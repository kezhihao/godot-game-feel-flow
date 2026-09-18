@tool
class_name GFFText
extends GFFEffect

## Game Feel Flow Text
##
## Counterpart of Feel's MMF_Text / MMF_TextColor feedbacks, retargeted to
## Godot text nodes (Label, RichTextLabel, Button, Label3D).
## text_mode selects the behavior (params["text_mode"] overrides):
##   "typewriter" -> reveal `text` (or current text) char-by-char via
##                  visible_ratio over `duration` (or chars_per_sec)
##   "set"        -> instantly replace the text
##   "append"     -> append `text` to the current content
##   "color"      -> tween the font color toward `to_color`
## Original text/ratio/color is restored when restore_after_play is on.

@export_group("Text")
## One of: typewriter, set, append, color.
@export var text_mode: StringName = &"typewriter"
## Payload text for typewriter/set/append. params["text"] overrides.
@export var text: String = ""
## >0: reveal this many chars per second (typewriter), ignoring duration.
@export var chars_per_sec: float = 0.0
## Target color for text_mode="color". params["to"] overrides.
@export var to_color: Color = Color.WHITE
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	var mode := StringName(params.get_string("text_mode", String(text_mode)))
	var payload := String(params.get_string("text", text))

	# Save text-node state the base restore doesn't cover.
	var orig_text := _get_text(node)
	var orig_ratio := _get_ratio(node)
	var orig_color := _get_font_color(node)
	_dbg("mode=" + String(mode) + " node=" + str(node))

	match String(mode):
		"typewriter":
			if not payload.is_empty():
				_set_text(node, payload)
			_set_ratio(node, 0.0)
			var full := _get_text(node).length()
			var dur := params.duration
			if chars_per_sec > 0.0 and full > 0:
				dur = float(full) / chars_per_sec
			if dur <= 0.0:
				dur = 0.01
			var elapsed := 0.0
			while elapsed < dur and _is_playing:
				await node.get_tree().process_frame
				elapsed += node.get_process_delta_time()
				_set_ratio(node, clampf(elapsed / dur, 0.0, 1.0))
		"set":
			_set_text(node, payload)
		"append":
			_set_text(node, orig_text + payload)
		"color":
			var target := _get_color_param(params)
			var dur2: float = maxf(params.duration, 0.01)
			var elapsed2 := 0.0
			while elapsed2 < dur2 and _is_playing:
				await node.get_tree().process_frame
				elapsed2 += node.get_process_delta_time()
				var k := clampf(elapsed2 / dur2, 0.0, 1.0)
				_set_font_color(node, orig_color.lerp(target, _apply_curve(k, easing_curve)))
		_:
			push_warning("GFFText: unknown text_mode '", mode, "'")
			return

	# Custom restore: base only knows transform/modulate.
	if restore_after_play and is_instance_valid(node):
		_set_text(node, orig_text)
		_set_ratio(node, orig_ratio)
		_set_font_color(node, orig_color)

func _get_color_param(params: GFFParams) -> Color:
	var v: Variant = params.get_variant("to", to_color)
	return v if v is Color else to_color

# ----- text node helpers (Label / RichTextLabel / Button / Label3D) -----

func _get_text(node: Node) -> String:
	if node is Label or node is RichTextLabel or node is Button or node is Label3D:
		return node.text
	return ""

func _set_text(node: Node, value: String) -> void:
	if node is Label or node is RichTextLabel or node is Button or node is Label3D:
		node.text = value

func _get_ratio(node: Node) -> float:
	if node is Label or node is RichTextLabel:
		return node.visible_ratio
	return 1.0

func _set_ratio(node: Node, r: float) -> void:
	if node is Label or node is RichTextLabel:
		node.visible_ratio = r

func _get_font_color(node: Node) -> Color:
	if node is Label3D:
		return node.modulate
	if node is Control and node.has_theme_color("font_color"):
		return node.get_theme_color("font_color")
	return Color.WHITE

func _set_font_color(node: Node, c: Color) -> void:
	if node is Label3D:
		node.modulate = c
	elif node is Control:
		node.add_theme_color_override("font_color", c)

func _get_default_duration() -> float:
	return duration if duration > 0.0 else 0.6

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFText] ", message)
