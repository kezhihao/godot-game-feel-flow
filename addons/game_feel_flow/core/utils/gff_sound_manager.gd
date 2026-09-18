@icon("res://addons/game_feel_flow/icons/icon_sound_manager.svg")
class_name GFFSoundManager
extends Node

## Game Feel Flow Sound Manager
##
## Lightweight counterpart of Feel's MMSoundManager — a pooled set of audio
## players with bus routing, volume/pitch randomization and fire-and-forget
## playback. Options Dictionary keys:
##   volume_db  float   (default 0)
##   pitch      float   (default 1)
##   pitch_var  float   (random ±, default 0)
##   bus        StringName (default &"Master")
##   position   Vector2/Vector3 — positional playback via 2D/3D players
##   loop       bool    (holds the player until stop_sound/release)
## play() returns the player node (or null when the pool is exhausted);
## finished players return to the pool automatically.

@export_group("Sound")
## Pooled AudioStreamPlayer count for non-positional playback.
@export var pool_size: int = 8
@export var positional_pool_size: int = 4
## Grow pools on exhaustion.
@export var auto_expand: bool = true
## Player type used for positional playback: "2d" or "3d".
@export var positional_mode: StringName = &"3d"
@export var debug_enabled: bool = false

var _free_flat: Array[AudioStreamPlayer] = []
var _free_pos: Array[Node] = []  # AudioStreamPlayer2D/3D

func _ready() -> void:
	_fill(pool_size, false)
	_fill(positional_pool_size, true)

func play(stream: AudioStream, options: Dictionary = {}) -> Node:
	## Fire-and-forget playback. Returns the playing node or null.
	if stream == null:
		push_warning("GFFSoundManager: play called with null stream")
		return null
	var pos: Variant = options.get("position", null)
	var player: Node = _pop(pos != null)
	if player == null:
		push_warning("GFFSoundManager: pool exhausted")
		return null

	player.stream = stream
	player.volume_db = options.get("volume_db", 0.0)
	var pitch: float = options.get("pitch", 1.0)
	var pvar: float = options.get("pitch_var", 0.0)
	if pvar > 0.0:
		pitch *= randf_range(1.0 - pvar, 1.0 + pvar)
	player.pitch_scale = pitch
	player.bus = options.get("bus", &"Master")

	if pos != null:
		_set_position(player, pos)

	player.play()
	_dbg("play " + str(stream) + " on " + str(player) + " bus=" + str(player.bus))
	return player

func play_at(stream: AudioStream, position: Variant, options: Dictionary = {}) -> Node:
	var o := options.duplicate()
	o["position"] = position
	return play(stream, o)

func release(player: Node) -> void:
	## Return a player to its pool early (e.g. looping sound stopped).
	if player == null or not is_instance_valid(player):
		return
	player.stop()
	_return(player)

func stop_all() -> void:
	for p in _free_flat + _free_pos:
		if p is AudioStreamPlayer:
			p.stop()
	# also stop any still-marked-in-use players: walk children once
	for child in get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer2D or child is AudioStreamPlayer3D:
			child.stop()

func free_flat_count() -> int:
	return _free_flat.size()

func free_positional_count() -> int:
	return _free_pos.size()

func _fill(count: int, positional: bool) -> void:
	for i in count:
		var p: Node
		if positional:
			p = AudioStreamPlayer3D.new() if positional_mode == &"3d" else AudioStreamPlayer2D.new()
			_free_pos.append(p)
		else:
			p = AudioStreamPlayer.new()
			_free_flat.append(p)
		add_child(p)
		# One persistent connection per pooled player — _return is idempotent.
		p.finished.connect(_on_player_finished.bind(p))

func _pop(positional: bool) -> Node:
	var pool: Array = _free_pos if positional else _free_flat
	if pool.is_empty():
		if auto_expand:
			_fill(1, positional)
		if pool.is_empty():
			return null
	var p: Node = pool.pop_back()
	p.process_mode = Node.PROCESS_MODE_INHERIT
	return p

func _return(p: Node) -> void:
	if p is AudioStreamPlayer2D or p is AudioStreamPlayer3D:
		_free_pos.append(p)
	elif p is AudioStreamPlayer:
		_free_flat.append(p)
	_dbg("returned " + str(p))

func _on_player_finished(player: Node) -> void:
	# `player` bound explicitly — reconnect/disconnect bookkeeping only.
	_return(player)

func _set_position(player: Node, pos: Variant) -> void:
	if player is AudioStreamPlayer3D and pos is Vector3:
		player.position = pos
	elif player is AudioStreamPlayer2D and pos is Vector2:
		player.position = pos
	elif player is AudioStreamPlayer2D and pos is Vector3:
		player.position = Vector2(pos.x, pos.y)

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFSoundManager] ", message)
