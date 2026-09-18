@tool
@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFLightColorSpring
extends GFFSpringEffect

## Springs a Light3D's light_color toward a target color (Feel: MMF_LightColorSpring).

const GFFPropertyTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_property_target.gd")

@export var target_color: Color = Color.RED

func _init() -> void:
	label = "Light Color Spring"
	duration = 0.8
	spring_mode = SpringMode.MOVE_TO

func _build_target() -> GFFTarget:
	var t := GFFPropertyTargetScript.new()
	t.property_path = "light_color"
	t.mode = GFFPropertyTargetScript.Mode.TO_TARGET
	t.target_color = target_color
	return t
