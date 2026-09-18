@tool
class_name GFFSpawn
extends GFFEffect

## Game Feel Flow Spawn / Destroy
##
## Counterpart of Feel's MMF_InstantiateObject + MMF_Destroy feedbacks.
## One effect, two actions via `action` or params["action"]:
##   "spawn"   -> instantiate `scene` (PackedScene) or duplicate
##                params["source_node"] / `source_name` node, attach under
##                params["parent_node"] / `parent_name` / the effect node's
##                parent, at position/rotation/scale offsets.
##   "destroy" -> queue_free() params["target_node"] / `destroy_name` node,
##                or the effect node itself when nothing else is given.
## `lifetime` > 0 auto-frees spawned nodes (fire-and-forget timer — the
## effect itself returns immediately, like Feel's instant instantiate).

@export_group("Spawn")
## One of: spawn, destroy.
@export var action: StringName = &"spawn"
## Scene to instantiate. params["scene"] (PackedScene) overrides.
@export var scene: PackedScene = null
## Node name to duplicate when no PackedScene is provided. params["source_node"].
@export var source_name: String = ""
## Parent for the spawned node. Empty = effect node's parent.
## params["parent_node"] overrides.
@export var parent_name: String = ""
## Name assigned to the spawned node (suffixed on collision). params["spawn_name"].
@export var spawn_name: String = ""
@export var position_offset: Vector3 = Vector3.ZERO
@export var rotation_euler_deg: Vector3 = Vector3.ZERO
@export var spawn_scale: Vector3 = Vector3.ONE
## Seconds before spawned nodes auto-free. 0 = persist.
@export var lifetime: float = 0.0

@export_group("Destroy")
## Node name to destroy when action == "destroy". params["target_node"] wins.
@export var destroy_name: String = ""
@export var debug_enabled: bool = false

func _init() -> void:
	# Spawning is a world-state change — nothing to restore on the origin.
	restore_after_play = false

func _execute(node: Node, params: GFFParams) -> void:
	var act := StringName(params.get_string("action", String(action)))
	match String(act):
		"spawn":
			_spawn(node, params)
		"destroy":
			_destroy(node, params)
		_:
			push_warning("GFFSpawn: unknown action '", act, "'")

func _spawn(node: Node, params: GFFParams) -> void:
	var inst: Node = null
	var packed: PackedScene = params.get_variant("scene", scene)
	if packed is PackedScene:
		inst = packed.instantiate()
	else:
		var source: Node = params.get_node("source_node", null)
		if source == null and not source_name.is_empty():
			source = node.get_tree().root.find_child(source_name, true, false)
		if source == null:
			push_warning("GFFSpawn: no scene and no valid source node")
			return
		inst = source.duplicate()

	var parent: Node = params.get_node("parent_node", null)
	if parent == null and not parent_name.is_empty():
		parent = node.get_tree().root.find_child(parent_name, true, false)
	if parent == null:
		parent = node.get_parent()
	if parent == null:
		parent = node.get_tree().root

	var desired_name := String(params.get_string("spawn_name", spawn_name))
	if not desired_name.is_empty():
		inst.name = desired_name

	parent.add_child(inst)
	_dbg("spawned " + str(inst) + " under " + str(parent))

	var off: Vector3 = params.get_vector3("position", position_offset)
	var rot: Vector3 = params.get_vector3("rotation", rotation_euler_deg)
	var scl: Vector3 = params.get_vector3("scale", spawn_scale)
	if inst is Node3D:
		inst.position += off
		inst.rotation_degrees += rot
		inst.scale *= scl
	elif inst is Node2D:
		inst.position += Vector2(off.x, off.y)
		inst.rotation_degrees += rot.z
		inst.scale *= Vector2(scl.x, scl.y)

	var life := params.get_float("lifetime", lifetime)
	if life > 0.0 and inst.is_inside_tree():
		var weak := weakref(inst)
		inst.get_tree().create_timer(life, true, false, true).timeout.connect(
			func() -> void:
				var n: Node = weak.get_ref()
				if n and is_instance_valid(n):
					n.queue_free()
		)

func _destroy(node: Node, params: GFFParams) -> void:
	var victim: Node = params.get_node("target_node", null)
	var dname := String(params.get_string("destroy_name", destroy_name))
	if victim == null and not dname.is_empty():
		victim = node.get_tree().root.find_child(dname, true, false)
	if victim == null:
		victim = node
	if victim == null or not is_instance_valid(victim):
		return
	_dbg("destroy " + str(victim))
	victim.queue_free()

func _get_default_duration() -> float:
	return 0.0

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFSpawn] ", message)
