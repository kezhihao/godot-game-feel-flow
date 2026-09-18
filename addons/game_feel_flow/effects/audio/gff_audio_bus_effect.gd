@tool
class_name GFFAudioBusEffect
extends GFFEffect

## Game Feel Flow Audio Bus Effect
##
## Inserts and tweens an AudioEffect on an AudioServer bus — counterpart of
## Feel's MMF_AudioFilter family (lowpass/highpass/echo/reverb/distortion).
## The effect instance is added for the play, a named parameter is tweened
## (optionally ping-pong), and the effect is removed when the play ends.

enum EffectType { LOWPASS, HIGHPASS, BANDPASS, ECHO, REVERB, DISTORTION, CHORUS, PANNER }

@export_group("Audio Bus Effect")
## Bus to insert the effect on (name or index via params["bus_index"]).
@export var bus_name: String = "FeelBus"
@export var effect_type: EffectType = EffectType.LOWPASS
## Effect parameter to tween ("cutoff_hz", "drive", "room_size", "delay"...).
@export var param_name: StringName = &"cutoff_hz"
@export var to_value: float = 800.0
## Start from this value instead of the parameter's current one.
@export var from_value: float = -1.0
@export var ping_pong: bool = true
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	var bus_idx: int = params.get_int("bus_index", AudioServer.get_bus_index(bus_name))
	if bus_idx < 0:
		push_warning("GFFAudioBusEffect: bus '", bus_name, "' not found")
		return
	var type_i: int = params.get_int("effect_type", effect_type)
	var pname := StringName(params.get_string("param", String(param_name)))
	var to: float = params.get_float("to", to_value)
	var final_duration := params.get_float("duration", duration)
	var do_ping_pong := params.get_bool("ping_pong", ping_pong)

	var fx := _make_effect(type_i)
	if fx == null:
		push_warning("GFFAudioBusEffect: unsupported effect type ", type_i)
		return
	if params.get_float("from", from_value) >= 0.0:
		fx.set(pname, params.get_float("from", from_value))
	AudioServer.add_bus_effect(bus_idx, fx)

	var from: float = fx.get(pname)
	if to < 0.0:
		to = from
	_dbg("bus=" + str(bus_idx) + " fx=" + fx.get_class() + " param=" + String(pname)
		+ " from=" + str(from) + " to=" + str(to))

	var total := final_duration * (2.0 if do_ping_pong else 1.0)
	var elapsed := 0.0
	while elapsed < total and _is_playing:
		var t: float
		if do_ping_pong:
			t = clampf(elapsed / final_duration, 0.0, 1.0)
			if elapsed > final_duration:
				t = 2.0 - t
		else:
			t = clampf(elapsed / final_duration, 0.0, 1.0)
		fx.set(pname, lerpf(from, to, _apply_curve(t, easing_curve)))
		await node.get_tree().process_frame
		if not _is_playing:
			break
		elapsed += node.get_process_delta_time()

	fx.set(pname, from if do_ping_pong else to)
	_remove_effect(bus_idx, fx)

func _remove_effect(bus_idx: int, fx: AudioEffect) -> void:
	for i in AudioServer.get_bus_effect_count(bus_idx):
		if AudioServer.get_bus_effect(bus_idx, i) == fx:
			AudioServer.remove_bus_effect(bus_idx, i)
			return

func _make_effect(type_i: int) -> AudioEffect:
	match type_i:
		EffectType.LOWPASS: return AudioEffectLowPassFilter.new()
		EffectType.HIGHPASS: return AudioEffectHighPassFilter.new()
		EffectType.BANDPASS: return AudioEffectBandPassFilter.new()
		EffectType.ECHO: return AudioEffectDelay.new()
		EffectType.REVERB: return AudioEffectReverb.new()
		EffectType.DISTORTION: return AudioEffectDistortion.new()
		EffectType.CHORUS: return AudioEffectChorus.new()
		EffectType.PANNER: return AudioEffectPanner.new()
	return null

func _get_default_duration() -> float:
	return 0.5

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFAudioBusEffect] ", message)
