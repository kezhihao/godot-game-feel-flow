@tool
class_name GFFLooper
extends GFFEffect

## Game Feel Flow Looper
##
## Counterpart of Feel's MMF_Looper — replays a referenced effect/combo
## `repeat_count` times on the same node, `interval` seconds between plays.
## The inner payload resolves in priority order:
##   params["effect_name"] / params["combo_name"]  (registry lookup)
##   `inner_effect` / `inner_combo`                (resource references)
##   `effect_name` / `combo_name` exports          (registry names)

@export_group("Looper")
## Registry effect name repeated when no resource/param payload is given.
@export var effect_name: String = ""
## Registry combo name repeated (only if effect_name resolves to nothing).
@export var combo_name: String = ""
## Inline effect resource (duplicated per play — safe for repeat).
@export var inner_effect: GFFEffect = null
## Inline combo resource.
@export var inner_combo: GFFCombo = null
## Extra repetitions. 1 = play twice total; Feel's NumberOfRepeats semantics.
@export var repeat_count: int = 1
## Seconds between iterations.
@export var interval: float = 0.0
@export var debug_enabled: bool = false

func _init() -> void:
	# The inner effect handles its own restore.
	restore_after_play = false

func _execute(node: Node, params: GFFParams) -> void:
	var repeats := params.get_int("repeat_count", repeat_count)
	var gap := params.get_float("interval", interval)
	var gff := _gff(node)
	for i in range(repeats + 1):
		if not _is_playing:
			return
		var played := await _play_once(gff, node, params)
		if not played:
			return
		if i < repeats and gap > 0.0 and is_instance_valid(node):
			await node.get_tree().create_timer(gap, true, false, true).timeout
	_dbg("looper done repeats=" + str(repeats))

func _play_once(gff: Node, node: Node, params: GFFParams) -> bool:
	var eff_name := String(params.get_string("effect_name", effect_name))
	var cmb_name := String(params.get_string("combo_name", combo_name))
	var inner_p: GFFParams = GFFParams.create(params.intensity, params.duration)

	if gff and not eff_name.is_empty() and gff.get_effect(eff_name):
		await gff.play(eff_name, node, inner_p)
		_dbg("loop play effect=" + eff_name)
		return true
	if gff and not cmb_name.is_empty() and gff.get_combo(cmb_name):
		await gff.play_combo(cmb_name, node, inner_p)
		_dbg("loop play combo=" + cmb_name)
		return true
	if inner_effect:
		var inst: GFFEffect = inner_effect.duplicate(true)
		if gff:
			await gff.play(inst, node, inner_p)
		else:
			await inst.apply(node, inner_p)
		return true
	if inner_combo:
		await inner_combo.duplicate(true).execute(node, inner_p)
		return true
	push_warning("GFFLooper: no effect/combo payload resolved")
	return false

func _gff(node: Node) -> Node:
	var tree := node.get_tree() if node and is_instance_valid(node) else Engine.get_main_loop()
	if tree is SceneTree and tree.root:
		return tree.root.get_node_or_null("GameFeelFlow")
	return null

func _get_default_duration() -> float:
	return 0.0

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFLooper] ", message)
