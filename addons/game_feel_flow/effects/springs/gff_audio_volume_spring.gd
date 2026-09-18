@tool
@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFAudioVolumeSpring
extends GFFSpringEffect

## Springs an AudioStreamPlayer's volume_db by a punch amount (Feel: MMF_AudioSourceVolumeSpring).

const GFFPropertyTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_property_target.gd")

@export var bump_amount: float = 12.0

func _init() -> void:
	label = "Audio Volume Spring"
	duration = 0.6

func _build_target() -> GFFTarget:
	var t := GFFPropertyTargetScript.new()
	t.property_path = "volume_db"
	t.mode = GFFPropertyTargetScript.Mode.BY_AMOUNT
	t.target_float = bump_amount
	return t
