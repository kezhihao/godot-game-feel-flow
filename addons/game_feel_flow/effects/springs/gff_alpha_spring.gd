@tool
@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFAlphaSpring
extends GFFSpringEffect

## Springs a CanvasItem's modulate alpha toward a value then back
## (Feel: MMF_CanvasGroupAlphaSpring equivalent).

const GFFAlphaTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_alpha_target.gd")

@export var target_alpha: float = 0.0

func _init() -> void:
	label = "Alpha Spring"
	duration = 0.6

func _build_target() -> GFFTarget:
	var t := GFFAlphaTargetScript.new()
	t.target_alpha = target_alpha
	return t
