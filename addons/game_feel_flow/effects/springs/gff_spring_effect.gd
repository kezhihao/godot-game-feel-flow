@tool
@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFSpringEffect
extends GFFEffectCommon

## Game Feel Flow Spring Effect (base)
##
## Base class for the dedicated spring feedback family — the Godot
## counterpart of Feel's MMF_*Spring feedbacks. Subclasses supply a Target
## via _build_target(); this base wires a GFFSpringTweener with the exported
## spring knobs. Target/tweener are built lazily on first play so
## Inspector-edited exports are honored.

const GFFSpringTweenerScript := preload("res://addons/game_feel_flow/core/tweeners/gff_spring_tweener.gd")

enum SpringMode { MOVE_TO, PUNCH }

@export_group("Spring")
@export var spring_mode: SpringMode = SpringMode.PUNCH
## How fast the spring stops oscillating. Lower = bouncier.
@export var damping: float = 0.4
## Oscillation speed in Hz. Higher = snappier.
@export var frequency: float = 6.0
## PUNCH overshoot as a fraction of the value delta.
@export var punch_strength: float = 1.0
## End early once the spring settles instead of running the full duration.
@export var settle_exit: bool = true

@export var debug_enabled: bool = false

## The base effect saves restorable state BEFORE _execute runs, so the target
## must exist by then — build it here too, or the save captures nothing and
## MOVE_TO springs would stay at their target value.
func _save_initial_state(node: Node) -> void:
	_ensure_built()
	super._save_initial_state(node)

func _execute(node: Node, params: GFFParams) -> void:
	_ensure_built()
	if is_instance_of(tweener, GFFSpringTweenerScript):
		tweener.set("debug_enabled", debug_enabled)
	if debug_enabled:
		print("[", get_script().get_global_name() if get_script() else "GFFSpringEffect",
			"] target=", target.get_target_name() if target else "null",
			" mode=", spring_mode, " damp=", damping, " freq=", frequency)
	await super._execute(node, params)

func _ensure_built() -> void:
	if target == null:
		target = _build_target()
	if tweener == null:
		tweener = _build_tweener()

## Override in subclasses: the Target resource this spring drives.
func _build_target() -> GFFTarget:
	return null

func _build_tweener() -> GFFTweener:
	var tw := GFFSpringTweenerScript.new()
	tw.spring_mode = (GFFSpringTweenerScript.SpringMode.MOVE_TO
		if spring_mode == SpringMode.MOVE_TO
		else GFFSpringTweenerScript.SpringMode.PUNCH)
	tw.damping = damping
	tw.frequency = frequency
	tw.punch_strength = punch_strength
	tw.settle_exit = settle_exit
	return tw
