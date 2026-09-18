@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFSpringComponent
extends Node

## Game Feel Flow Spring Component
##
## Persistent spring-driven property component — the Godot counterpart of
## Feel's MMSpringPosition / MMSpringRotation / MMSpringScale components.
## Attach under a node; the spring drives the chosen property every frame.
##
## Difference from the spring *effect* (GFFSpringTweener): an effect plays
## once and restores; a component OWNS the property — move_to() makes the
## value spring over and HOLD there until told otherwise. bump() kicks the
## velocity so it oscillates back to the current target.
##
## Supports the same channel listening as GFFShaker — emitters broadcast a
## spring event on a channel and every listening component reacts without
## knowing the targets.

enum SpringProperty { POSITION, ROTATION, SCALE }
enum ChannelMode { INT, ASSET, NAME, ANY, NONE }

const GFFSpringScript := preload("res://addons/game_feel_flow/core/springs/gff_spring.gd")

@export_group("Target")
## Node whose property is driven. Defaults to the parent.
@export var target_path: NodePath = NodePath("..")
@export var spring_property: SpringProperty = SpringProperty.POSITION

@export_group("Spring")
## How fast the spring stops oscillating. Lower = bouncier.
@export var damping: float = 0.4
## Oscillation speed in Hz.
@export var frequency: float = 6.0
## When true the spring stops updating once settled (saves a property write
## per frame). Channel events and API calls always wake it back up.
@export var sleep_when_settled: bool = true

@export_group("Listen")
## Channel event driving the spring. Payload keys:
##   action: "move_to" | "move_to_instant" | "move_to_additive" | "bump" |
##           "stop" | "finish" | "restore"
##   value:  target/delta/velocity (Vector3 for position/scale, radians for rotation)
@export var channel_mode: ChannelMode = ChannelMode.NONE
@export var channel: int = 0
@export var channel_asset: Resource = null
@export var channel_name: StringName = &""
@export var event_name: StringName = &"spring"

@export var debug_enabled: bool = false

var spring = null  # GFFSpring

var _target: Node = null

func _ready() -> void:
	_target = get_node_or_null(target_path)
	if _target == null:
		_target = get_parent()
	if not is_instance_valid(_target):
		push_warning("[GFFSpringComponent] no valid target on " + str(get_path()))
		return
	spring = GFFSpringScript.create(_read_property(), damping, frequency)
	if channel_mode != ChannelMode.NONE and not event_name.is_empty():
		GameFeelFlow.listen_channel(_resolve_channel(), event_name, _on_channel_event)
		_dbg("listening event=" + str(event_name) + " channel=" + str(_resolve_channel()))

func _exit_tree() -> void:
	if channel_mode != ChannelMode.NONE and not event_name.is_empty() and is_instance_valid(GameFeelFlow):
		GameFeelFlow.unlisten_channel(_resolve_channel(), event_name, _on_channel_event)

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		set_process(false)
		return
	if sleep_when_settled and spring.is_settled():
		return
	spring.update_spring(minf(delta, GFFSpringScript.MAX_FRAME_DELTA))
	_write_property(spring.current_value)

# ===== Spring API (Feel parity) =====

func move_to(value: Variant) -> void:
	spring.move_to(_coerce(value))
	_wake()

func move_to_instant(value: Variant) -> void:
	spring.move_to_instant(_coerce(value))
	_apply_now()

func move_to_additive(value: Variant) -> void:
	spring.move_to_additive(_coerce(value))
	_wake()

func move_to_subtractive(value: Variant) -> void:
	spring.move_to_subtractive(_coerce(value))
	_wake()

func bump(amount: Variant) -> void:
	spring.bump(_coerce(amount))
	_wake()

func stop() -> void:
	spring.stop()
	_apply_now()

func finish() -> void:
	spring.finish()
	_apply_now()

func restore_initial_value() -> void:
	spring.restore_initial_value()
	_apply_now()

func set_current_as_initial() -> void:
	spring.set_current_as_initial()

# ===== Channel =====

func _on_channel_event(payload: Dictionary) -> void:
	var action := String(payload.get("action", "bump"))
	var value: Variant = payload.get("value", null)
	_dbg("event action=" + action + " value=" + str(value))
	match action:
		"move_to":
			if value != null: move_to(value)
		"move_to_instant":
			if value != null: move_to_instant(value)
		"move_to_additive":
			if value != null: move_to_additive(value)
		"move_to_subtractive":
			if value != null: move_to_subtractive(value)
		"bump":
			if value != null: bump(value)
		"stop":
			stop()
		"finish":
			finish()
		"restore":
			restore_initial_value()
		_:
			push_warning("[GFFSpringComponent] unknown action: " + action)

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

func _wake() -> void:
	set_process(true)

func _apply_now() -> void:
	_write_property(spring.current_value)
	_wake()

func _read_property() -> Variant:
	match spring_property:
		SpringProperty.POSITION:
			return _target.position
		SpringProperty.ROTATION:
			return _target.rotation  # Vector3 euler on Node3D, float on Node2D
		SpringProperty.SCALE:
			return _target.scale
	return Vector3.ZERO

func _write_property(value: Variant) -> void:
	match spring_property:
		SpringProperty.POSITION:
			if _target is Node3D:
				_target.position = value
			elif _target is Node2D or _target is Control:
				_target.position = Vector2(value.x, value.y)
		SpringProperty.ROTATION:
			if _target is Node3D:
				_target.rotation = value
			elif _target is Node2D or _target is Control:
				_target.rotation = value.y if value is Vector3 else value
		SpringProperty.SCALE:
			if _target is Node3D:
				_target.scale = value
			elif _target is Node2D or _target is Control:
				_target.scale = Vector2(value.x, value.y)

func _coerce(value: Variant) -> Variant:
	## Channel payloads may arrive with the wrong numeric shape — coerce to the
	## property's value type so spring math never sees a type mismatch.
	var current: Variant = spring.current_value
	if current is Vector3:
		if value is Vector2:
			return Vector3(value.x, value.y, 0.0)
		if value is float or value is int:
			return Vector3(value, value, value)
	elif current is Vector2:
		if value is Vector3:
			return Vector2(value.x, value.y)
		if value is float or value is int:
			return Vector2(value, value)
	elif current is float:
		if value is Vector3:
			return value.y
		if value is Vector2:
			return value.x
	return value

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFSpringComponent] ", message)
