@tool
class_name GFFColliderState
extends GFFEffect

## Game Feel Flow Collider State
##
## Enable/disable collision shapes — counterpart of Feel's MMF_Collider
## feedbacks (Collider enable, Collider toggle). Actions: "enable",
## "disable", "toggle". Targets a CollisionShape2D/3D directly or a body/
## container — in that case every descendant collision shape is switched.
## Area monitoring is toggled alongside when present.

@export_group("Collider")
## One of: enable, disable, toggle.
@export var action: StringName = &"toggle"
## Also flip monitoring/monitorable on Area2D/Area3D targets.
@export var affect_area_monitoring: bool = true
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	var act := StringName(params.get_string("action", String(action)))
	var shapes := _collect_shapes(node)
	if shapes.is_empty():
		push_warning("GFFColliderState: no collision shapes found on ", node.name)
		return
	for s in shapes:
		var cur: bool = s.disabled
		var next: bool
		match String(act):
			"enable": next = false
			"disable": next = true
			"toggle": next = not cur
			_:
				push_warning("GFFColliderState: unknown action '", act, "'")
				return
		# disabled must be changed outside the physics step.
		s.set_deferred(&"disabled", next)
	if affect_area_monitoring and (node is Area2D or node is Area3D):
		var on := String(act) != "disable"
		if String(act) == "toggle":
			on = not node.monitoring
		node.set_deferred(&"monitoring", on)
		node.set_deferred(&"monitorable", on)
	_dbg("action=" + String(act) + " shapes=" + str(shapes.size()))

func _collect_shapes(node: Node) -> Array:
	var out: Array = []
	if node is CollisionShape2D or node is CollisionShape3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_collect_shapes(child))
	return out

func _get_default_duration() -> float:
	return 0.0

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFColliderState] ", message)
