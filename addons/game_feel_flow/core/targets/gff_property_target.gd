@tool
@icon("res://addons/game_feel_flow/icons/icon_material_target.svg")
class_name GFFPropertyTarget
extends GFFTarget

## Game Feel Flow Property Target
##
## Generic target that reads/writes any numeric property on the node by name
## (float / Vector2 / Vector3 / Color), e.g. "light_energy", "pitch_scale",
## "size", "value". Prefix "shader:" resolves a shader parameter on the
## surface material's ShaderMaterial; prefix "material:" resolves any property
## on the surface material (StandardMaterial3D fields like "metalness" work,
## and it falls back to shader params on ShaderMaterial).
##
## Powers the dedicated spring family — one class per Feel MMSpring_* variant
## without needing a bespoke target per property.

enum Mode { TO_TARGET, BY_AMOUNT, FROM_TARGET }

@export var property_path: String = ""
@export var mode: Mode = Mode.BY_AMOUNT
## Which typed target_value is used depends on the live property's type.
@export var target_float: float = 1.0
@export var target_vector2: Vector2 = Vector2.ONE
@export var target_vector3: Vector3 = Vector3.ONE
@export var target_color: Color = Color.WHITE

@export var debug_enabled: bool = false

func get_value_type() -> GFFValueType.Value:
	return GFFValueType.Value.FLOAT

func _read(node: Node) -> Variant:
	if node == null or property_path.is_empty():
		return null
	if property_path.begins_with("shader:"):
		return _read_shader_param(node)
	if property_path.begins_with("material:"):
		return _read_material_prop(node)
	return node.get(property_path)

func _write(node: Node, value: Variant) -> void:
	if node == null or property_path.is_empty():
		return
	if property_path.begins_with("shader:"):
		_write_shader_param(node, value)
	elif property_path.begins_with("material:"):
		_write_material_prop(node, value)
	else:
		node.set(property_path, value)

func _scaled_target(v: Variant, intensity: float) -> Variant:
	match typeof(v):
		TYPE_FLOAT, TYPE_INT:
			return target_float * intensity
		TYPE_VECTOR2:
			return target_vector2 * intensity
		TYPE_VECTOR3:
			return target_vector3 * intensity
		TYPE_COLOR:
			return Color(target_color.r * intensity, target_color.g * intensity,
				target_color.b * intensity, target_color.a * intensity)
	return target_float * intensity

func get_initial_value(node: Node) -> Variant:
	var v: Variant = _read(node)
	if v == null:
		return 0.0
	return v

func get_start_value(node: Node, intensity: float) -> Variant:
	if mode == Mode.FROM_TARGET:
		return _scaled_target(_read(node), intensity)
	return get_initial_value(node)

func get_end_value(node: Node, intensity: float) -> Variant:
	var initial: Variant = get_initial_value(node)
	var scaled: Variant = _scaled_target(initial, intensity)
	match mode:
		Mode.TO_TARGET:
			return scaled
		Mode.BY_AMOUNT:
			return _add(initial, scaled)
		Mode.FROM_TARGET:
			return initial
	return initial

func _add(a: Variant, b: Variant) -> Variant:
	if a is Color and b is Color:
		return Color(a.r + b.r, a.g + b.g, a.b + b.b, a.a + b.a)
	if typeof(a) == typeof(b) or (a is float and b is int) or (a is int and b is float):
		return a + b
	return a

func apply_value(node: Node, value: Variant) -> void:
	_write(node, value)

func apply_params(params: GFFParams) -> void:
	if params == null:
		return
	var v: Variant = params.get_variant("amount", params.get_variant("value", null))
	if v == null:
		return
	match typeof(v):
		TYPE_FLOAT, TYPE_INT:
			target_float = float(v)
		TYPE_VECTOR2:
			target_vector2 = v
		TYPE_VECTOR3:
			target_vector3 = v
		TYPE_COLOR:
			target_color = v

func get_target_name() -> String:
	return "Property(" + property_path + ")"

func can_restore(node: Node) -> bool:
	return _read(node) != null

func get_restorable_state(node: Node) -> Dictionary:
	return {"_prop_value": _read(node)}

func restore_state(node: Node, state: Dictionary) -> void:
	if state.has("_prop_value"):
		_write(node, state["_prop_value"])

# ===== Shader param resolution =====

func _shader_param_name() -> String:
	return property_path.substr(7)

func _surface_material(node: Node) -> Material:
	if node is MeshInstance3D:
		var m: Material = node.get_surface_override_material(0)
		if m == null and node.mesh != null:
			m = node.mesh.surface_get_material(0)
		return m
	if node is GeometryInstance3D:
		return node.material_override
	if node is CanvasItem:
		return node.material
	return null

func _read_shader_param(node: Node) -> Variant:
	var m: Material = _surface_material(node)
	if m is ShaderMaterial:
		return m.get_shader_parameter(_shader_param_name())
	return null

func _write_shader_param(node: Node, value: Variant) -> void:
	var m: Material = _surface_material(node)
	if m is ShaderMaterial:
		m.set_shader_parameter(_shader_param_name(), value)
	elif debug_enabled:
		print("[GFFPropertyTarget] no ShaderMaterial on ", node.name, " for ", property_path)

func _material_prop_name() -> String:
	return property_path.substr("material:".length())

func _read_material_prop(node: Node) -> Variant:
	var m: Material = _surface_material(node)
	if m == null:
		return null
	var prop: String = _material_prop_name()
	var v: Variant = m.get(prop)
	if v == null and m is ShaderMaterial:
		v = m.get_shader_parameter(prop)
	return v

func _write_material_prop(node: Node, value: Variant) -> void:
	var m: Material = _surface_material(node)
	if m == null:
		if debug_enabled:
			print("[GFFPropertyTarget] no material on ", node.name, " for ", property_path)
		return
	var prop: String = _material_prop_name()
	if m.get(prop) == null and m is ShaderMaterial:
		m.set_shader_parameter(prop, value)
	else:
		m.set(prop, value)
