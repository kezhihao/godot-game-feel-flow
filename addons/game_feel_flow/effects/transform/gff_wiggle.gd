@tool
class_name GFFWiggle
extends GFFEffect

## Game Feel Flow Wiggle
##
## Periodic sine oscillation around the base value — counterpart of Feel's
## MMF_Wiggle / MMWiggle. Unlike shake (random noise), wiggle is smooth and
## rhythmic: position sway, rotation seesaw, breathing scale.

enum WiggleProperty { POSITION, ROTATION, SCALE }

@export_group("Wiggle")
@export var wiggle_property: WiggleProperty = WiggleProperty.POSITION
## Oscillation magnitude. Units: POSITION=world units, ROTATION=degrees, SCALE=units.
@export var amplitude: Vector3 = Vector3(0.2, 0.0, 0.0)
## Oscillations per second.
@export var frequency: float = 4.0
## Fade the oscillation out over the play (linear decay).
@export var decay: bool = true
## Starting phase (0..1 of a cycle). 0.25 starts at the positive peak.
@export var phase: float = 0.0

func _execute(node: Node, params: GFFParams) -> void:
	var amp := amplitude * params.get_float("intensity", 1.0)
	var final_duration := params.get_float("duration", duration)
	var freq := params.get_float("frequency", frequency)
	var base := _read_value(node)

	var elapsed := 0.0
	while elapsed < final_duration and _is_playing:
		if not is_instance_valid(node):
			return
		var t := elapsed / final_duration
		var env := (1.0 - t) if decay else 1.0
		var wave := sin((elapsed * freq + phase) * TAU)
		_apply_value(node, base, amp * wave * env)
		await node.get_tree().process_frame
		if not is_instance_valid(node) or not _is_playing:
			return
		elapsed += node.get_process_delta_time()

	if is_instance_valid(node):
		_apply_value(node, base, Vector3.ZERO)

func _read_value(node: Node) -> Variant:
	match wiggle_property:
		WiggleProperty.POSITION:
			return node.position
		WiggleProperty.ROTATION:
			return node.rotation
		WiggleProperty.SCALE:
			return node.scale
	return null

func _apply_value(node: Node, base: Variant, offset: Vector3) -> void:
	match wiggle_property:
		WiggleProperty.POSITION:
			if node is Node3D:
				node.position = base + offset
			elif node is Node2D or node is Control:
				node.position = base + Vector2(offset.x, offset.y)
		WiggleProperty.ROTATION:
			var rad := offset * (PI / 180.0)
			if node is Node3D:
				node.rotation = base + rad
			elif node is Node2D or node is Control:
				node.rotation = base + rad.y
		WiggleProperty.SCALE:
			if node is Node3D:
				node.scale = base + offset
			elif node is Node2D or node is Control:
				node.scale = Vector2(base.x + offset.x, base.y + offset.y)

func _get_default_intensity() -> float:
	return 1.0

func _get_default_duration() -> float:
	return 0.8
