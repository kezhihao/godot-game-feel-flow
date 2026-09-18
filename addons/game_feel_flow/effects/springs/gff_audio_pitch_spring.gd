@tool
@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFAudioPitchSpring
extends GFFSpringEffect

## Springs an AudioStreamPlayer's pitch_scale by a punch amount (Feel: MMF_AudioSourcePitchSpring).

const GFFPropertyTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_property_target.gd")

@export var bump_amount: float = 0.5

func _init() -> void:
	label = "Audio Pitch Spring"
	duration = 0.6

func _build_target() -> GFFTarget:
	var t := GFFPropertyTargetScript.new()
	t.property_path = "pitch_scale"
	t.mode = GFFPropertyTargetScript.Mode.BY_AMOUNT
	t.target_float = bump_amount
	return t
