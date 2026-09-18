@tool
class_name GFFFlicker
extends GFFEffect

## Game Feel Flow Flicker
##
## Rapid on/off modulation — counterpart of Feel's MMF_Flicker feedback.
## COLOR flips albedo between base and flicker_color, EMISSION pulses
## emission_energy_multiplier, VISIBILITY toggles node.visible. Rate is in Hz;
## decay fades the flicker out over the duration.

const MaterialUtil = preload("res://addons/game_feel_flow/core/utils/gff_material_util.gd")

enum FlickerMode { COLOR, EMISSION, VISIBILITY }

@export_group("Flicker")
@export var flicker_mode: FlickerMode = FlickerMode.COLOR
@export var flicker_color: Color = Color.WHITE
## Emission energy while "on" in EMISSION mode.
@export var emission_energy: float = 4.0
## Flashes per second.
@export var rate_hz: float = 18.0
## Fade the on-phase weight to zero by the end of the effect.
@export var decay: bool = true
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	var final_duration := params.get_float("duration", duration)
	var rate := params.get_float("rate", rate_hz)
	var mode_i := params.get_int("flicker_mode", flicker_mode)
	if rate <= 0.0:
		push_warning("GFFFlicker: rate_hz must be > 0")
		return

	var mi := node as MeshInstance3D
	var info: Dictionary = {}
	var mat: Material = null
	var base_albedo := Color.BLACK
	var base_emission_on := false
	var base_emission_energy := 1.0

	if mode_i != FlickerMode.VISIBILITY:
		if mi == null:
			push_warning("GFFFlicker: COLOR/EMISSION need a MeshInstance3D target")
			return
		info = MaterialUtil.acquire(node, 0, true)
		mat = info["material"]
		if mat is StandardMaterial3D:
			base_albedo = mat.albedo_color
			base_emission_on = mat.emission_enabled
			base_emission_energy = mat.emission_energy_multiplier
			if mode_i == FlickerMode.EMISSION:
				mat.emission_enabled = true
		else:
			push_warning("GFFFlicker: material is not StandardMaterial3D")
			MaterialUtil.release(node, info)
			return

	_dbg("mode=" + str(mode_i) + " rate=" + str(rate) + " dur=" + str(final_duration))

	var elapsed := 0.0
	while elapsed < final_duration and _is_playing:
		if not is_instance_valid(node):
			return
		var t := clampf(elapsed / final_duration, 0.0, 1.0)
		var env := (1.0 - t) if decay else 1.0
		var on := sin(TAU * rate * elapsed) > 0.0
		var k := (1.0 if on else 0.0) * env
		match mode_i:
			FlickerMode.COLOR:
				mat.albedo_color = base_albedo.lerp(flicker_color, k)
			FlickerMode.EMISSION:
				mat.emission_energy_multiplier = lerpf(base_emission_energy, emission_energy, k)
			FlickerMode.VISIBILITY:
				node.visible = on or k < 0.5
		await node.get_tree().process_frame
		if not is_instance_valid(node) or not _is_playing:
			return
		elapsed += node.get_process_delta_time()

	if is_instance_valid(node):
		match mode_i:
			FlickerMode.COLOR:
				mat.albedo_color = base_albedo
			FlickerMode.EMISSION:
				mat.emission_enabled = base_emission_on
				mat.emission_energy_multiplier = base_emission_energy
			FlickerMode.VISIBILITY:
				node.visible = true
		if mode_i != FlickerMode.VISIBILITY:
			MaterialUtil.release(node, info)

func _get_default_duration() -> float:
	return 0.5

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFFlicker] ", message)
