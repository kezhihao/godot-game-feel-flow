@tool
@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFCameraOrthoSpring
extends GFFSpringEffect

## Springs a Camera3D's orthographic size by a punch amount (Feel: MMF_CameraOrthographicSizeSpring).

const GFFPropertyTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_property_target.gd")

@export var bump_amount: float = 2.0

func _init() -> void:
	label = "Camera Ortho Spring"
	duration = 0.6

func _build_target() -> GFFTarget:
	var t := GFFPropertyTargetScript.new()
	t.property_path = "size"
	t.mode = GFFPropertyTargetScript.Mode.BY_AMOUNT
	t.target_float = bump_amount
	return t
