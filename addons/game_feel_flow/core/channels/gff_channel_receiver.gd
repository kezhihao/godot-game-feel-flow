@icon("res://addons/game_feel_flow/icons/icon_channel_receiver.svg")
class_name GFFChannelReceiver
extends Node

## Game Feel Flow Channel Receiver
##
## Listens on a channel and reacts to broadcast events — the Godot counterpart
## of Feel's channel-listening components (MMShaker / MMF players listening on
## an MMChannel). Drop under any node; when a GFFChannelBroadcast effect (or a
## direct GameFeelFlow.broadcast_channel call) fires a matching event, this
## receiver plays/stops its configured effect on the target.

enum ChannelMode { INT, ASSET, NAME, ANY }
enum Action { PLAY_EFFECT, PLAY_COMBO, STOP_TARGET }

@export_group("Listen")
@export var channel_mode: ChannelMode = ChannelMode.INT
@export var channel: int = 0
## Typed as Resource (not GFFChannel) so headless runs don't need the editor
## class cache — assign a GFFChannel .tres here.
@export var channel_asset: Resource = null
@export var channel_name: StringName = &""
@export var event_name: StringName = &""

@export_group("React")
@export var action: Action = Action.PLAY_EFFECT
## Effect or combo name registered in GameFeelFlow (e.g. "spring_scale").
@export var effect_name: String = ""
## Node the reaction applies to. Defaults to the parent node.
@export var target_path: NodePath = NodePath("..")
@export var debug_enabled: bool = false

var _subscribed := false

func _ready() -> void:
	if event_name.is_empty():
		push_warning("[GFFChannelReceiver] event_name is empty on " + str(get_path()))
		return
	var ch := _resolve_channel()
	GameFeelFlow.listen_channel(ch, event_name, _on_channel_event)
	_subscribed = true
	_dbg("listening event=" + str(event_name) + " channel=" + str(ch))

func _exit_tree() -> void:
	if _subscribed and is_instance_valid(GameFeelFlow):
		GameFeelFlow.unlisten_channel(_resolve_channel(), event_name, _on_channel_event)
		_subscribed = false

func _on_channel_event(payload: Dictionary) -> void:
	var target: Node = get_node_or_null(target_path)
	if target == null:
		target = get_parent()
	_dbg("event=" + str(event_name) + " action=" + str(action) + " target=" + str(target))
	match action:
		Action.PLAY_EFFECT:
			if effect_name.is_empty() or target == null:
				return
			GameFeelFlow.play(effect_name, target, payload)
		Action.PLAY_COMBO:
			if effect_name.is_empty() or target == null:
				return
			GameFeelFlow.play_combo(effect_name, target, payload)
		Action.STOP_TARGET:
			if target != null:
				GameFeelFlow.stop_all(target)

func _resolve_channel() -> Variant:
	match channel_mode:
		ChannelMode.INT:
			return channel
		ChannelMode.ASSET:
			return channel_asset
		ChannelMode.NAME:
			return channel_name
		ChannelMode.ANY:
			return null  # wildcard: every channel matches
	return channel

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFChannelReceiver] ", message)
