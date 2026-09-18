@tool
@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFPositionSpring
extends GFFSpringEffect

## Springs a Node's position by a punch amount (Feel: MMF_PositionSpring).

const GFFPositionTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_position_target.gd")

@export var bump_amount: Vector3 = Vector3(0.0, 0.3, 0.0)

func _init() -> void:
	label = "Position Spring"
	duration = 0.6

func _build_target() -> GFFTarget:
	var t := GFFPositionTargetScript.new()
	t.mode = GFFPositionTargetScript.Mode.BY_AMOUNT
	t.target_value = bump_amount
	return t
