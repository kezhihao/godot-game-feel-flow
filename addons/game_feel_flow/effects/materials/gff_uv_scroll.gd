@tool
class_name GFFUVScroll
extends GFFEffect

## Game Feel Flow UV Scroll
##
## Scrolls or tweens StandardMaterial3D UV transform — counterpart of Feel's
## MMF_MaterialPropertyBlockUV feedbacks. SCROLL moves uv1_offset at a steady
## velocity; TWEEN_OFFSET / TWEEN_SCALE lerp to a target value and back.

const MaterialUtil = preload("res://addons/game_feel_flow/core/utils/gff_material_util.gd")

enum UVMode { SCROLL, TWEEN_OFFSET, TWEEN_SCALE }

@export_group("UV")
@export var uv_mode: UVMode = UVMode.SCROLL
## uv1_offset units per second for SCROLL mode.
@export var scroll_velocity: Vector3 = Vector3(0.5, 0.0, 0.0)
## Target uv1_offset for TWEEN_OFFSET.
@export var to_offset: Vector3 = Vector3(1.0, 0.0, 0.0)
## Target uv1_scale for TWEEN_SCALE.
@export var to_scale: Vector3 = Vector3(2.0, 1.0, 1.0)
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	var mi := node as MeshInstance3D
	if mi == null:
		push_warning("GFFUVScroll: only MeshInstance3D targets are supported")
		return
	var info := MaterialUtil.acquire(node, 0, true)
	var mat: Material = info["material"]
	if not mat is StandardMaterial3D:
		push_warning("GFFUVScroll: material is not StandardMaterial3D")
		MaterialUtil.release(node, info)
		return
	var sm := mat as StandardMaterial3D

	var mode_i: int = params.get_int("uv_mode", uv_mode)
	var final_duration := params.get_float("duration", duration)
	var intensity := params.get_float("intensity", 1.0)
	var velocity: Vector3 = params.get_vector3("velocity", scroll_velocity) * intensity
	var tgt_offset: Vector3 = params.get_vector3("to_offset", to_offset)
	var tgt_scale: Vector3 = params.get_vector3("to_scale", to_scale)

	var base_offset := sm.uv1_offset
	var base_scale := sm.uv1_scale
	_dbg("mode=" + str(mode_i) + " vel=" + str(velocity) + " dur=" + str(final_duration))

	var elapsed := 0.0
	while elapsed < final_duration and _is_playing:
		if not is_instance_valid(node):
			return
		var t := clampf(elapsed / final_duration, 0.0, 1.0)
		match mode_i:
			UVMode.SCROLL:
				sm.uv1_offset = base_offset + velocity * elapsed
			UVMode.TWEEN_OFFSET:
				sm.uv1_offset = base_offset.lerp(tgt_offset, _apply_curve(t, easing_curve))
			UVMode.TWEEN_SCALE:
				sm.uv1_scale = base_scale.lerp(tgt_scale, _apply_curve(t, easing_curve))
		await node.get_tree().process_frame
		if not is_instance_valid(node) or not _is_playing:
			return
		elapsed += node.get_process_delta_time()

	if is_instance_valid(node):
		sm.uv1_offset = base_offset
		sm.uv1_scale = base_scale
		MaterialUtil.release(node, info)

func _get_default_duration() -> float:
	return 1.0

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFUVScroll] ", message)
