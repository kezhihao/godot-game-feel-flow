@tool
class_name GFFImage
extends GFFEffect

## Game Feel Flow Image
##
## Counterpart of Feel's MMF_Image* feedbacks (Image swap, ImageColor,
## ImageAlpha, ImageFill) retargeted to Godot controls:
##   "texture" -> swap `texture` (TextureRect/Sprite2D/Sprite3D),
##                params["texture"] supplies the new Texture2D
##   "color"   -> tween CanvasItem/Label3D modulate toward `to_color`
##   "alpha"   -> tween modulate alpha toward `to_value` (0..1)
##   "fill"    -> tween `value` on Range-derived nodes
##                (TextureProgressBar/ProgressBar) toward `to_value`
## Changed state is restored when restore_after_play is on.

@export_group("Image")
## One of: texture, color, alpha, fill.
@export var image_mode: StringName = &"fill"
## New texture for image_mode="texture". params["texture"] overrides.
@export var to_texture: Texture2D = null
## Target tint for image_mode="color". params["to"] (Color) overrides.
@export var to_color: Color = Color.WHITE
## Target scalar for alpha (0..1) or fill (Range units). params["to"] (float).
@export var to_value: float = 100.0
## Tween back to the start value in the second half of the duration.
@export var ping_pong: bool = true
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	var mode := StringName(params.get_string("image_mode", String(image_mode)))
	var dur: float = maxf(params.duration, 0.01)
	_dbg("mode=" + String(mode) + " node=" + str(node))

	match String(mode):
		"texture":
			var tex_v: Variant = params.get_variant("texture", to_texture)
			if not (tex_v is Texture2D):
				push_warning("GFFImage: texture mode needs params['texture']/to_texture")
				return
			var orig_tex: Variant = _get_prop(node, "texture")
			_set_prop(node, "texture", tex_v)
			var elapsed_t := 0.0
			while elapsed_t < dur and _is_playing:
				await node.get_tree().process_frame
				elapsed_t += node.get_process_delta_time()
			if restore_after_play and is_instance_valid(node):
				_set_prop(node, "texture", orig_tex)
		"color":
			var orig_c: Color = _get_modulate_prop(node)
			var target_c: Color = _to_color(params)
			await _lerp_prop(node, dur,
				func(k: float) -> void:
					var e := _envelope(k)
					_set_modulate_prop(node, orig_c.lerp(target_c, e)))
		"alpha":
			var orig_c2: Color = _get_modulate_prop(node)
			var target_a := params.get_float("to", to_value)
			await _lerp_prop(node, dur,
				func(k: float) -> void:
					var e2 := _envelope(k)
					var c := orig_c2
					c.a = lerpf(orig_c2.a, target_a, e2)
					_set_modulate_prop(node, c))
		"fill":
			var orig_v: Variant = _get_prop(node, "value")
			if orig_v == null:
				push_warning("GFFImage: fill mode needs a Range-derived node")
				return
			var target_v := params.get_float("to", to_value)
			var base_v := float(orig_v)
			await _lerp_prop(node, dur,
				func(k: float) -> void:
					var e3 := _envelope(k)
					_set_prop(node, "value", lerpf(base_v, target_v, e3)))
			if restore_after_play and is_instance_valid(node):
				_set_prop(node, "value", orig_v)
			return
		_:
			push_warning("GFFImage: unknown image_mode '", mode, "'")
			return
	# color/alpha modulate restore is handled by the base _restore_initial_state;
	# texture/fill restore inside their own branches above.

func _lerp_prop(node: Node, dur: float, apply: Callable) -> void:
	var elapsed := 0.0
	while elapsed < dur and _is_playing and is_instance_valid(node):
		await node.get_tree().process_frame
		elapsed += node.get_process_delta_time()
		apply.call(clampf(elapsed / dur, 0.0, 1.0))

func _envelope(k: float) -> float:
	var e := _apply_curve(k, easing_curve)
	if ping_pong:
		e = 1.0 - absf(2.0 * e - 1.0)
	return e

func _to_color(params: GFFParams) -> Color:
	var v: Variant = params.get_variant("to", to_color)
	return v if v is Color else to_color

func _get_prop(node: Node, prop: StringName) -> Variant:
	for p in node.get_property_list():
		if p.name == prop:
			return node.get(prop)
	return null

func _set_prop(node: Node, prop: StringName, value: Variant) -> void:
	for p in node.get_property_list():
		if p.name == prop:
			node.set(prop, value)
			return

func _get_modulate_prop(node: Node) -> Color:
	if node is CanvasItem:
		return node.modulate
	if node is Label3D:
		return node.modulate
	return Color.WHITE

func _set_modulate_prop(node: Node, c: Color) -> void:
	if node is CanvasItem or node is Label3D:
		node.modulate = c

func _get_default_duration() -> float:
	return duration if duration > 0.0 else 0.5

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFImage] ", message)
