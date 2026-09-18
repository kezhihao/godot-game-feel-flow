@tool
class_name GFFPostProcess
extends GFFEffect

## Game Feel Flow Post Process
##
## Deeper post-processing counterpart of Feel's URP/HDRP volume feedbacks —
## complements GFFEnvironment (basic ambient/fog/glow) with the rest of the
## Environment feature set plus CameraAttributes DOF.
## post_prop (params["prop"] overrides), each lerped current -> `to` with
## optional ping_pong, and auto-enables the matching feature flag:
##   ssao_intensity / ssao_radius   (ssao_enabled)
##   ssil_intensity                 (ssil_enabled)
##   sdfgi_energy                   (sdfgi_enabled)
##   glow_strength / glow_bloom     (glow_enabled)
##   fog_density / fog_light_energy (fog_enabled)
##   vfog_density / vfog_albedo     (volumetric_fog_enabled)
##   adj_brightness / adj_contrast / adj_saturation (adjustment_enabled)
##   dof_blur_amount / dof_blur_far (CameraAttributesPractical dof_blur_*)
## Environment/attributes are duplicated before write (no shared-resource
## pollution) and restored afterwards.

enum PostProp {
	SSAO_INTENSITY, SSAO_RADIUS, SSIL_INTENSITY, SDFGI_ENERGY,
	GLOW_STRENGTH, GLOW_BLOOM, FOG_DENSITY, FOG_LIGHT_ENERGY,
	VFOG_DENSITY, VFOG_ALBEDO,
	ADJ_BRIGHTNESS, ADJ_CONTRAST, ADJ_SATURATION,
	DOF_BLUR_AMOUNT, DOF_BLUR_FAR,
}

@export_group("Post Process")
@export var post_prop: PostProp = PostProp.GLOW_BLOOM
## Target scalar. params["to"] overrides. params["to_color"] for vfog_albedo.
@export var to_value: float = 0.5
@export var to_color: Color = Color(0.5, 0.5, 0.5)
@export var ping_pong: bool = true
@export var debug_enabled: bool = false

const _PROP_INFO := {
	"ssao_intensity": ["ssao_intensity", "ssao_enabled"],
	"ssao_radius": ["ssao_radius", "ssao_enabled"],
	"ssil_intensity": ["ssil_intensity", "ssil_enabled"],
	"sdfgi_energy": ["sdfgi_energy", "sdfgi_enabled"],
	"glow_strength": ["glow_strength", "glow_enabled"],
	"glow_bloom": ["glow_bloom", "glow_enabled"],
	"fog_density": ["fog_density", "fog_enabled"],
	"fog_light_energy": ["fog_light_energy", "fog_enabled"],
	"vfog_density": ["volumetric_fog_density", "volumetric_fog_enabled"],
	"vfog_albedo": ["volumetric_fog_albedo", "volumetric_fog_enabled"],
	"adj_brightness": ["adjustment_brightness", "adjustment_enabled"],
	"adj_contrast": ["adjustment_contrast", "adjustment_enabled"],
	"adj_saturation": ["adjustment_saturation", "adjustment_enabled"],
	"dof_blur_amount": ["dof_blur_amount", "dof_blur_near_enabled"],
	"dof_blur_far": ["dof_blur_far_distance", "dof_blur_far_enabled"],
}

func _execute(node: Node, params: GFFParams) -> void:
	var key := String(params.get_string("prop", PostProp.keys()[post_prop].to_lower()))
	if not _PROP_INFO.has(key):
		push_warning("GFFPostProcess: unknown prop '", key, "'")
		return
	var info: Array = _PROP_INFO[key]
	var prop := StringName(info[0])
	var flag := StringName(info[1])
	var on_camera := key.begins_with("dof_")

	# Resolve the resource to write: duplicated Environment or CameraAttributes.
	# Keep the ORIGINAL resource reference (may be null) so restore can put back
	# exactly what was there — including "nothing": a freshly created resource
	# carries engine defaults (e.g. dof_blur_amount = 0.1) that were never on
	# the target before play.
	var owner_node: Node = node
	var res: Resource = null
	var orig_res: Resource = null
	if on_camera:
		var cam := _find_camera(node)
		if cam == null:
			push_warning("GFFPostProcess: DOF props need a Camera3D target")
			return
		orig_res = cam.attributes
		cam.attributes = orig_res.duplicate() if orig_res else CameraAttributesPractical.new()
		res = cam.attributes
		owner_node = cam
	else:
		var we := _find_world_env(node)
		if we == null:
			push_warning("GFFPostProcess: env props need a WorldEnvironment target")
			return
		orig_res = we.environment
		we.environment = orig_res.duplicate() if orig_res else Environment.new()
		res = we.environment
		owner_node = we

	var orig: Variant = res.get(prop)
	res.set(flag, true)
	var target: Variant = _target_value(key, params)
	var dur: float = maxf(params.duration, 0.01)
	var elapsed := 0.0
	_dbg("prop=" + prop + " to=" + str(target) + " on " + str(owner_node))
	while elapsed < dur and _is_playing and is_instance_valid(res):
		await owner_node.get_tree().process_frame
		elapsed += owner_node.get_process_delta_time()
		var k := clampf(elapsed / dur, 0.0, 1.0)
		var e := _apply_curve(k, easing_curve)
		if ping_pong:
			e = 1.0 - absf(2.0 * e - 1.0)
		res.set(prop, _lerp_variant(orig, target, e))

	if restore_after_play and is_instance_valid(owner_node):
		# Reassign the original resource wholesale: restores the pre-play state
		# exactly (including "no resource") and drops the mutated duplicate —
		# flag toggles like dof_blur_near_enabled go away with it.
		if on_camera:
			(owner_node as Camera3D).attributes = orig_res
		else:
			(owner_node as WorldEnvironment).environment = orig_res

func _target_value(key: String, params: GFFParams) -> Variant:
	if key == "vfog_albedo":
		var c: Variant = params.get_variant("to", to_color)
		return c if c is Color else to_color
	return params.get_float("to", to_value)

func _lerp_variant(a: Variant, b: Variant, k: float) -> Variant:
	if a is Color and b is Color:
		return a.lerp(b, k)
	return lerpf(float(a), float(b), k)

func _find_world_env(node: Node) -> WorldEnvironment:
	if node is WorldEnvironment:
		return node
	var tree := node.get_tree() if node else null
	if tree and tree.root:
		return _find_env_recursive(tree.root)
	return null

func _find_env_recursive(n: Node) -> WorldEnvironment:
	if n is WorldEnvironment:
		return n
	for c in n.get_children():
		var r := _find_env_recursive(c)
		if r:
			return r
	return null

func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node
	if node:
		var vp := node.get_viewport()
		if vp:
			return vp.get_camera_3d()
	return null

func _resolve_target(target: Node) -> Node:
	# WorldEnvironment is a plain Node — base only accepts Node2D/3D/Control.
	if target is WorldEnvironment:
		return target
	return super._resolve_target(target)

func _get_default_duration() -> float:
	return duration if duration > 0.0 else 0.5

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFPostProcess] ", message)
