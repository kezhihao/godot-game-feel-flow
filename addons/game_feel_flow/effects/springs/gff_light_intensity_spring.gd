@tool
@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFLightIntensitySpring
extends GFFSpringEffect

## Springs a Light3D's light_energy by a punch amount (Feel: MMF_LightIntensitySpring).

const GFFPropertyTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_property_target.gd")

@export var bump_amount: float = 1.5

func _init() -> void:
	label = "Light Intensity Spring"
	duration = 0.6

func _build_target() -> GFFTarget:
	var t := GFFPropertyTargetScript.new()
	t.property_path = "light_energy"
	t.mode = GFFPropertyTargetScript.Mode.BY_AMOUNT
	t.target_float = bump_amount
	return t
