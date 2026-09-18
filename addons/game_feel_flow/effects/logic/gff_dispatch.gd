@tool
class_name GFFDispatch
extends GFFEffect

## Game Feel Flow Dispatch (player chain / player control)
##
## Counterpart of Feel's MMF_PlayerChain / MMF_Feedbacks / MMF_PlayerControl
## feedbacks — triggers or stops another registered effect/combo on a node
## resolved by GFFTargetResolver (GF-63 acquisition modes).
## dispatch_action:
##   "play" -> GameFeelFlow.play/play_combo on the resolved node.
##            await_play=false fires and forgets (call_deferred), true awaits.
##   "stop" -> GameFeelFlow.stop_all on the resolved node.
## Payload priority: params["effect_name"]/params["combo_name"] >
## inner_effect/inner_combo > effect_name/combo_name exports.

const ResolverScript = preload("res://addons/game_feel_flow/core/utils/gff_target_resolver.gd")

@export_group("Dispatch")
## One of: play, stop.
@export var dispatch_action: StringName = &"play"
@export var effect_name: String = ""
@export var combo_name: String = ""
@export var inner_effect: GFFEffect = null
@export var inner_combo: GFFCombo = null
## When false, play is deferred — the dispatch effect finishes instantly.
@export var await_play: bool = false

@export_group("Target")
## GFFTargetResolver.Mode index: 0 SELF, 1 PARENT, 2 CHILD, 3 NAMED,
## 4 GROUP_FIRST, 5 GROUP_CLOSEST, 6 ALL_IN_GROUP.
@export var target_mode: int = 0
@export var target_name: String = ""
@export var target_group: StringName = &""
@export var debug_enabled: bool = false

func _init() -> void:
	restore_after_play = false

func _execute(node: Node, params: GFFParams) -> void:
	var act := StringName(params.get_string("action", String(dispatch_action)))
	var mode := params.get_int("target_mode", target_mode)
	var tname := String(params.get_string("target_name", target_name))
	var tgroup := StringName(params.get_string("target_group", String(target_group)))
	var receivers: Array = ResolverScript.resolve_all(node, mode, tname, tgroup)
	if receivers.is_empty():
		push_warning("GFFDispatch: no receiver resolved (mode=", mode, ")")
		return

	var gff := _gff(node)
	if gff == null:
		push_warning("GFFDispatch: GameFeelFlow singleton unavailable")
		return

	for receiver in receivers:
		if not is_instance_valid(receiver):
			continue
		match String(act):
			"play":
				_play_on(gff, receiver, params)
			"stop":
				gff.stop_all(receiver)
				_dbg("stop_all on " + str(receiver))
			_:
				push_warning("GFFDispatch: unknown action '", act, "'")
				return

func _play_on(gff: Node, receiver: Node, params: GFFParams) -> void:
	var eff_name := String(params.get_string("effect_name", effect_name))
	var cmb_name := String(params.get_string("combo_name", combo_name))
	var inner_p := GFFParams.create(params.intensity, params.duration)
	var wait := params.get_bool("await_play", await_play)

	if wait:
		await _play_inner(gff, receiver, eff_name, cmb_name, inner_p)
	else:
		var task := func() -> void:
			await _play_inner(gff, receiver, eff_name, cmb_name, inner_p)
		task.call_deferred()
	_dbg("play " + eff_name + cmb_name + " on " + str(receiver))

func _play_inner(gff: Node, receiver: Node, eff_name: String, cmb_name: String, inner_p: GFFParams) -> void:
	if not eff_name.is_empty():
		await gff.play(eff_name, receiver, inner_p)
	elif not cmb_name.is_empty():
		await gff.play_combo(cmb_name, receiver, inner_p)
	elif inner_effect:
		await gff.play(inner_effect.duplicate(true), receiver, inner_p)
	elif inner_combo:
		await gff.play_combo(inner_combo.duplicate(true), receiver, inner_p)
	else:
		push_warning("GFFDispatch: no effect/combo payload resolved")

func _gff(node: Node) -> Node:
	var tree := node.get_tree() if node and is_instance_valid(node) else Engine.get_main_loop()
	if tree is SceneTree and tree.root:
		return tree.root.get_node_or_null("GameFeelFlow")
	return null

func _get_default_duration() -> float:
	return 0.0

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFDispatch] ", message)
