@tool
class_name GFFLight
extends GFFEffect

## Game Feel Flow Light
##
## Tweens Light3D properties — counterpart of Feel's MMF_Light feedback.
## ENERGY/COLOR work on every light; RANGE maps to omni_range or spot_range,
## SPOT_ANGLE to spot_angle. ping_pong gives the classic out-and-back flash.

enum LightProp { ENERGY, COLOR, RANGE, SPOT_ANGLE }

@export_group("Light")
@export var light_property: LightProp = LightProp.ENERGY
## Destination value: float for ENERGY/RANGE/SPOT_ANGLE, Color for COLOR.
@export var to_value: Variant = 0.2
## Out-and-back pulse (Feel's default light flash behaviour).
@export var ping_pong: bool = true
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	var light := node as Light3D
	if light == null:
		push_warning("GFFLight: only Light3D targets are supported")
		return
	var prop_i: int = params.get_int("light_property", light_property)
	var to: Variant = params.get_variant("to", to_value)
	var final_duration := params.get_float("duration", duration)
	var do_ping_pong := params.get_bool("ping_pong", ping_pong)
	var intensity := params.get_float("intensity", 1.0)

	var prop := _resolve_prop(light, prop_i)
	if prop.is_empty():
		push_warning("GFFLight: property ", prop_i, " not available on ", node.get_class())
		return
	var from: Variant = light.get(prop)
	if prop_i == LightProp.ENERGY:
		to = lerpf(from, float(to), intensity)

	_dbg("prop=" + prop + " from=" + str(from) + " to=" + str(to))

	var total := final_duration * (2.0 if do_ping_pong else 1.0)
	var elapsed := 0.0
	while elapsed < total and _is_playing:
		if not is_instance_valid(node):
			return
		var t: float
		if do_ping_pong:
			t = clampf(elapsed / final_duration, 0.0, 1.0)
			if elapsed > final_duration:
				t = 2.0 - t
		else:
			t = clampf(elapsed / final_duration, 0.0, 1.0)
		var k := _apply_curve(t, easing_curve)
		light.set(prop, _lerp_variant(from, to, k))
		await node.get_tree().process_frame
		if not is_instance_valid(node) or not _is_playing:
			return
		elapsed += node.get_process_delta_time()

	if is_instance_valid(node):
		light.set(prop, from if do_ping_pong else to)

func _resolve_prop(light: Light3D, prop_i: int) -> StringName:
	match prop_i:
		LightProp.ENERGY:
			return &"light_energy"
		LightProp.COLOR:
			return &"light_color"
		LightProp.RANGE:
			if light is OmniLight3D:
				return &"omni_range"
			if light is SpotLight3D:
				return &"spot_range"
			return &""
		LightProp.SPOT_ANGLE:
			if light is SpotLight3D:
				return &"spot_angle"
			return &""
	return &""

func _lerp_variant(a: Variant, b: Variant, k: float) -> Variant:
	match typeof(a):
		TYPE_FLOAT, TYPE_INT:
			return lerpf(float(a), float(b), k)
		TYPE_COLOR:
			return a.lerp(b, k)
		_:
			return b if k >= 1.0 else a

func _get_default_duration() -> float:
	return 0.4

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFLight] ", message)
