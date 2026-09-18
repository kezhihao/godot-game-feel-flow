@tool
class_name GFFDestinationTransform
extends GFFEffect

## Game Feel Flow Destination Transform
##
## Drives a node toward a destination transform — counterpart of Feel's
## MMF_DestinationTransform. Destination is provided at play time via
## params["destination"] (Node) or resolved by destination_name lookup in the
## scene tree. Per-axis switches let you move only, rotate only, etc.

@export_group("Destination")
## Scene-tree node name to move toward (used when params["destination"] is not given).
@export var destination_name: String = ""
@export var apply_position: bool = true
@export var apply_rotation: bool = true
@export var apply_scale: bool = false
## Use global space (true) or local transform space (false).
@export var use_global_space: bool = true
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	if not node is Node3D:
		push_warning("GFFDestinationTransform: only Node3D targets are supported")
		return
	var dest: Node = params.get_node("destination", null)
	if dest == null and not destination_name.is_empty():
		dest = node.get_tree().root.find_child(destination_name, true, false)
	if not dest is Node3D:
		push_warning("GFFDestinationTransform: no valid Node3D destination")
		return

	var final_duration := params.get_float("duration", duration)
	var n3 := node as Node3D
	var d3 := dest as Node3D

	var from_pos: Vector3 = n3.global_position if use_global_space else n3.position
	var to_pos: Vector3 = d3.global_position if use_global_space else d3.position
	var from_rot: Vector3 = n3.global_rotation if use_global_space else n3.rotation
	var to_rot: Vector3 = d3.global_rotation if use_global_space else d3.rotation
	var from_scale: Vector3 = n3.global_transform.basis.get_scale() if use_global_space else n3.scale
	var to_scale: Vector3 = d3.global_transform.basis.get_scale() if use_global_space else d3.scale
	_dbg("dest=" + dest.name + " from_pos=" + str(from_pos) + " to_pos=" + str(to_pos)
		+ " pos=" + str(apply_position) + " rot=" + str(apply_rotation) + " dur=" + str(final_duration))

	var elapsed := 0.0
	while elapsed < final_duration and _is_playing:
		if not is_instance_valid(node):
			return
		var t := clampf(elapsed / final_duration, 0.0, 1.0)
		var k := _apply_curve(t, easing_curve)
		_apply(n3, from_pos, to_pos, from_rot, to_rot, from_scale, to_scale, k)
		await node.get_tree().process_frame
		if not is_instance_valid(node) or not _is_playing:
			return
		elapsed += node.get_process_delta_time()

	if is_instance_valid(node):
		_apply(n3, from_pos, to_pos, from_rot, to_rot, from_scale, to_scale, 1.0)

func _apply(n3: Node3D, from_pos: Vector3, to_pos: Vector3,
		from_rot: Vector3, to_rot: Vector3,
		from_scale: Vector3, to_scale: Vector3, k: float) -> void:
	if apply_position:
		if use_global_space:
			n3.global_position = from_pos.lerp(to_pos, k)
		else:
			n3.position = from_pos.lerp(to_pos, k)
	if apply_rotation:
		var fq := Quaternion.from_euler(from_rot)
		var tq := Quaternion.from_euler(to_rot)
		var rq := fq.slerp(tq, k)
		if use_global_space:
			n3.global_rotation = rq.get_euler()
		else:
			n3.rotation = rq.get_euler()
	if apply_scale:
		var s := from_scale.lerp(to_scale, k)
		if use_global_space:
			n3.global_transform.basis = n3.global_transform.basis.scaled(s / n3.global_transform.basis.get_scale())
		else:
			n3.scale = s

func _get_default_duration() -> float:
	return 0.6

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFDestinationTransform] ", message)
