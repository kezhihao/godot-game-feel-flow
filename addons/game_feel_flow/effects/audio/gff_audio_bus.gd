@tool
class_name GFFAudioBus
extends GFFEffect

## Game Feel Flow Audio Bus
##
## Bus-level mixer control — counterpart of Feel's
## MMF_AudioMixerSnapshotTransition. Tweens a bus's volume_db (or flips
## mute/solo) then restores — the "snapshot" is the captured pre-play state,
## optionally applied to ALL buses at once for true snapshot semantics.

enum BusAction { VOLUME, MUTE, SOLO }

@export_group("Audio Bus")
## Target bus name; params["bus_index"] can override.
@export var bus_name: String = "FeelBus"
@export var bus_action: BusAction = BusAction.VOLUME
## For VOLUME: destination volume_db.
@export var to_value: float = -12.0
## For MUTE/SOLO: the state to set during play.
@export var state_on: bool = true
## Apply the same action to every bus (snapshot-style).
@export var all_buses: bool = false
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	var act_i: int = params.get_int("bus_action", bus_action)
	var to: float = params.get_float("to", to_value)
	var on: bool = params.get_bool("state_on", state_on)
	var final_duration := params.get_float("duration", duration)
	var every := params.get_bool("all_buses", all_buses)

	var indices: Array[int] = []
	if every:
		for i in AudioServer.bus_count:
			indices.append(i)
	else:
		var idx: int = params.get_int("bus_index", AudioServer.get_bus_index(bus_name))
		if idx < 0:
			push_warning("GFFAudioBus: bus '", bus_name, "' not found")
			return
		indices.append(idx)

	# Snapshot pre-play state for every touched bus.
	var before: Array = []
	for i in indices:
		before.append({
			"volume": AudioServer.get_bus_volume_db(i),
			"mute": AudioServer.is_bus_mute(i),
			"solo": AudioServer.is_bus_solo(i),
		})
	_dbg("action=" + str(act_i) + " buses=" + str(indices) + " to=" + str(to))

	if act_i != BusAction.VOLUME:
		for k in indices.size():
			if act_i == BusAction.MUTE:
				AudioServer.set_bus_mute(indices[k], on)
			else:
				AudioServer.set_bus_solo(indices[k], on)
		await _wait(node, final_duration)
	else:
		var elapsed := 0.0
		while elapsed < final_duration and _is_playing:
			var t := clampf(elapsed / final_duration, 0.0, 1.0)
			var k := _apply_curve(t, easing_curve)
			for j in indices.size():
				AudioServer.set_bus_volume_db(indices[j], lerpf(before[j]["volume"], to, k))
			await node.get_tree().process_frame
			if not _is_playing:
				break
			elapsed += node.get_process_delta_time()

	# Restore the snapshot.
	for k in indices.size():
		AudioServer.set_bus_volume_db(indices[k], before[k]["volume"])
		AudioServer.set_bus_mute(indices[k], before[k]["mute"])
		AudioServer.set_bus_solo(indices[k], before[k]["solo"])

func _wait(node: Node, secs: float) -> void:
	var elapsed := 0.0
	while elapsed < secs and _is_playing:
		await node.get_tree().process_frame
		if not _is_playing:
			return
		elapsed += node.get_process_delta_time()

func _get_default_duration() -> float:
	return 0.5

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFAudioBus] ", message)
