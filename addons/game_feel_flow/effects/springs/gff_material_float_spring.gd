@tool
@icon("res://addons/game_feel_flow/icons/icon_spring.svg")
class_name GFFMaterialFloatSpring
extends GFFSpringEffect

## Springs a float on the target's surface material (Feel: MMF_MaterialFloatSpring).
## property_path resolves as "material:<prop>" — StandardMaterial3D fields like
## "metallic" work directly; on ShaderMaterial it falls back to shader params.

const GFFPropertyTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_property_target.gd")

## Material property (e.g. "metallic", "roughness") or shader param name.
@export var material_param: String = "metallic"
@export var bump_amount: float = 0.8

func _init() -> void:
	label = "Material Float Spring"
	duration = 0.6

func _build_target() -> GFFTarget:
	var t := GFFPropertyTargetScript.new()
	t.property_path = "material:" + material_param
	t.mode = GFFPropertyTargetScript.Mode.BY_AMOUNT
	t.target_float = bump_amount
	return t
