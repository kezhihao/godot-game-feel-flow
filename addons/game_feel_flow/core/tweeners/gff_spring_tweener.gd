@tool
class_name GFFSpringTweener
extends GFFTweener

## Game Feel Flow Spring Tweener
##
## Drives any numeric Target with damped-spring physics instead of an easing
## curve. Combines with existing targets to produce spring effects
## (position / scale / rotation / camera / ...).

# Preload rather than class_name references: headless runs have no editor
# class cache, so uncached class_name identifiers fail at parse time.
const GFFSpringScript := preload("res://addons/game_feel_flow/core/springs/gff_spring.gd")

enum SpringMode {
	MOVE_TO,  ## Spring the value from current state toward the target value and hold.
	PUNCH,    ## Bump velocity toward (to - from), spring relaxes back to base value.
}

@export var spring_mode: SpringMode = SpringMode.PUNCH
## How fast the spring stops oscillating. Lower = bouncier, closer to 1 = settles fast.
@export var damping: float = 0.4
## Oscillation speed in Hz. Higher = snappier, more oscillations per second.
@export var frequency: float = 6.0
## How far PUNCH overshoots, as a fraction of the (to - from) delta.
## 1.0 ≈ reach the target delta, >1.0 = visible overshoot past it.
@export var punch_strength: float = 1.0
## Stop early once both velocity and distance-to-target fall below this.
@export var settle_epsilon: float = 0.001
## When true the tween ends as soon as the spring settles instead of running the full duration.
@export var settle_exit: bool = true
## When true the final value is snapped exactly to the logical end value.
@export var end_at_target: bool = true

var debug_enabled: bool = false

var _spring = null  # GFFSpring instance
var _base_punch_strength: float = -1.0

func get_tweener_name() -> String:
	return "Spring"

func get_supported_value_types() -> Array[GFFValueType.Value]:
	return [
		GFFValueType.Value.FLOAT,
		GFFValueType.Value.VECTOR2,
		GFFValueType.Value.VECTOR3,
		GFFValueType.Value.COLOR,
	]

func can_handle(target: GFFTarget) -> bool:
	if spring_mode == SpringMode.PUNCH and target.get_value_type() == GFFValueType.Value.COLOR:
		# PUNCH needs a signed delta; color punch is ill-defined — fall back to MOVE_TO semantics.
		return false
	return get_supported_value_types().has(target.get_value_type())

func apply_params(params: GFFParams) -> void:
	if _base_punch_strength < 0.0:
		_base_punch_strength = punch_strength
	var intensity := params.get_float("intensity", 1.0)
	damping = params.get_float("damping", damping)
	frequency = params.get_float("frequency", frequency)
	punch_strength = params.get_float("punch_strength", _base_punch_strength) * intensity

func tween_node(node: Node, target: GFFTarget, from: Variant, to: Variant, duration: float, curve: Curve = null) -> void:
	_is_stopped = false
	_spring = GFFSpringScript.create(from, damping, frequency)
	_spring.debug_enabled = debug_enabled

	match spring_mode:
		SpringMode.MOVE_TO:
			_spring.move_to(to)
		SpringMode.PUNCH:
			# A velocity kick of delta * omega displaces the spring by roughly delta.
			_spring.bump(_delta(to, from) * punch_strength * frequency * TAU)

	if debug_enabled:
		print("[GFFSpringTweener] start mode=", spring_mode, " from=", from, " to=", to, " duration=", duration)

	var elapsed := 0.0
	while elapsed < duration and not _is_stopped:
		if not is_instance_valid(node):
			return
		target.apply_value(node, _spring.current_value)
		await node.get_tree().process_frame
		if _is_stopped or not is_instance_valid(node):
			return
		var dt := minf(node.get_process_delta_time(), GFFSpringScript.MAX_FRAME_DELTA)
		_spring.update_spring(dt)
		elapsed += dt
		if settle_exit and _spring.is_settled(settle_epsilon):
			if debug_enabled:
				print("[GFFSpringTweener] settled early at t=", elapsed)
			break

	if is_instance_valid(node) and not _is_stopped:
		if end_at_target:
			_spring.finish()
		target.apply_value(node, _spring.current_value)
		if debug_enabled:
			print("[GFFSpringTweener] end value=", _spring.current_value)

func _delta(to: Variant, from: Variant) -> Variant:
	if to is float or to is int:
		return to - from
	elif to is Vector2:
		return to - from
	elif to is Vector3:
		return to - from
	elif to is Color:
		return Color(to.r - from.r, to.g - from.g, to.b - from.b, to.a - from.a)
	return 0.0
