@tool
class_name GFFFloatingText
extends GFFEffect

## Game Feel Flow Floating Text
##
## Counterpart of Feel's MMFloatingText — spawns a world-space Label3D (or
## screen-space Label when world_space=false) at the target's position,
## floats it along `float_direction` over `duration`, fades alpha to 0,
## then frees it. params["text"]/["position"]/["color"] override exports.

@export_group("Floating Text")
@export var text: String = "99"
## Direction (normalized internally) the label travels over its life.
@export var float_direction: Vector3 = Vector3.UP
## World units travelled over `duration`.
@export var distance: float = 1.5
@export var font_size: int = 48
@export var color: Color = Color(1.0, 0.9, 0.2)
@export var fade_out: bool = true
## true = Label3D in world space; false = Label under a CanvasLayer.
@export var world_space: bool = true
## Start offset added to the target position. params["position"] adds too.
@export var spawn_offset: Vector3 = Vector3(0.0, 0.8, 0.0)
@export var debug_enabled: bool = false

func _init() -> void:
	# The spawned label owns its lifecycle — the origin node is untouched.
	restore_after_play = false

func _execute(node: Node, params: GFFParams) -> void:
	var label_node: Node
	if world_space:
		var l3 := Label3D.new()
		l3.font_size = font_size
		l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label_node = l3
	else:
		var l2 := Label.new()
		l2.add_theme_font_size_override("font_size", font_size)
		label_node = l2
	label_node.name = "GFFFloatingText"
	label_node.text = String(params.get_string("text", text))

	var col := _color_param(params)
	if label_node is Label3D:
		label_node.modulate = col
	else:
		label_node.add_theme_color_override("font_color", col)

	var parent: Node = params.get_node("parent_node", null)
	if parent == null:
		parent = node.get_parent()
	if parent == null:
		parent = node.get_tree().root
	parent.add_child(label_node)

	var start := _origin_pos(node) + spawn_offset + params.get_vector3("position", Vector3.ZERO)
	_set_pos(label_node, start)
	_dbg("spawn " + str(label_node) + " at " + str(start))

	var dir := float_direction.normalized()
	if dir.is_zero_approx():
		dir = Vector3.UP
	var dur: float = maxf(params.duration, 0.01)
	var dist := params.get_float("distance", distance)
	var elapsed := 0.0
	while elapsed < dur and _is_playing and is_instance_valid(label_node):
		await node.get_tree().process_frame
		elapsed += node.get_process_delta_time()
		var t := clampf(elapsed / dur, 0.0, 1.0)
		_set_pos(label_node, start + dir * dist * _apply_curve(t, easing_curve))
		if fade_out:
			_set_alpha(label_node, col, 1.0 - t)

	if is_instance_valid(label_node):
		label_node.queue_free()
	_dbg("freed")

func _color_param(params: GFFParams) -> Color:
	var v: Variant = params.get_variant("color", color)
	return v if v is Color else color

func _origin_pos(node: Node) -> Vector3:
	if node is Node3D:
		return node.global_position
	if node is Node2D:
		var p: Vector2 = node.global_position
		return Vector3(p.x, p.y, 0.0)
	return Vector3.ZERO

func _set_pos(n: Node, p: Vector3) -> void:
	if n is Label3D:
		n.global_position = p
	elif n is Label:
		n.global_position = Vector2(p.x, p.y)

func _set_alpha(n: Node, base: Color, a: float) -> void:
	var c := base
	c.a = clampf(a, 0.0, 1.0)
	if n is Label3D:
		n.modulate = c
	elif n is Label:
		n.add_theme_color_override("font_color", c)

func _get_default_duration() -> float:
	return duration if duration > 0.0 else 0.8

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFFloatingText] ", message)
