@tool
class_name GFFEnvironment
extends GFFEffect

## Game Feel Flow Environment
##
## Tweens Environment resource properties on a WorldEnvironment node —
## counterpart of Feel's MMF_Skybox / volume-blend feedbacks. The environment
## is duplicated before writing so a shared Environment resource is never
## mutated, then swapped back when the effect ends.

enum EnvProp {
	AMBIENT_ENERGY,
	AMBIENT_COLOR,
	FOG_DENSITY,
	GLOW_INTENSITY,
	TONEMAP_EXPOSURE,
	ADJUSTMENT_BRIGHTNESS,
	ADJUSTMENT_SATURATION,
}

@export_group("Environment")
@export var env_property: EnvProp = EnvProp.AMBIENT_ENERGY
## Destination value (float, or Color for AMBIENT_COLOR).
@export var to_value: Variant = 0.2
## Out-and-back pulse; when false the property stays at to_value.
@export var ping_pong: bool = true
@export var debug_enabled: bool = false

func _resolve_target(target: Node) -> Node:
	# WorldEnvironment is a plain Node — the base resolver only accepts
	# Node2D/Node3D/Control, so accept it directly here.
	if target is WorldEnvironment:
		return target
	return super._resolve_target(target)

func _execute(node: Node, params: GFFParams) -> void:
	var we := node as WorldEnvironment
	if we == null or we.environment == null:
		push_warning("GFFEnvironment: needs a WorldEnvironment target with an Environment")
		return
	var prop_i: int = params.get_int("env_property", env_property)
	var to: Variant = params.get_variant("to", to_value)
	var final_duration := params.get_float("duration", duration)
	var do_ping_pong := params.get_bool("ping_pong", ping_pong)
	var intensity := params.get_float("intensity", 1.0)

	var prop := _prop_name(prop_i)
	if prop.is_empty():
		push_warning("GFFEnvironment: unsupported property ", prop_i)
		return

	# Work on a duplicate so the original Environment resource stays clean.
	var original := we.environment
	var env := original.duplicate() as Environment
	we.environment = env
	_enable_if_needed(env, prop_i)

	var from: Variant = env.get(prop)
	if typeof(from) == TYPE_FLOAT:
		to = lerpf(float(from), float(to), intensity)
	_dbg("prop=" + prop + " from=" + str(from) + " to=" + str(to))

	var total := final_duration * (2.0 if do_ping_pong else 1.0)
	var elapsed := 0.0
	while elapsed < total and _is_playing:
		if not is_instance_valid(node) or we.environment != env:
			return
		var t: float
		if do_ping_pong:
			t = clampf(elapsed / final_duration, 0.0, 1.0)
			if elapsed > final_duration:
				t = 2.0 - t
		else:
			t = clampf(elapsed / final_duration, 0.0, 1.0)
		env.set(prop, _lerp_variant(from, to, _apply_curve(t, easing_curve)))
		await node.get_tree().process_frame
		if not is_instance_valid(node) or not _is_playing:
			return
		elapsed += node.get_process_delta_time()

	if is_instance_valid(we) and we.environment == env:
		env.set(prop, from if do_ping_pong else to)
		we.environment = original

func _prop_name(prop_i: int) -> StringName:
	match prop_i:
		EnvProp.AMBIENT_ENERGY: return &"ambient_light_energy"
		EnvProp.AMBIENT_COLOR: return &"ambient_light_color"
		EnvProp.FOG_DENSITY: return &"fog_density"
		EnvProp.GLOW_INTENSITY: return &"glow_intensity"
		EnvProp.TONEMAP_EXPOSURE: return &"tonemap_exposure"
		EnvProp.ADJUSTMENT_BRIGHTNESS: return &"adjustment_brightness"
		EnvProp.ADJUSTMENT_SATURATION: return &"adjustment_saturation"
	return &""

## Some properties only render when their feature flag is on — flip the flag
## for the duration so the tween is actually visible.
func _enable_if_needed(env: Environment, prop_i: int) -> void:
	match prop_i:
		EnvProp.AMBIENT_ENERGY, EnvProp.AMBIENT_COLOR:
			if env.ambient_light_source == Environment.AMBIENT_SOURCE_DISABLED:
				env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		EnvProp.FOG_DENSITY:
			env.fog_enabled = true
		EnvProp.GLOW_INTENSITY:
			env.glow_enabled = true
		EnvProp.ADJUSTMENT_BRIGHTNESS, EnvProp.ADJUSTMENT_SATURATION:
			env.adjustment_enabled = true

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
		print("[GFFEnvironment] ", message)
