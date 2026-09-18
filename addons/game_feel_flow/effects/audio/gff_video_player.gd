@tool
class_name GFFVideoPlayer
extends GFFEffect

## Game Feel Flow Video Player
##
## Counterpart of Feel's MMF_VideoPlayer feedbacks, driving a
## VideoStreamPlayer. video_action (params["video_action"] overrides):
##   "play"   -> play() (from `seek_to` if > 0)
##   "stop"   -> stop()
##   "pause"  -> paused = true
##   "resume" -> paused = false
##   "seek"   -> stream_position = seek_to (no play state change)
##   "volume" -> tween volume_db toward `to_value` over duration
##   "stream" -> swap `stream` (params["stream"]/to_stream), restore after
## `to_value` carries seek seconds / volume dB depending on action.

@export_group("Video")
## One of: play, stop, pause, resume, seek, volume, stream.
@export var video_action: StringName = &"play"
## Seconds for seek actions / dB for volume. params["to"] overrides.
@export var to_value: float = 0.0
## Jump position applied right before play(). params["seek_to"] overrides.
@export var seek_to: float = -1.0
## Stream resource for action="stream". params["stream"] overrides.
@export var to_stream: VideoStream = null
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	if not (node is VideoStreamPlayer):
		push_warning("GFFVideoPlayer: target is not a VideoStreamPlayer")
		return
	var player := node as VideoStreamPlayer
	var act := StringName(params.get_string("video_action", String(video_action)))
	var val := params.get_float("to", to_value)
	_dbg("action=" + String(act) + " node=" + str(node))

	match String(act):
		"play":
			var s := params.get_float("seek_to", seek_to)
			if s >= 0.0:
				player.stream_position = s
			player.play()
		"stop":
			player.stop()
		"pause":
			player.paused = true
		"resume":
			player.paused = false
		"seek":
			player.stream_position = val
		"volume":
			var orig_db := player.volume_db
			var dur: float = maxf(params.duration, 0.01)
			var elapsed := 0.0
			while elapsed < dur and _is_playing:
				await node.get_tree().process_frame
				elapsed += node.get_process_delta_time()
				var k := clampf(elapsed / dur, 0.0, 1.0)
				player.volume_db = lerpf(orig_db, val, _apply_curve(k, easing_curve))
			if restore_after_play and is_instance_valid(player):
				player.volume_db = orig_db
		"stream":
			var st: Variant = params.get_variant("stream", to_stream)
			if not (st is VideoStream):
				push_warning("GFFVideoPlayer: stream action needs a VideoStream")
				return
			var orig: VideoStream = player.stream
			player.stream = st
			var dur2: float = maxf(params.duration, 0.01)
			var elapsed2 := 0.0
			while elapsed2 < dur2 and _is_playing:
				await node.get_tree().process_frame
				elapsed2 += node.get_process_delta_time()
			if restore_after_play and is_instance_valid(player):
				player.stream = orig
		_:
			push_warning("GFFVideoPlayer: unknown video_action '", act, "'")

func _resolve_target(target: Node) -> Node:
	# Accept VideoStreamPlayer directly — base only knows Node2D/3D/Control
	# (VideoStreamPlayer IS a Control, but keep explicit for clarity).
	if target is VideoStreamPlayer:
		return target
	return super._resolve_target(target)

func _get_default_duration() -> float:
	return 0.0

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFVideoPlayer] ", message)
