@icon("res://addons/game_feel_flow/icons/icon_pool.svg")
class_name GFFPool
extends Node

## Game Feel Flow Object Pool
##
## Counterpart of Feel's MMMiniObjectPooler — pre-instantiates a fixed pool
## of inactive objects and hands them out on demand.
## Source priority: `scene` (PackedScene) > `prototype_node` (duplicated).
## get_object() returns a live node (visible + processing); when the pool is
## exhausted it either expands (auto_expand) or returns null.
## return_object() deactivates and parks the node back in the pool.

@export_group("Pool")
## Scene to instance for each pool slot.
@export var scene: PackedScene = null
## Runtime prototype duplicated per slot when no PackedScene is set.
@export var prototype_node: Node = null:
	set(value):
		prototype_node = value
		if prototype_node and (prototype_node is CanvasItem or prototype_node is Node3D):
			prototype_node.visible = false
@export var pool_size: int = 8
## Grow the pool on exhaustion instead of returning null.
@export var auto_expand: bool = true
## Hide returned objects; also disables processing.
@export var hide_inactive: bool = true
## Parent for pooled instances. Empty = this node's parent.
@export var parent_name: String = ""
@export var debug_enabled: bool = false

var _available: Array[Node] = []
var _in_use: Array[Node] = []

func _ready() -> void:
	_fill(pool_size)

func _fill(count: int) -> void:
	var parent := _pool_parent()
	for i in count:
		var inst := _make_instance()
		if inst == null:
			return
		inst.name = "%s_%d" % [_proto_name(), _available.size() + _in_use.size()]
		parent.add_child(inst)
		_deactivate(inst)
		_available.append(inst)
	_dbg("filled " + str(_available.size()))

func get_object() -> Node:
	## Pop a pooled object: activates it and returns it. Null when exhausted
	## and auto_expand is off.
	if _available.is_empty():
		if auto_expand:
			_fill(1)
		if _available.is_empty():
			push_warning("GFFPool: pool exhausted")
			return null
	var inst: Node = _available.pop_back()
	_in_use.append(inst)
	_activate(inst)
	_dbg("get " + str(inst) + " avail=" + str(_available.size()))
	return inst

func return_object(inst: Node) -> void:
	## Park an object back in the pool.
	if inst == null or not is_instance_valid(inst):
		return
	_in_use.erase(inst)
	if inst not in _available:
		_available.append(inst)
	_deactivate(inst)
	_dbg("return " + str(inst) + " avail=" + str(_available.size()))

func return_all() -> void:
	for inst in _in_use.duplicate():
		return_object(inst)

func available_count() -> int:
	return _available.size()

func in_use_count() -> int:
	return _in_use.size()

func _make_instance() -> Node:
	if scene:
		return scene.instantiate()
	if prototype_node:
		return prototype_node.duplicate()
	push_warning("GFFPool: no scene/prototype_node configured")
	return null

func _proto_name() -> String:
	if prototype_node:
		return prototype_node.name + "_pooled"
	return "pooled"

func _pool_parent() -> Node:
	if not parent_name.is_empty() and is_inside_tree():
		var found := get_tree().root.find_child(parent_name, true, false)
		if found:
			return found
	return get_parent() if get_parent() else self

func _activate(inst: Node) -> void:
	inst.process_mode = Node.PROCESS_MODE_INHERIT
	if inst is Node3D or inst is CanvasItem:
		inst.visible = true
	inst.set_process(true)
	inst.set_physics_process(true)

func _deactivate(inst: Node) -> void:
	if hide_inactive and (inst is Node3D or inst is CanvasItem):
		inst.visible = false
	inst.set_process(false)
	inst.set_physics_process(false)
	inst.process_mode = Node.PROCESS_MODE_DISABLED

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFPool] ", message)
