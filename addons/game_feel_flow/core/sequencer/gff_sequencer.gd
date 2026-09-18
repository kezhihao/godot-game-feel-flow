@icon("res://addons/game_feel_flow/icons/icon_sequencer.svg")
class_name GFFSequencer
extends Node

## Game Feel Flow Sequencer
##
## Timeline player for GFFSequence resources — the Godot counterpart of
## Feel's MMSequencer. Advances a playhead over the sequence, firing each
## item when its start_time is crossed. Supports play/pause/resume/stop,
## seek, playback speed, and looping.
##
## Item payloads dispatch through the existing plugin systems:
##   EFFECT/COMBO -> GameFeelFlow.play / play_combo
##   CHANNEL      -> GameFeelFlow.broadcast_channel
##   SIGNAL       -> item_signal emitted (item.id as payload)
##   METHOD       -> target.call(method)
##   SOUND        -> GFFSoundManager (found via group or auto-created player)

signal sequence_started()
signal sequence_finished()
signal item_triggered(item: GFFSequenceItem)
signal item_signal(item_id: String)

enum State { STOPPED, PLAYING, PAUSED }

@export var sequence: GFFSequence = null
## Node used when an item has no target_path of its own.
@export var default_target: Node = null
@export var auto_play: bool = false
@export var loop: bool = false
## Timeline playback speed multiplier.
@export var play_speed: float = 1.0
## Sequence time in seconds at which playback starts (like Feel's play range).
@export var play_range_start: float = 0.0
## 0 = play to sequence end.
@export var play_range_end: float = 0.0

@export var debug_enabled: bool = false

var state: State = State.STOPPED
var current_time: float = 0.0

var _items: Array[GFFSequenceItem] = []
var _fired: Dictionary = {}  # GFFSequenceItem -> bool
var _end_time: float = 0.0


func _ready() -> void:
	_dbg("ready seq=%s items=%d" % [sequence, _items.size()])
	if auto_play and sequence != null:
		call_deferred("play")


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	current_time += delta * play_speed
	_fire_due_items()
	if current_time >= _end_time:
		if loop:
			_seek_to_range_start()
		else:
			_finish()


func play() -> void:
	if sequence == null:
		_dbg("play ignored: no sequence")
		return
	_items = sequence.get_sorted_items()
	var seq_end: float = sequence.get_duration()
	_end_time = play_range_end if play_range_end > 0.0 else seq_end
	state = State.PLAYING
	_seek_to_range_start()
	sequence_started.emit()
	_dbg("play items=%d end=%.2f speed=%.2f" % [_items.size(), _end_time, play_speed])


func stop() -> void:
	state = State.STOPPED
	current_time = 0.0
	_fired.clear()
	_dbg("stop")


func pause() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		_dbg("pause t=%.3f" % current_time)


func resume() -> void:
	if state == State.PAUSED:
		state = State.PLAYING
		_dbg("resume t=%.3f" % current_time)


func is_playing() -> bool:
	return state == State.PLAYING


## Jump the playhead. Items strictly before t are marked fired so they
## do not re-trigger; items at/after t remain pending.
func seek(t: float) -> void:
	current_time = clampf(t, 0.0, maxf(_end_time, 0.0))
	_fired.clear()
	for it: GFFSequenceItem in _items:
		if it.start_time < current_time:
			_fired[it] = true
	_dbg("seek t=%.3f pending=%d" % [current_time, _items.size() - _fired.size()])


func _seek_to_range_start() -> void:
	_fired.clear()
	current_time = play_range_start
	for it: GFFSequenceItem in _items:
		if it.start_time < current_time:
			_fired[it] = true


func _fire_due_items() -> void:
	for it: GFFSequenceItem in _items:
		if _fired.get(it, false):
			continue
		if it.start_time > current_time:
			break  # sorted: nothing later is due either
		_fired[it] = true
		_fire_item(it)


func _finish() -> void:
	state = State.STOPPED
	sequence_finished.emit()
	_dbg("finished")


func _fire_item(it: GFFSequenceItem) -> void:
	var target: Node = _resolve_target(it)
	match it.item_type:
		GFFSequenceItem.ItemType.EFFECT:
			GameFeelFlow.play(String(it.name_key), target, _params_for(it))
		GFFSequenceItem.ItemType.COMBO:
			GameFeelFlow.play_combo(String(it.name_key), target, _params_for(it))
		GFFSequenceItem.ItemType.CHANNEL:
			GameFeelFlow.broadcast_channel(it.channel, it.name_key, it.params)
		GFFSequenceItem.ItemType.SIGNAL:
			item_signal.emit(it.id)
		GFFSequenceItem.ItemType.METHOD:
			if target != null and target.has_method(it.name_key):
				var args: Variant = it.params.get("args", [])
				if args is Array:
					target.callv(it.name_key, args)
				else:
					target.call(it.name_key, args)
		GFFSequenceItem.ItemType.SOUND:
			_play_sound(it, target)
	item_triggered.emit(it)
	_dbg("item t=%.3f type=%d id='%s' key='%s'" % [current_time, it.item_type, it.id, it.name_key])


func _resolve_target(it: GFFSequenceItem) -> Node:
	if it.target_path != NodePath(""):
		var n: Node = get_node_or_null(it.target_path)
		if n != null:
			return n
		var root: Node = get_tree().root if is_inside_tree() else null
		if root != null:
			return root.get_node_or_null(it.target_path)
		return null
	return default_target


func _params_for(it: GFFSequenceItem) -> GFFParams:
	var p: GFFParams = GFFParams.new()
	if it.duration > 0.0:
		p.duration = it.duration
	for k: String in it.params:
		if k == "duration":
			p.duration = float(it.params[k])
		else:
			p.with_variant(k, it.params[k])
	return p


func _play_sound(it: GFFSequenceItem, target: Node) -> void:
	if it.stream == null:
		return
	var sm: Node = _find_sound_manager()
	if sm != null:
		if target is Node3D:
			sm.play_at(it.stream, target.global_position, it.params)
		else:
			sm.play(it.stream, it.params)
		return
	var pl: AudioStreamPlayer = AudioStreamPlayer.new()
	pl.stream = it.stream
	pl.finished.connect(pl.queue_free)
	add_child(pl)
	pl.play()


func _find_sound_manager() -> Node:
	for n: Node in get_tree().get_nodes_in_group("gff_sound_manager"):
		return n
	if default_target != null:
		for c: Node in default_target.get_children():
			if c is GFFSoundManager:
				return c
	for c: Node in get_children():
		if c is GFFSoundManager:
			return c
	return null


func _dbg(msg: String) -> void:
	if debug_enabled:
		print("[GFFSequencer] %s" % msg)
