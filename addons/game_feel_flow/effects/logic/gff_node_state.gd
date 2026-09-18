@tool
class_name GFFNodeState
extends GFFEffect

## Game Feel Flow Node State
##
## Instant state-switch effects — counterparts of Feel's MMF_SetActive /
## MMF_SetParent / MMF_Enable feedbacks. One effect covers all three via the
## `action` export or a params["action"] string at play time:
##   "visible" | "hidden" | "toggle"   -> CanvasItem/Node3D.visible
##   "enable"  | "disable"             -> Node.process_mode
##   "set_parent"                      -> reparent to params["parent_node"]
##                                      or exported parent_name lookup

@export_group("Node State")
## One of: visible, hidden, toggle, enable, disable, set_parent.
@export var action: StringName = &"visible"
## Scene node name used by set_parent when no params["parent_node"] is given.
@export var parent_name: String = ""
@export var debug_enabled: bool = false

func _init() -> void:
	# State switches are meant to stick — restoring would undo the point of
	# the effect. Callers opt back in via restore_after_play if needed.
	restore_after_play = false

func _execute(node: Node, params: GFFParams) -> void:
	var act := StringName(params.get_string("action", String(action)))
	_dbg("action=" + String(act) + " node=" + str(node))
	match String(act):
		"visible":
			_set_visible(node, true)
		"hidden":
			_set_visible(node, false)
		"toggle":
			_set_visible(node, not _get_visible(node))
		"enable":
			node.process_mode = Node.PROCESS_MODE_INHERIT
		"disable":
			node.process_mode = Node.PROCESS_MODE_DISABLED
		"set_parent":
			var p: Node = params.get_node("parent_node", null)
			if p == null and not parent_name.is_empty():
				p = node.get_tree().root.find_child(parent_name, true, false)
			if p == null:
				push_warning("GFFNodeState: set_parent has no valid parent node")
				return
			if p == node.get_parent():
				return
			node.reparent(p)
		_:
			push_warning("GFFNodeState: unknown action '", act, "'")

func _set_visible(node: Node, v: bool) -> void:
	if node is Node3D or node is CanvasItem:
		node.visible = v
	else:
		push_warning("GFFNodeState: node has no 'visible' property")

func _get_visible(node: Node) -> bool:
	if node is Node3D or node is CanvasItem:
		return node.visible
	return true

func _get_default_duration() -> float:
	return 0.0

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFNodeState] ", message)
