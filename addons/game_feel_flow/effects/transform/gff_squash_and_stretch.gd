@tool
class_name GFFSquashAndStretch
extends GFFEffect

## Game Feel Flow Squash & Stretch
##
## The classic cartoon squash-and-stretch punch — counterpart of Feel's
## MMF_SquashAndStretch. Compresses the node along one axis while expanding
## the perpendicular axes to fake volume preservation, driven by a 0->1->0
## sine envelope so it snaps out and settles back.

enum Axis { X, Y, Z }

@export_group("Squash & Stretch")
## Axis that gets compressed.
@export var axis: Axis = Axis.Y
## Compression strength at envelope peak: 0.4 shrinks the axis to 60%.
@export var squash_amount: float = 0.4
## Expand the other axes by 1/sqrt(factor) to fake constant volume.
@export var preserve_volume: bool = true
## Optional envelope override (sampled 0..1 over the play). Default: sin(t*PI).
@export var envelope_curve: Curve = null

func _execute(node: Node, params: GFFParams) -> void:
	var amount := squash_amount * params.get_float("intensity", 1.0)
	var final_duration := params.get_float("duration", duration)
	var base_scale: Vector3 = _get_scale(node)
	if base_scale == Vector3.ZERO:
		push_warning("GFFSquashAndStretch: target scale is zero, nothing to squash")
		return

	var elapsed := 0.0
	while elapsed < final_duration and _is_playing:
		if not is_instance_valid(node):
			return
		var t := elapsed / final_duration
		var env := _envelope(t)
		var s := base_scale
		var factor := 1.0 - amount * env
		var compensate := 1.0 / sqrt(maxf(factor, 0.01)) if preserve_volume else 1.0
		match axis:
			Axis.X:
				s = Vector3(base_scale.x * factor, base_scale.y * compensate, base_scale.z * compensate)
			Axis.Y:
				s = Vector3(base_scale.x * compensate, base_scale.y * factor, base_scale.z * compensate)
			Axis.Z:
				s = Vector3(base_scale.x * compensate, base_scale.y * compensate, base_scale.z * factor)
		_set_scale(node, s)
		await node.get_tree().process_frame
		if not is_instance_valid(node) or not _is_playing:
			return
		elapsed += node.get_process_delta_time()

	if is_instance_valid(node):
		_set_scale(node, base_scale)

func _envelope(t: float) -> float:
	if envelope_curve:
		return clampf(envelope_curve.sample(t), 0.0, 1.0)
	return sin(t * PI)

func _get_default_intensity() -> float:
	return 1.0

func _get_default_duration() -> float:
	return 0.4
