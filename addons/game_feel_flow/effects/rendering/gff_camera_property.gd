@tool
class_name GFFCameraProperty
extends GFFEffect

## Game Feel Flow Camera Property
##
## Tweens camera lens properties — counterparts of Feel's
## MMF_CameraClippingPlanes / MMF_CameraOrthographicSize (+ FOV) feedbacks.
## Works on Camera2D (zoom) and Camera3D (near/far/size/fov). ORTHO_SIZE can
## temporarily force the orthogonal projection so the tween is meaningful.

enum CamProp { NEAR, FAR, ORTHO_SIZE, FOV, ZOOM }

@export_group("Camera")
@export var camera_property: CamProp = CamProp.NEAR
## Destination value (float).
@export var to_value: float = 0.5
## Out-and-back pulse; false keeps to_value.
@export var ping_pong: bool = true
## For ORTHO_SIZE: switch the camera to orthogonal projection for the play.
@export var force_orthogonal: bool = false
@export var debug_enabled: bool = false

func _execute(node: Node, params: GFFParams) -> void:
	var prop_i: int = params.get_int("camera_property", camera_property)
	var to: float = params.get_float("to", to_value)
	var final_duration := params.get_float("duration", duration)
	var do_ping_pong := params.get_bool("ping_pong", ping_pong)
	var intensity := params.get_float("intensity", 1.0)
	var force_ortho := params.get_bool("force_orthogonal", force_orthogonal)

	var prop: StringName
	var base_projection := -1
	var cam3 := node as Camera3D
	var cam2 := node as Camera2D
	match prop_i:
		CamProp.NEAR:
			if cam3: prop = &"near"
		CamProp.FAR:
			if cam3: prop = &"far"
		CamProp.ORTHO_SIZE:
			if cam3:
				prop = &"size"
				if force_ortho:
					base_projection = cam3.projection
					cam3.projection = Camera3D.PROJECTION_ORTHOGONAL
		CamProp.FOV:
			if cam3:
				prop = &"fov"
			elif cam2:
				push_warning("GFFCameraProperty: Camera2D has no fov, use ZOOM")
				return
		CamProp.ZOOM:
			if cam2:
				prop = &"zoom.x"  # zoom is Vector2; drive uniformly
			elif cam3:
				push_warning("GFFCameraProperty: Camera3D has no zoom, use FOV")
				return
	if prop.is_empty():
		push_warning("GFFCameraProperty: property ", prop_i, " not available on ", node.get_class())
		_restore_projection(node, base_projection)
		return

	var from: float
	var is_zoom := prop == &"zoom.x"
	if is_zoom:
		from = (node as Camera2D).zoom.x
	else:
		from = float(node.get(prop))
	to = lerpf(from, to, intensity)
	_dbg("prop=" + String(prop) + " from=" + str(from) + " to=" + str(to))

	var total := final_duration * (2.0 if do_ping_pong else 1.0)
	var elapsed := 0.0
	while elapsed < total and _is_playing:
		if not is_instance_valid(node):
			return
		var t: float
		if do_ping_pong:
			t = clampf(elapsed / final_duration, 0.0, 1.0)
			if elapsed > final_duration:
				t = 2.0 - t
		else:
			t = clampf(elapsed / final_duration, 0.0, 1.0)
		var v := lerpf(from, to, _apply_curve(t, easing_curve))
		if is_zoom:
			(node as Camera2D).zoom = Vector2(v, v)
		else:
			node.set(prop, v)
		await node.get_tree().process_frame
		if not is_instance_valid(node) or not _is_playing:
			return
		elapsed += node.get_process_delta_time()

	if is_instance_valid(node):
		var end_v: float = from if do_ping_pong else to
		if is_zoom:
			(node as Camera2D).zoom = Vector2(end_v, end_v)
		else:
			node.set(prop, end_v)
		_restore_projection(node, base_projection)

func _restore_projection(node: Node, base_projection: int) -> void:
	var cam3 := node as Camera3D
	if cam3 and base_projection >= 0:
		cam3.projection = base_projection

func _get_default_duration() -> float:
	return 0.4

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFCameraProperty] ", message)
