@tool
class_name GFFRigidbodyAction
extends GFFEffect

## Game Feel Flow Rigidbody Action
##
## Physics body actions — counterparts of Feel's MMF_Rigidbody feedback
## family (impulse/force/torque). Actions: "impulse" (central impulse),
## "impulse_offset" (impulse at local offset), "force" (sustained central
## force for the duration), "torque" (torque impulse), "freeze"/"unfreeze"
## (RigidBody freeze), "sleep"/"wake".
## reset_on_finish teleports the body back and zeroes velocities — useful
## for repeatable feel tests.

@export_group("Rigidbody")
## One of: impulse, impulse_offset, force, torque, freeze, unfreeze, sleep, wake.
@export var action: StringName = &"impulse"
@export var force: Vector3 = Vector3(5.0, 0.0, 0.0)
@export var torque: Vector3 = Vector3(0.0, 0.0, 5.0)
## Local-space application point for impulse_offset.
@export var offset: Vector3 = Vector3(0.0, 0.3, 0.0)
## Restore transform + velocities when the play ends (physics is not
## otherwise restorable).
@export var reset_on_finish: bool = false
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	var act := StringName(params.get_string("action", String(action)))
	var intensity := params.get_float("intensity", 1.0)
	var final_duration := params.get_float("duration", duration)
	var f: Vector3 = params.get_vector3("force", force) * intensity
	var tq: Vector3 = params.get_vector3("torque", torque) * intensity
	var off: Vector3 = params.get_vector3("offset", offset)

	var body3 := node as RigidBody3D
	var body2 := node as RigidBody2D
	if body3 == null and body2 == null:
		push_warning("GFFRigidbodyAction: target is not a RigidBody2D/3D")
		return

	# Capture state for reset.
	var base_xform: Variant = null
	var base_lv: Variant = null
	var base_av: Variant = null
	var do_reset := params.get_bool("reset", reset_on_finish)
	if do_reset:
		base_xform = node.get("global_transform")
		base_lv = node.get("linear_velocity")
		base_av = node.get("angular_velocity")

	_dbg("action=" + String(act) + " force=" + str(f) + " dur=" + str(final_duration))
	match String(act):
		"impulse":
			_apply_impulse(node, f, Vector3.ZERO)
		"impulse_offset":
			_apply_impulse(node, f, off)
		"torque":
			_apply_torque(node, tq)
		"force":
			var elapsed := 0.0
			while elapsed < final_duration and _is_playing:
				if not is_instance_valid(node):
					return
				_apply_force(node, f)
				await node.get_tree().physics_frame
				if not is_instance_valid(node) or not _is_playing:
					break
				elapsed += node.get_physics_process_delta_time()
		"freeze", "unfreeze", "sleep", "wake":
			_set_state(node, String(act))
		_:
			push_warning("GFFRigidbodyAction: unknown action '", act, "'")
			return

	if do_reset and is_instance_valid(node):
		node.set("freeze", true)
		node.set("global_transform", base_xform)
		node.set("linear_velocity", base_lv)
		node.set("angular_velocity", base_av)
		node.set("freeze", false)

func _apply_impulse(node: Node, f: Vector3, off: Vector3) -> void:
	if node is RigidBody3D:
		node.apply_impulse(f, off)
	else:
		(node as RigidBody2D).apply_impulse(Vector2(f.x, f.y), Vector2(off.x, off.y))

func _apply_torque(node: Node, tq: Vector3) -> void:
	if node is RigidBody3D:
		node.apply_torque_impulse(tq)
	else:
		(node as RigidBody2D).apply_torque_impulse(tq.z)

func _apply_force(node: Node, f: Vector3) -> void:
	if node is RigidBody3D:
		node.apply_central_force(f)
	else:
		(node as RigidBody2D).apply_central_force(Vector2(f.x, f.y))

func _set_state(node: Node, act: String) -> void:
	match act:
		"freeze": node.set("freeze", true)
		"unfreeze": node.set("freeze", false)
		"sleep": node.set("sleeping", true)
		"wake": node.set("sleeping", false)

func _get_default_duration() -> float:
	return 0.5

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFRigidbodyAction] ", message)
