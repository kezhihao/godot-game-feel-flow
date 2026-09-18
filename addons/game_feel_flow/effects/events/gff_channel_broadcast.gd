@tool
class_name GFFChannelBroadcast
extends GFFEffect

## Game Feel Flow Channel Broadcast Effect
##
## Plays by broadcasting `event_name` (with `payload`) on a channel — the Godot
## counterpart of Feel's MMF_PlayerEvent / channel-targeted feedback events.
## Remote GFFChannelReceiver nodes subscribed to the same channel pick the
## event up and play their own effects, decoupling the emitter from its
## audience.

# ===== Channel =====
enum ChannelMode { INT, ASSET, NAME }

@export_group("Channel")
@export var channel_mode: ChannelMode = ChannelMode.INT
@export var channel: int = 0
## Typed as Resource (not GFFChannel) so headless runs don't need the editor
## class cache — assign a GFFChannel .tres here.
@export var channel_asset: Resource = null
@export var channel_name: StringName = &""

# ===== Event =====
@export_group("Event")
@export var event_name: StringName = &""
@export var payload: Dictionary = {}

func _init() -> void:
	requires_target = false
	restore_after_play = false

# ===== Override Methods =====

func _execute(node: Node, params: GFFParams) -> void:
	var ch: Variant = _resolve_channel(params)
	var ev := StringName(params.get_string("event_name", String(event_name)))
	if String(ev).is_empty():
		push_warning("GFFChannelBroadcast: event_name is empty")
		return

	var data := payload.duplicate()
	var override_data = params.get_variant("payload", {})
	if override_data is Dictionary:
		for key in override_data:
			data[key] = override_data[key]
	if node:
		data["emitter"] = node
	# Forward intensity/duration so receivers can scale with the emitter.
	data["intensity"] = params.get_float("intensity", 1.0)

	var delivered := GameFeelFlow.broadcast_channel(ch, ev, data)
	if delivered == 0:
		push_warning("GFFChannelBroadcast: no listeners for event '", ev, "' on channel ", ch)

func _resolve_channel(params: GFFParams) -> Variant:
	var ch = params.get_variant("channel", null)
	if ch != null:
		return ch
	match channel_mode:
		ChannelMode.INT:
			return channel
		ChannelMode.ASSET:
			return channel_asset
		ChannelMode.NAME:
			return channel_name
	return channel

func _get_default_intensity() -> float:
	return 1.0

func _get_default_duration() -> float:
	return 0.0
