class_name GFFSpring
extends RefCounted

## Game Feel Flow Spring
##
## Damped harmonic oscillator for float / Vector2 / Vector3 / Vector4 / Color.
## Feel-style spring model: `damping` controls decay, `frequency` (Hz) controls
## oscillation speed. Disturb via bump()/move_to() then call update_spring()
## every frame.

const STEP := 1.0 / 60.0
## A single frame may never advance the spring by more than this. Without a cap,
## a hitching frame (startup stall, shader compile) would fast-forward the whole
## oscillation inside one call and the visible punch would be skipped entirely.
const MAX_FRAME_DELTA := 1.0 / 20.0
const SETTLE_EPSILON := 0.001

# ===== Spring Model =====
var damping: float = 0.4
var frequency: float = 6.0

var current_value: Variant = 0.0
var target_value: Variant = 0.0
var velocity: Variant = null  # lazily initialized to zero of the value type
var initial_value: Variant = null

# ===== Clamp =====
var clamp_min_enabled: bool = false
var clamp_max_enabled: bool = false
var clamp_min_value: Variant = 0.0
var clamp_max_value: Variant = 0.0
## When true the respective bound uses initial_value instead of clamp_*_value.
var clamp_min_uses_initial: bool = false
var clamp_max_uses_initial: bool = false
## When true the value reflects past the bound instead of hard-clamping.
var clamp_min_bounce: bool = false
var clamp_max_bounce: bool = false

# ===== Debug =====
var debug_enabled: bool = false

# ===== Lifecycle =====

static func create(value: Variant, p_damping: float = 0.4, p_frequency: float = 6.0):
	var spring := new()
	spring.damping = p_damping
	spring.frequency = p_frequency
	spring.current_value = value
	spring.target_value = value
	spring.initial_value = value
	spring.velocity = spring._zero(value)
	return spring

# ===== Update =====

func update_spring(delta_time: float) -> void:
	## Integrate the spring. Sub-stepped at a fixed 1/60s for stability,
	## regardless of the frame delta passed in.
	_ensure_state()
	var accumulator := minf(delta_time, MAX_FRAME_DELTA)
	while accumulator > 0.0:
		var step := minf(accumulator, STEP)
		velocity = _velocity_step(current_value, target_value, velocity, step)
		current_value = _add(current_value, _mul_scalar(velocity, step))
		accumulator -= step
	_handle_clamp()

func is_settled(epsilon: float = SETTLE_EPSILON) -> bool:
	_ensure_state()
	return _abs_sum(_sub(current_value, target_value)) < epsilon and _abs_sum(velocity) < epsilon

# ===== Disturbance API =====

func move_to(new_value: Variant) -> void:
	_ensure_state()
	target_value = _apply_target_clamp(new_value)
	_dbg("move_to -> " + str(target_value))

func move_to_instant(new_value: Variant) -> void:
	_ensure_state()
	current_value = new_value
	target_value = _apply_target_clamp(new_value)
	velocity = _zero(current_value)
	_dbg("move_to_instant -> " + str(new_value))

func move_to_additive(delta_value: Variant) -> void:
	move_to(_add(target_value, delta_value))

func move_to_subtractive(delta_value: Variant) -> void:
	move_to(_sub(target_value, delta_value))

func move_to_random(min_value: Variant, max_value: Variant) -> void:
	move_to(_rand_between(min_value, max_value))

func bump(bump_amount: Variant) -> void:
	_ensure_state()
	velocity = _add(velocity, bump_amount)
	_dbg("bump +" + str(bump_amount) + " velocity=" + str(velocity))

func bump_random(min_amount: Variant, max_amount: Variant) -> void:
	bump(_rand_between(min_amount, max_amount))

func stop() -> void:
	## Freeze motion and hold the current value.
	_ensure_state()
	velocity = _zero(current_value)
	target_value = current_value
	_dbg("stop at " + str(current_value))

func finish() -> void:
	## Snap instantly to the target value.
	_ensure_state()
	velocity = _zero(current_value)
	current_value = target_value
	_dbg("finish at " + str(current_value))

# ===== Initial Value =====

func set_initial_value(value: Variant) -> void:
	initial_value = value

func restore_initial_value() -> void:
	_ensure_state()
	current_value = initial_value
	target_value = initial_value
	_dbg("restore_initial_value -> " + str(initial_value))

func set_current_as_initial() -> void:
	_ensure_state()
	initial_value = current_value

# ===== Internals =====

func _ensure_state() -> void:
	if velocity == null:
		velocity = _zero(current_value)
	if initial_value == null:
		initial_value = current_value

func _dbg(message) -> void:
	if not debug_enabled:
		return
	print("[GFFSpring] ", message)

## Semi-implicit Euler step of a damped harmonic oscillator.
func _velocity_step(current: Variant, target: Variant, vel: Variant, step: float) -> Variant:
	var omega := frequency * TAU
	var accel := _sub(
		_mul_scalar(_sub(current, target), -omega * omega),
		_mul_scalar(vel, 2.0 * damping * omega)
	)
	return _add(vel, _mul_scalar(accel, step))

# ===== Clamp =====

func _apply_target_clamp(value: Variant) -> Variant:
	var result: Variant = value
	if clamp_min_enabled and not clamp_min_uses_initial:
		result = _component_max(result, clamp_min_value)
	if clamp_max_enabled and not clamp_max_uses_initial:
		result = _component_min(result, clamp_max_value)
	return result

func _handle_clamp() -> void:
	if not clamp_min_enabled and not clamp_max_enabled:
		return
	_ensure_state()
	if clamp_min_enabled:
		var bound: Variant = initial_value if clamp_min_uses_initial else clamp_min_value
		if _any_less(current_value, bound):
			if clamp_min_bounce:
				current_value = _add(_component_abs(_sub(current_value, bound)), bound)
			else:
				current_value = _component_max(current_value, bound)
	if clamp_max_enabled:
		var bound: Variant = initial_value if clamp_max_uses_initial else clamp_max_value
		if _any_greater(current_value, bound):
			if clamp_max_bounce:
				current_value = _sub(bound, _component_abs(_sub(current_value, bound)))
			else:
				current_value = _component_min(current_value, bound)

# ===== Per-type math =====

func _zero(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT, TYPE_INT:
			return 0.0
		TYPE_VECTOR2:
			return Vector2.ZERO
		TYPE_VECTOR3:
			return Vector3.ZERO
		TYPE_VECTOR4:
			return Vector4.ZERO
		TYPE_COLOR:
			return Color(0, 0, 0, 0)
	push_error("[GFFSpring] Unsupported value type: ", typeof(v))
	return 0.0

func _add(a: Variant, b: Variant) -> Variant:
	if a is Color and b is Color:
		return Color(a.r + b.r, a.g + b.g, a.b + b.b, a.a + b.a)
	return a + b

func _sub(a: Variant, b: Variant) -> Variant:
	if a is Color and b is Color:
		return Color(a.r - b.r, a.g - b.g, a.b - b.b, a.a - b.a)
	return a - b

func _mul_scalar(v: Variant, s: float) -> Variant:
	if v is Color:
		return Color(v.r * s, v.g * s, v.b * s, v.a * s)
	return v * s

func _abs_sum(v: Variant) -> float:
	match typeof(v):
		TYPE_FLOAT, TYPE_INT:
			return absf(v)
		TYPE_VECTOR2:
			return absf(v.x) + absf(v.y)
		TYPE_VECTOR3:
			return absf(v.x) + absf(v.y) + absf(v.z)
		TYPE_VECTOR4:
			return absf(v.x) + absf(v.y) + absf(v.z) + absf(v.w)
		TYPE_COLOR:
			return absf(v.r) + absf(v.g) + absf(v.b) + absf(v.a)
	return 0.0

func _component_max(a: Variant, b: Variant) -> Variant:
	match typeof(a):
		TYPE_FLOAT, TYPE_INT:
			return maxf(a, b)
		TYPE_VECTOR2:
			return Vector2(maxf(a.x, b.x), maxf(a.y, b.y))
		TYPE_VECTOR3:
			return Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
		TYPE_VECTOR4:
			return Vector4(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z), maxf(a.w, b.w))
		TYPE_COLOR:
			return Color(maxf(a.r, b.r), maxf(a.g, b.g), maxf(a.b, b.b), maxf(a.a, b.a))
	return a

func _component_min(a: Variant, b: Variant) -> Variant:
	match typeof(a):
		TYPE_FLOAT, TYPE_INT:
			return minf(a, b)
		TYPE_VECTOR2:
			return Vector2(minf(a.x, b.x), minf(a.y, b.y))
		TYPE_VECTOR3:
			return Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
		TYPE_VECTOR4:
			return Vector4(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z), minf(a.w, b.w))
		TYPE_COLOR:
			return Color(minf(a.r, b.r), minf(a.g, b.g), minf(a.b, b.b), minf(a.a, b.a))
	return a

func _component_abs(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT, TYPE_INT:
			return absf(v)
		TYPE_VECTOR2:
			return v.abs()
		TYPE_VECTOR3:
			return v.abs()
		TYPE_VECTOR4:
			return v.abs()
		TYPE_COLOR:
			return Color(absf(v.r), absf(v.g), absf(v.b), absf(v.a))
	return v

func _any_less(a: Variant, b: Variant) -> bool:
	match typeof(a):
		TYPE_FLOAT, TYPE_INT:
			return a < b
		TYPE_VECTOR2:
			return a.x < b.x or a.y < b.y
		TYPE_VECTOR3:
			return a.x < b.x or a.y < b.y or a.z < b.z
		TYPE_VECTOR4:
			return a.x < b.x or a.y < b.y or a.z < b.z or a.w < b.w
		TYPE_COLOR:
			return a.r < b.r or a.g < b.g or a.b < b.b or a.a < b.a
	return false

func _any_greater(a: Variant, b: Variant) -> bool:
	match typeof(a):
		TYPE_FLOAT, TYPE_INT:
			return a > b
		TYPE_VECTOR2:
			return a.x > b.x or a.y > b.y
		TYPE_VECTOR3:
			return a.x > b.x or a.y > b.y or a.z > b.z
		TYPE_VECTOR4:
			return a.x > b.x or a.y > b.y or a.z > b.z or a.w > b.w
		TYPE_COLOR:
			return a.r > b.r or a.g > b.g or a.b > b.b or a.a > b.a
	return false

func _rand_between(min_value: Variant, max_value: Variant) -> Variant:
	match typeof(min_value):
		TYPE_FLOAT, TYPE_INT:
			return randf_range(min_value, max_value)
		TYPE_VECTOR2:
			return Vector2(randf_range(min_value.x, max_value.x), randf_range(min_value.y, max_value.y))
		TYPE_VECTOR3:
			return Vector3(randf_range(min_value.x, max_value.x), randf_range(min_value.y, max_value.y), randf_range(min_value.z, max_value.z))
		TYPE_VECTOR4:
			return Vector4(randf_range(min_value.x, max_value.x), randf_range(min_value.y, max_value.y), randf_range(min_value.z, max_value.z), randf_range(min_value.w, max_value.w))
		TYPE_COLOR:
			return Color(randf_range(min_value.r, max_value.r), randf_range(min_value.g, max_value.g), randf_range(min_value.b, max_value.b), randf_range(min_value.a, max_value.a))
	return min_value
