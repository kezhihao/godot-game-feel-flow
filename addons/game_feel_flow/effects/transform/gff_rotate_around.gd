@tool
class_name GFFRotateAround
extends GFFEffect

## Game Feel Flow Rotate Around
##
## Orbits a node around a center point — counterpart of Feel's MMF_RotateAround.
## Center comes from params["center"] (Vector3) / params["center_node"] (Node)
## or the exported center_value. Total angle = speed_deg * duration, or set
## total_angle_deg > 0 to spin a fixed amount regardless of duration.

@export_group("Rotate Around")
@export var axis: Vector3 = Vector3.UP
## Orbit speed in degrees/second.
@export var speed_deg: float = 180.0
## When > 0, total degrees to travel (ignores speed_deg; rate = angle/duration).
@export var total_angle_deg: float = 0.0
## Fallback orbit center (world space) when no param is provided.
@export var center_value: Vector3 = Vector3.ZERO
## Also spin the node itself around its own axis while orbiting.
@export var rotate_node_too: bool = false
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	if not node is Node3D:
		push_warning("GFFRotateAround: only Node3D targets are supported")
		return
	var n3 := node as Node3D
	var center: Vector3 = center_value
	var cn: Node = params.get_node("center_node", null)
	if cn is Node3D:
		center = cn.global_position
	elif params.get_variant("center", null) is Vector3:
		center = params.get_vector3("center", center_value)

	var final_duration := params.get_float("duration", duration)
	var angle := params.get_float("total_angle", total_angle_deg)
	var speed := params.get_float("speed", speed_deg) * params.get_float("intensity", 1.0)
	var axis_n := axis.normalized()
	if axis_n.is_zero_approx():
		push_warning("GFFRotateAround: axis is zero")
		return

	var base_pos := n3.global_position
	var base_rot := n3.rotation
	var offset := base_pos - center
	_dbg("center=" + str(center) + " offset=" + str(offset) + " speed=" + str(speed)
		+ " total_angle=" + str(angle) + " dur=" + str(final_duration))
	var elapsed := 0.0
	while elapsed < final_duration and _is_playing:
		if not is_instance_valid(node):
			return
		var t := clampf(elapsed / final_duration, 0.0, 1.0)
		var k := _apply_curve(t, easing_curve)
		var deg := angle * k if angle > 0.0 else speed * elapsed
		var basis_rot := Basis(axis_n, deg_to_rad(deg))
		n3.global_position = center + basis_rot * offset
		if rotate_node_too:
			n3.rotation = (basis_rot * Basis.from_euler(base_rot)).get_euler()
		await node.get_tree().process_frame
		if not is_instance_valid(node) or not _is_playing:
			return
		elapsed += node.get_process_delta_time()

func _get_default_duration() -> float:
	return 1.0

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFRotateAround] ", message)
