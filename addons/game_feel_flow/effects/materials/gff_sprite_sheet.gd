@tool
class_name GFFSpriteSheet
extends GFFEffect

## Game Feel Flow Sprite Sheet
##
## Stepped frame animation for Sprite2D / Sprite3D / TextureRect-style nodes —
## counterpart of Feel's MMF_SpriteSheetAnimation feedback. Advances `frame`
## across hframes*vframes cells at `fps`; optionally loops until duration ends
## then restores the starting frame.

@export_group("Sprite Sheet")
## Frames per second.
@export var fps: float = 12.0
## Total frames to play. 0 = use sprite's hframes*vframes.
@export var frame_count: int = 0
## Restart at frame 0 when reaching the end, until duration expires.
## When false, plays once through and clamps on the last frame.
@export var loop: bool = false
## First frame index to play from.
@export var start_frame: int = 0
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	if node.get("frame") == null or node.get("hframes") == null:
		push_warning("GFFSpriteSheet: target has no frame/hframes properties")
		return
	var final_duration := params.get_float("duration", duration)
	var rate := params.get_float("fps", fps) * params.get_float("intensity", 1.0)
	var do_loop := params.get_bool("loop", loop)
	if rate <= 0.0:
		push_warning("GFFSpriteSheet: fps must be > 0")
		return

	var total: int = params.get_int("frame_count", frame_count)
	if total <= 0:
		total = int(node.get("hframes")) * int(node.get("vframes"))
	total = maxi(total, 1)

	var base_frame: int = node.get("frame")
	var first: int = clampi(params.get_int("start_frame", start_frame), 0, total - 1)
	_dbg("total=" + str(total) + " fps=" + str(rate) + " loop=" + str(do_loop)
		+ " dur=" + str(final_duration))

	var elapsed := 0.0
	while elapsed < final_duration and _is_playing:
		if not is_instance_valid(node):
			return
		var idx := first + int(elapsed * rate)
		if do_loop:
			node.set("frame", idx % total)
		else:
			node.set("frame", mini(idx, total - 1))
			if idx >= total - 1:
				break
		await node.get_tree().process_frame
		if not is_instance_valid(node) or not _is_playing:
			return
		elapsed += node.get_process_delta_time()

	if is_instance_valid(node):
		node.set("frame", base_frame)

func _get_default_duration() -> float:
	return 0.6

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFSpriteSheet] ", message)
