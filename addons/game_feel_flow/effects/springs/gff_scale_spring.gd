@tool
@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFScaleSpring
extends GFFSpringEffect

## Springs a Node's scale by a punch amount (Feel: MMF_ScaleSpring).

const GFFScaleTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_scale_target.gd")

@export var bump_amount: Vector3 = Vector3(0.25, 0.25, 0.25)

func _init() -> void:
	label = "Scale Spring"
	duration = 0.6

func _build_target() -> GFFTarget:
	var t := GFFScaleTargetScript.new()
	t.mode = GFFScaleTargetScript.Mode.BY_AMOUNT
	t.target_value = bump_amount
	return t
