@tool
class_name GFFMaterialUtil
extends RefCounted

## Material acquisition helper for Game Feel Flow effects.
##
## Effects that write material properties should never mutate a shared
## resource: acquire() returns a per-instance material (duplicating into the
## surface override when needed) plus enough info for release() to put the
## original override back when the effect ends.

## Returns {"material": Material, "original_override": Material, "replaced": bool}
static func acquire(node: Node, surface: int = 0, unique: bool = true) -> Dictionary:
	var out := {"material": null, "original_override": null, "replaced": false}
	var mi := node as MeshInstance3D
	if mi == null:
		return out
	var original := mi.get_surface_override_material(surface)
	out["original_override"] = original
	var mat: Material = original
	if mat == null:
		mat = mi.material_override
	if mat == null and mi.mesh:
		mat = mi.mesh.surface_get_material(surface)
	if mat == null:
		return out
	if unique:
		var dup := mat.duplicate() as Material
		mi.set_surface_override_material(surface, dup)
		out["material"] = dup
		out["replaced"] = true
	else:
		out["material"] = mat
	return out

## Put back the original override when acquire() replaced it.
static func release(node: Node, info: Dictionary, surface: int = 0) -> void:
	if not info.get("replaced", false):
		return
	var mi := node as MeshInstance3D
	if is_instance_valid(mi):
		mi.set_surface_override_material(surface, info["original_override"])
