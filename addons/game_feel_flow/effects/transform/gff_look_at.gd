@tool
class_name GFFLookAt
extends GFFEffect

## Game Feel Flow Look At
##
## Rotates a Node3D to face a target — counterpart of Feel's MMF_LookAt.
## Target comes from params["look_at"] (Node) / params["look_position"]
## (Vector3) / exported target_name (scene lookup). Instant when
## turn_speed_deg <= 0, otherwise slerps at a fixed rate.

@export_group("Look At")
## Scene node name to face (used when no param is provided).
@export var target_name: String = ""
## Degrees per second to turn. <= 0 snaps instantly.
@export var turn_speed_deg: float = 720.0
## Keep the node's up direction aligned to world up.
@export var use_model_front: bool = false
@export var up_vector: Vector3 = Vector3.UP
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	if not node is Node3D:
		push_warning("GFFLookAt: only Node3D targets are supported")
		return
	var n3 := node as Node3D

	var target_pos: Variant = params.get_variant("look_position", null)
	var tn: Node = params.get_node("look_at", null)
	if tn is Node3D:
		target_pos = tn.global_position
	elif target_pos == null and not target_name.is_empty():
		var found := node.get_tree().root.find_child(target_name, true, false)
		if found is Node3D:
			target_pos = found.global_position
	if not target_pos is Vector3:
		push_warning("GFFLookAt: no valid look target")
		return
	if n3.global_position.is_equal_approx(target_pos):
		return

	var speed := params.get_float("turn_speed", turn_speed_deg)
	var final_duration := params.get_float("duration", duration)

	# Destination orientation via a temporary look_at.
	var goal_rot: Vector3 = _goal_rotation(n3, target_pos)
	var from_quat := n3.quaternion
	var to_quat := Quaternion.from_euler(goal_rot)
	var total_angle := rad_to_deg(from_quat.angle_to(to_quat))
	_dbg("target=" + str(target_pos) + " turn_deg=" + str(total_angle) + " speed=" + str(speed))

	if speed <= 0.0 or total_angle < 0.001:
		n3.rotation = goal_rot
		return

	var turn_time := total_angle / speed
	var run_time := minf(turn_time, final_duration) if final_duration > 0.0 else turn_time
	var elapsed := 0.0
	while elapsed < run_time and _is_playing:
		if not is_instance_valid(node):
			return
		var k := clampf(elapsed / turn_time, 0.0, 1.0)
		n3.quaternion = from_quat.slerp(to_quat, k)
		await node.get_tree().process_frame
		if not is_instance_valid(node) or not _is_playing:
			return
		elapsed += node.get_process_delta_time()

	if is_instance_valid(node):
		n3.quaternion = to_quat

func _goal_rotation(n3: Node3D, target_pos: Vector3) -> Vector3:
	var look := Transform3D(n3.global_transform.basis, n3.global_position).looking_at(
		target_pos, up_vector, use_model_front)
	return look.basis.get_euler()

func _get_default_duration() -> float:
	return 0.5

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFLookAt] ", message)
