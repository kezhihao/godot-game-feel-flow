@tool
@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFCameraFovSpring
extends GFFSpringEffect

## Springs a Camera3D's fov by a punch amount in degrees (Feel: MMF_CameraFieldOfViewSpring).

const GFFCameraFovTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_camera_fov_target.gd")

@export var bump_amount: float = -8.0

func _init() -> void:
	label = "Camera FOV Spring"
	duration = 0.6

func _build_target() -> GFFTarget:
	var t := GFFCameraFovTargetScript.new()
	t.mode = GFFCameraFovTargetScript.Mode.BY_AMOUNT
	t.target_value = bump_amount
	return t
