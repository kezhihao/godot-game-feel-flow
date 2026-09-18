@tool
class_name GFFTargetResolver
extends RefCounted

## Game Feel Flow Target Resolver
##
## Shared target-acquisition helper — counterpart of Feel's
## MMFeedbackTargetAcquisition. Effects take an origin node plus a mode and
## resolve the actual receiver node:
##   SELF          -> the origin itself
##   PARENT        -> origin.get_parent()
##   CHILD         -> recursive find_child(name) below origin
##   NAMED         -> scene-wide find_child(name) from the tree root
##   GROUP_FIRST   -> first node in `group`
##   GROUP_CLOSEST -> node in `group` nearest to origin (2D/3D aware)
##   ALL_IN_GROUP  -> resolve() returns first, resolve_all() returns everyone

enum Mode {
	SELF,
	PARENT,
	CHILD,
	NAMED,
	GROUP_FIRST,
	GROUP_CLOSEST,
	ALL_IN_GROUP,
}

static var debug_enabled: bool = false

static func resolve(origin: Node, mode: int, node_name: String = "", group: StringName = &"") -> Node:
	if origin == null or not is_instance_valid(origin):
		return null
	match mode:
		Mode.SELF:
			return origin
		Mode.PARENT:
			return origin.get_parent()
		Mode.CHILD:
			if node_name.is_empty():
				push_warning("GFFTargetResolver: CHILD mode needs node_name")
				return null
			return origin.find_child(node_name, true, false)
		Mode.NAMED:
			var tree := origin.get_tree()
			if tree == null or tree.root == null:
				return null
			return tree.root.find_child(node_name, true, false)
		Mode.GROUP_FIRST, Mode.ALL_IN_GROUP:
			var tree2 := origin.get_tree()
			if tree2 == null:
				return null
			return tree2.get_first_node_in_group(group)
		Mode.GROUP_CLOSEST:
			var tree3 := origin.get_tree()
			if tree3 == null:
				return null
			var best: Node = null
			var best_dist := INF
			var o := _global_pos(origin)
			for candidate in tree3.get_nodes_in_group(group):
				if candidate == origin:
					continue
				var d: float = o.distance_to(_global_pos(candidate))
				if d < best_dist:
					best_dist = d
					best = candidate
			return best
	return null

static func resolve_all(origin: Node, mode: int, node_name: String = "", group: StringName = &"") -> Array:
	if mode == Mode.ALL_IN_GROUP:
		var tree := origin.get_tree() if origin and is_instance_valid(origin) else null
		if tree == null:
			return []
		return tree.get_nodes_in_group(group)
	var single := resolve(origin, mode, node_name, group)
	return [single] if single != null else []

static func _global_pos(node: Node) -> Vector3:
	if node is Node3D:
		return node.global_position
	if node is Node2D:
		var p: Vector2 = node.global_position
		return Vector3(p.x, p.y, 0.0)
	if node is Control:
		var c: Vector2 = node.global_position
		return Vector3(c.x, c.y, 0.0)
	return Vector3.ZERO
