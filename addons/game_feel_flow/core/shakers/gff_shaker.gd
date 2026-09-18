@icon("res://addons/game_feel_flow/icons/icon_shaker.svg")
class_name GFFShaker
extends Node

## Game Feel Flow Shaker
##
## Persistent shake component — the Godot counterpart of Feel's MMShaker
## family (MMPositionShaker / MMRotationShaker / MMScaleShaker). Attach under a
## node, pick a property, then trigger via shake() or a channel event.
##
## Unlike one-shot shake *effects*, a Shaker is a receiver: it sits on the
## node, listens on a channel, and any emitter can make it shake without
## knowing the target exists. Stack multiple shakers for combined
## position+rotation shakes (e.g. camera feel).

enum ShakeProperty { POSITION, ROTATION, SCALE }
enum ChannelMode { INT, ASSET, NAME, ANY, NONE }

@export_group("Target")
## Node whose property is shaken. Defaults to the parent.
@export var target_path: NodePath = NodePath("..")
@export var shake_property: ShakeProperty = ShakeProperty.POSITION

@export_group("Shake")
## Offset magnitude. Units: POSITION=world units, ROTATION=degrees, SCALE=scale units.
@export var amplitude: Vector3 = Vector3(0.3, 0.3, 0.0)
## Seconds to shake. Ignored while permanent_shake is on.
@export var shake_duration: float = 0.5
## Amplitude fade-out over the shake (1 -> full strength throughout).
@export var attenuation: Curve = null
## Shake forever until stop_shaking() is called.
@export var permanent_shake: bool = false
## Allow a new shake to restart while already shaking.
@export var interruptible: bool = true
## Minimum seconds between two shake starts.
@export var cooldown: float = 0.0
## Start shaking as soon as the node is ready.
@export var play_on_ready: bool = false

@export_group("Noise")
## How many new noise targets per second (Feel's shake frequency). Lower =
## lazier drift, higher = harsher jitter.
@export var shake_frequency: float = 20.0
## Smooth = glide between noise targets (Feel's default motion); off =
## per-frame white jitter for a harsh electrical feel.
@export var smooth_noise: bool = true
## If non-zero, all offsets are constrained along this direction
## (Feel's directional shake) with amplitude's magnitude as reach.
@export var shake_direction: Vector3 = Vector3.ZERO

@export_group("Listen")
## Channel event that triggers a shake. NONE = only manual shake() calls.
@export var channel_mode: ChannelMode = ChannelMode.NONE
@export var channel: int = 0
@export var channel_asset: Resource = null
@export var channel_name: StringName = &""
@export var event_name: StringName = &"shake"
## Payload keys honoured from events: duration, amplitude_mult, intensity.
## When false, event parameters are ignored and only this shaker's own
## inspector values are used (Feel's OnlyUseShakerValues).
@export var use_event_values: bool = true

@export var debug_enabled: bool = false

var shaking: bool = false

var _elapsed: float = 0.0
var _current_duration: float = 0.0
var _current_amplitude: Vector3 = Vector3.ZERO
var _current_frequency: float = 0.0
var _base_value: Variant = null
var _last_shake_time: float = -1e20
var _target: Node = null
var _noise_from: Vector3 = Vector3.ZERO
var _noise_to: Vector3 = Vector3.ZERO
var _noise_t: float = 0.0

func _ready() -> void:
	_target = get_node_or_null(target_path)
	if _target == null:
		_target = get_parent()
	set_process(false)
	if channel_mode != ChannelMode.NONE and not event_name.is_empty():
		GameFeelFlow.listen_channel(_resolve_channel(), event_name, _on_channel_event)
		_dbg("listening event=" + str(event_name) + " channel=" + str(_resolve_channel()))
	if play_on_ready:
		shake()

func _exit_tree() -> void:
	if channel_mode != ChannelMode.NONE and not event_name.is_empty() and is_instance_valid(GameFeelFlow):
		GameFeelFlow.unlisten_channel(_resolve_channel(), event_name, _on_channel_event)

# ===== Public API =====

func shake(p_duration: float = -1.0, p_amplitude_mult: float = 1.0,
		p_frequency: float = -1.0) -> void:
	## Start shaking. duration<0 uses shake_duration; frequency<0 uses
	## shake_frequency; permanent_shake overrides duration.
	if not is_instance_valid(_target):
		push_warning("[GFFShaker] no valid target on " + str(get_path()))
		return
	if shaking and not interruptible:
		_dbg("shake ignored: not interruptible")
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_shake_time < cooldown:
		_dbg("shake ignored: in cooldown")
		return
	_last_shake_time = now

	_elapsed = 0.0
	_current_duration = maxf(p_duration, 0.0) if p_duration >= 0.0 else shake_duration
	_current_amplitude = amplitude * p_amplitude_mult
	_current_frequency = p_frequency if p_frequency > 0.0 else shake_frequency
	_base_value = _read_property(_target)
	# Start mid-segment with a zero origin so stacked shakers don't sync up.
	_noise_from = Vector3.ZERO
	_noise_to = _new_random_offset()
	_noise_t = randf()
	shaking = true
	set_process(true)
	_dbg("shake start duration=" + str(_current_duration) + " amp=" + str(_current_amplitude)
		+ " freq=" + str(_current_frequency) + " dir=" + str(shake_direction))

func stop_shaking() -> void:
	## Stop now and restore the base value.
	if not shaking:
		return
	shaking = false
	set_process(false)
	_restore()
	_dbg("shake stopped")

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		stop_shaking()
		return
	_elapsed += delta

	var env := 1.0
	if not permanent_shake:
		if _elapsed >= _current_duration:
			stop_shaking()
			return
		env = 1.0 - (_elapsed / _current_duration)
		if attenuation:
			env = clampf(attenuation.sample(_elapsed / _current_duration), 0.0, 1.0)

	_apply_offset(_offset(delta) * env)

# ===== Channel =====

func _on_channel_event(payload: Dictionary) -> void:
	var dur := -1.0
	var mult := 1.0
	var freq := -1.0
	if use_event_values:
		dur = float(payload.get("duration", -1.0))
		mult = float(payload.get("amplitude_mult", payload.get("intensity", 1.0)))
		freq = float(payload.get("frequency", -1.0))
	_dbg("event=" + str(event_name) + " dur=" + str(dur) + " mult=" + str(mult) + " freq=" + str(freq))
	shake(dur, mult, freq)

func _resolve_channel() -> Variant:
	match channel_mode:
		ChannelMode.INT:
			return channel
		ChannelMode.ASSET:
			return channel_asset
		ChannelMode.NAME:
			return channel_name
		ChannelMode.ANY:
			return null
	return channel

# ===== Internals =====

func _offset(delta: float) -> Vector3:
	## White jitter mode: a fresh random offset every frame.
	if not smooth_noise:
		return _new_random_offset()
	# Smooth mode: pick a new target every 1/frequency seconds and glide
	# between targets with smoothstep interpolation (Feel's noise feel).
	_noise_t += delta * _current_frequency
	while _noise_t >= 1.0:
		_noise_t -= 1.0
		_noise_from = _noise_to
		_noise_to = _new_random_offset()
	var t := _noise_t * _noise_t * (3.0 - 2.0 * _noise_t)
	return _noise_from.lerp(_noise_to, t)

func _new_random_offset() -> Vector3:
	if shake_direction.length_squared() > 0.0001:
		return shake_direction.normalized() * randf_range(-1.0, 1.0) * _current_amplitude.length()
	return Vector3(
		randf_range(-1.0, 1.0) * _current_amplitude.x,
		randf_range(-1.0, 1.0) * _current_amplitude.y,
		randf_range(-1.0, 1.0) * _current_amplitude.z
	)

func _read_property(node: Node) -> Variant:
	match shake_property:
		ShakeProperty.POSITION:
			return node.position
		ShakeProperty.ROTATION:
			return node.rotation  # Vector3 euler on Node3D, float on Node2D/Control
		ShakeProperty.SCALE:
			return node.scale
	return null

func _apply_offset(offset: Vector3) -> void:
	match shake_property:
		ShakeProperty.POSITION:
			if _target is Node3D:
				_target.position = _base_value + offset
			elif _target is Node2D or _target is Control:
				_target.position = _base_value + Vector2(offset.x, offset.y)
		ShakeProperty.ROTATION:
			var rad := offset * (PI / 180.0)
			if _target is Node3D:
				_target.rotation = _base_value + rad
			elif _target is Node2D or _target is Control:
				_target.rotation = _base_value + rad.y
		ShakeProperty.SCALE:
			if _target is Node3D:
				_target.scale = _base_value + offset
			elif _target is Node2D or _target is Control:
				_target.scale = Vector2(_base_value.x + offset.x, _base_value.y + offset.y)

func _restore() -> void:
	if not is_instance_valid(_target):
		return
	match shake_property:
		ShakeProperty.POSITION:
			_target.position = _base_value
		ShakeProperty.ROTATION:
			if _target is Node3D:
				_target.rotation = _base_value
			else:
				_target.rotation = _base_value
		ShakeProperty.SCALE:
			_target.scale = _base_value

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFShaker] ", message)
