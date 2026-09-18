@tool
class_name GFFAudioControl
extends GFFEffect

## Game Feel Flow Audio Control
##
## Player-level audio actions + property tweens — counterparts of Feel's
## MMF_AudioSource family (Play/Stop/Pause, Pitch, Pan, Volume).
## Instant actions: "play", "stop", "pause", "resume".
## Tweened properties: "pitch" (pitch_scale), "volume" (volume_db),
## "pan" (panning_strength on 2D/3D players only — plain AudioStreamPlayer
## has no pan in Godot, use a bus Panner effect via GFFAudioBusEffect instead).

@export_group("Audio Control")
## One of: play, stop, pause, resume, pitch, volume, pan.
@export var action: StringName = &"play"
## Tween destination for pitch/volume/pan actions.
@export var to_value: float = 0.5
## Out-and-back for tweened properties.
@export var ping_pong: bool = true
@export var debug_enabled: bool = false

func _resolve_target(target: Node) -> Node:
	# Audio players are plain Nodes — the base resolver only accepts
	# Node2D/Node3D/Control, so accept audio players directly here.
	if target is AudioStreamPlayer or target is AudioStreamPlayer2D or target is AudioStreamPlayer3D:
		return target
	return super._resolve_target(target)

func _execute(node: Node, params: GFFParams) -> void:
	var act := StringName(params.get_string("action", String(action)))
	var prop := _prop_for(node, act)
	if prop.is_empty():
		# Instant transport actions.
		match String(act):
			"play":
				node.play(params.get_float("from_position", 0.0))
			"stop":
				node.stop()
			"pause":
				node.stream_paused = true
			"resume":
				node.stream_paused = false
			_:
				push_warning("GFFAudioControl: unknown action '", act, "'")
				return
		_dbg("action=" + String(act) + " node=" + node.name)
		return

	# Tweened property actions.
	var to: float = params.get_float("to", to_value)
	var final_duration := params.get_float("duration", duration)
	var do_ping_pong := params.get_bool("ping_pong", ping_pong)
	var intensity := params.get_float("intensity", 1.0)
	var from: float = node.get(prop)
	to = lerpf(from, to, intensity)
	_dbg("prop=" + prop + " from=" + str(from) + " to=" + str(to))

	var total := final_duration * (2.0 if do_ping_pong else 1.0)
	var elapsed := 0.0
	while elapsed < total and _is_playing:
		if not is_instance_valid(node):
			return
		var t: float
		if do_ping_pong:
			t = clampf(elapsed / final_duration, 0.0, 1.0)
			if elapsed > final_duration:
				t = 2.0 - t
		else:
			t = clampf(elapsed / final_duration, 0.0, 1.0)
		node.set(prop, lerpf(from, to, _apply_curve(t, easing_curve)))
		await node.get_tree().process_frame
		if not is_instance_valid(node) or not _is_playing:
			return
		elapsed += node.get_process_delta_time()

	if is_instance_valid(node):
		node.set(prop, from if do_ping_pong else to)

func _prop_for(node: Node, act: StringName) -> StringName:
	match String(act):
		"pitch":
			return &"pitch_scale"
		"volume":
			return &"volume_db"
		"pan":
			if node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
				return &"panning_strength"
			push_warning("GFFAudioControl: plain AudioStreamPlayer has no pan — use a bus Panner")
			return &""
	return &""

func _get_default_duration() -> float:
	return 0.4

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFAudioControl] ", message)
