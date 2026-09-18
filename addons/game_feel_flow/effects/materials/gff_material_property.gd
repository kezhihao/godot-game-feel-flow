@tool
class_name GFFMaterialProperty
extends GFFEffect

## Game Feel Flow Material Property
##
## Tweens any material property or shader parameter — counterpart of Feel's
## MMF_Material / MMF_ShaderGlobal-style feedbacks. Works on a per-instance
## duplicated material so shared resources are never mutated.

const MaterialUtil = preload("res://addons/game_feel_flow/core/utils/gff_material_util.gd")

enum PropMode { MATERIAL_PROP, SHADER_PARAM }

@export_group("Material Property")
## Material property name ("albedo_color", "metallic", "uv1_scale"...) or
## shader parameter name when mode is SHADER_PARAM.
@export var property_name: StringName = &"albedo_color"
@export var mode: PropMode = PropMode.MATERIAL_PROP
## Value to reach at the end of the outward leg. float/Color/Vector2/Vector3.
@export var to_value: Variant = Color.WHITE
## Play out-and-back (Feel's typical material pulse) instead of one-way.
@export var ping_pong: bool = true
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	var mi := node as MeshInstance3D
	if mi == null:
		push_warning("GFFMaterialProperty: only MeshInstance3D targets are supported")
		return
	var info := MaterialUtil.acquire(node, 0, true)
	var mat: Material = info["material"]
	if mat == null:
		push_warning("GFFMaterialProperty: target has no material to drive")
		return

	var prop := StringName(params.get_string("property", String(property_name)))
	var to: Variant = params.get_variant("to", to_value)
	var mode_i: int = params.get_int("mode", mode)
	var final_duration := params.get_float("duration", duration)
	var do_ping_pong := params.get_bool("ping_pong", ping_pong)

	var from: Variant
	if mode_i == PropMode.SHADER_PARAM:
		from = mat.get_shader_parameter(prop)
	else:
		from = mat.get(prop)
	if from == null or not _same_family(from, to):
		push_warning("GFFMaterialProperty: '", prop, "' has no readable value compatible with ", to)
		MaterialUtil.release(node, info)
		return

	_dbg("prop=" + String(prop) + " from=" + str(from) + " to=" + str(to)
		+ " ping_pong=" + str(do_ping_pong))

	var total := final_duration * (2.0 if do_ping_pong else 1.0)
	var elapsed := 0.0
	while elapsed < total and _is_playing:
		if not is_instance_valid(node):
			return
		var t: float
		if do_ping_pong:
			var half := final_duration
			t = clampf(elapsed / half, 0.0, 1.0)
			if elapsed > half:
				t = 2.0 - t
		else:
			t = clampf(elapsed / final_duration, 0.0, 1.0)
		var k := _apply_curve(t, easing_curve)
		_set_prop(mat, prop, mode_i, _lerp_variant(from, to, k))
		await node.get_tree().process_frame
		if not is_instance_valid(node) or not _is_playing:
			return
		elapsed += node.get_process_delta_time()

	if is_instance_valid(node):
		_set_prop(mat, prop, mode_i, from if do_ping_pong else to)
		MaterialUtil.release(node, info)

func _set_prop(mat: Material, prop: StringName, mode_i: int, value: Variant) -> void:
	if mode_i == PropMode.SHADER_PARAM:
		mat.set_shader_parameter(prop, value)
	else:
		mat.set(prop, value)

func _same_family(a: Variant, b: Variant) -> bool:
	return typeof(a) == typeof(b)

func _lerp_variant(a: Variant, b: Variant, k: float) -> Variant:
	match typeof(a):
		TYPE_FLOAT, TYPE_INT:
			return lerpf(float(a), float(b), k)
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_COLOR, TYPE_VECTOR4:
			return a.lerp(b, k)
		_:
			return b if k >= 1.0 else a

func _get_default_duration() -> float:
	return 0.4

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFMaterialProperty] ", message)
