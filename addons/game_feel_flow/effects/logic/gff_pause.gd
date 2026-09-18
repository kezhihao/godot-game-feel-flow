@tool
class_name GFFPause
extends GFFEffect

## Game Feel Flow Pause / HoldingPause
##
## Counterpart of Feel's MMF_Pause + MMF_HoldingPause feedbacks — a timing
## spacer that blocks its combo track (or the caller awaiting play()).
## wait_mode selects the pause condition:
##   "time"        -> wait `wait_duration` seconds (MMF_Pause)
##   "hold_action" -> wait while Input.is_action_pressed(hold_action) stays
##                    true; resumes when the action is released
##   "signal"      -> wait until the `signal_channel`/`signal_event` channel
##                    broadcast fires (GameFeelFlow channel bus, GF-02)
## `max_wait` > 0 bounds every mode — the pause always ends (safety timeout).

@export_group("Pause")
## One of: time, hold_action, signal.
@export var wait_mode: StringName = &"time"
## Seconds for wait_mode="time". params["wait_duration"] overrides.
@export var wait_duration: float = 0.5
## InputMap action polled for wait_mode="hold_action". params["hold_action"].
@export var hold_action: StringName = &"ui_accept"
## Channel for wait_mode="signal" (int/StringName/GFFChannel). params["signal_channel"].
@export var signal_channel: Variant = 0
## Event name awaited for wait_mode="signal". params["signal_event"].
@export var signal_event: StringName = &"resume"
## Hard cap in seconds for hold/signal modes. 0 = wait forever.
@export var max_wait: float = 0.0
@export var debug_enabled: bool = false

func _init() -> void:
	# A pause changes nothing on the node — no restore needed.
	restore_after_play = false

func _execute(node: Node, params: GFFParams) -> void:
	var mode := StringName(params.get_string("wait_mode", String(wait_mode)))
	var cap := params.get_float("max_wait", max_wait)
	var elapsed := 0.0
	_dbg("wait_mode=" + String(mode))

	match String(mode):
		"hold_action":
			var action := StringName(params.get_string("hold_action", String(hold_action)))
			if not InputMap.has_action(action):
				push_warning("GFFPause: input action '", action, "' not in InputMap")
				return
			while Input.is_action_pressed(action):
				await node.get_tree().process_frame
				elapsed += node.get_process_delta_time()
				if cap > 0.0 and elapsed >= cap:
					_dbg("hold_action capped at " + str(cap) + "s")
					return
		"signal":
			var gff := _gff(node)
			if gff == null:
				push_warning("GFFPause: GameFeelFlow singleton unavailable")
				return
			var ch: Variant = params.get_variant("signal_channel", signal_channel)
			var ev := StringName(params.get_string("signal_event", String(signal_event)))
			var state := {"fired": false}
			var cb := func(_payload: Dictionary) -> void: state.fired = true
			gff.listen_channel(ch, ev, cb)
			while not state.fired:
				await node.get_tree().process_frame
				elapsed += node.get_process_delta_time()
				if cap > 0.0 and elapsed >= cap:
					break
			gff.unlisten_channel(ch, ev, cb)
		_:
			var secs := params.get_float("wait_duration", wait_duration)
			if secs > 0.0:
				await node.get_tree().create_timer(secs, true, false, true).timeout
	_dbg("released after ~" + str(elapsed) + "s")

func _gff(node: Node) -> Node:
	var tree := node.get_tree() if node and is_instance_valid(node) else Engine.get_main_loop()
	if tree is SceneTree and tree.root:
		return tree.root.get_node_or_null("GameFeelFlow")
	return null

func _get_default_duration() -> float:
	return wait_duration

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFPause] ", message)
