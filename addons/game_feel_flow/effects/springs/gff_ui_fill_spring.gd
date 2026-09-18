@tool
@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFUIFillSpring
extends GFFSpringEffect

## Springs a ProgressBar/TextureProgressBar's value by a punch amount
## (Feel: MMF_ImageFillAmountSpring equivalent for Godot controls).

const GFFPropertyTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_property_target.gd")

@export var bump_amount: float = 30.0

func _init() -> void:
	label = "UI Fill Spring"
	duration = 0.6

func _build_target() -> GFFTarget:
	var t := GFFPropertyTargetScript.new()
	t.property_path = "value"
	t.mode = GFFPropertyTargetScript.Mode.BY_AMOUNT
	t.target_float = bump_amount
	return t
