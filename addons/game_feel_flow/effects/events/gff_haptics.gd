@tool
class_name GFFHaptics
extends GFFEffect

## Game Feel Flow Haptics
##
## Counterpart of Feel's NiceVibrations feedbacks, mapped to Godot Input:
##   "handheld" -> Input.vibrate_handheld(duration_ms, amplitude)
##   "joy"      -> Input.start_joy_vibration(device, weak, strong, dur)
##   "joy_stop" -> Input.stop_joy_vibration(device)
## No hardware is required — calls are safe no-ops without devices.

@export_group("Haptics")
## One of: handheld, joy, joy_stop.
@export var haptic_mode: StringName = &"handheld"
## Joypad device id for joy modes. -1 = all devices.
@export var device: int = 0
## Weak motor magnitude 0..1.
@export var weak: float = 0.5
## Strong motor magnitude 0..1.
@export var strong: float = 0.8
## Handheld amplitude 0..1 (defaults to `strong` when < 0).
@export var amplitude: float = -1.0
@export var debug_enabled: bool = false

func _init() -> void:
	requires_target = false
	restore_after_play = false

func _execute(node: Node, params: GFFParams) -> void:
	var mode := StringName(params.get_string("haptic_mode", String(haptic_mode)))
	var dev := params.get_int("device", device)
	var dur := params.get_float("duration", duration)
	var w := clampf(params.get_float("weak", weak), 0.0, 1.0)
	var s := clampf(params.get_float("strong", strong), 0.0, 1.0)
	_dbg("mode=" + String(mode) + " dev=" + str(dev) + " dur=" + str(dur))

	match String(mode):
		"handheld":
			var amp := amplitude if amplitude >= 0.0 else s
			Input.vibrate_handheld(int(dur * 1000.0), clampf(amp, 0.0, 1.0))
		"joy":
			Input.start_joy_vibration(dev, w, s, dur)
			if dur > 0.0:
				var tree := node.get_tree() if node else Engine.get_main_loop()
				await tree.create_timer(dur, true, false, true).timeout
				Input.stop_joy_vibration(dev)
		"joy_stop":
			Input.stop_joy_vibration(dev)
		_:
			push_warning("GFFHaptics: unknown haptic_mode '", mode, "'")

func _get_default_duration() -> float:
	return duration if duration > 0.0 else 0.2

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFHaptics] ", message)
