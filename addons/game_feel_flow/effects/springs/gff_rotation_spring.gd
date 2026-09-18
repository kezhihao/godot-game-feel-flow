@tool
@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFRotationSpring
extends GFFSpringEffect

## Springs a Node3D's Y rotation by a punch amount in degrees (Feel: MMF_RotationSpring).

const GFFRotationTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_rotation_target.gd")

@export var bump_amount: float = 15.0

func _init() -> void:
	label = "Rotation Spring"
	duration = 0.6

func _build_target() -> GFFTarget:
	var t := GFFRotationTargetScript.new()
	t.mode = GFFRotationTargetScript.Mode.BY_AMOUNT
	t.target_value = bump_amount
	return t
