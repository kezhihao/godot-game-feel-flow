@tool
class_name GFFScene
extends GFFEffect

## Game Feel Flow Scene
##
## Counterpart of Feel's MMF_LoadScene / MMF_UnloadScene feedbacks,
## retargeted to Godot scene-tree APIs. scene_action selects the behavior
## (params["scene_action"] overrides):
##   "load"        -> change_scene_to_file(scene_path) — full scene swap
##   "load_packed" -> change_scene_to_packed(params["scene"]/scene)
##   "add_scene"   -> instantiate PackedScene (params["scene"]/scene or
##                    scene_path) and add it under the tree root — additive
##                    load, like Feel's additive LoadScene
##   "unload"      -> free a previously added scene root: params["target_node"],
##                    unload_name, or the last instance this effect added
##   "reload"      -> reload_current_scene()
## NOTE: load/reload replace the running scene — use with care in tests.

@export_group("Scene")
## One of: load, load_packed, add_scene, unload, reload.
@export var scene_action: StringName = &"add_scene"
## res:// path used by "load" and as PackedScene source for "add_scene".
@export var scene_path: String = ""
## PackedScene for "load_packed"/"add_scene". params["scene"] overrides.
@export var scene: PackedScene = null
## Name for the added scene root / lookup name for "unload".
@export var instance_name: String = ""
## Scene-root node name to free for "unload". params["target_node"] wins.
@export var unload_name: String = ""
@export var debug_enabled: bool = false

var _last_instance: WeakRef = null

func _init() -> void:
	# Scene state is a world change — nothing to restore on the origin.
	restore_after_play = false

func _execute(node: Node, params: GFFParams) -> void:
	var act := StringName(params.get_string("scene_action", String(scene_action)))
	var tree := node.get_tree()
	_dbg("action=" + String(act))
	match String(act):
		"load":
			var path := String(params.get_string("scene_path", scene_path))
			if path.is_empty():
				push_warning("GFFScene: load needs scene_path")
				return
			tree.change_scene_to_file(path)
		"load_packed":
			var packed := _packed(params)
			if packed == null:
				push_warning("GFFScene: load_packed needs a PackedScene")
				return
			tree.change_scene_to_packed(packed)
		"add_scene":
			var packed2 := _packed(params)
			if packed2 == null:
				var p2 := String(params.get_string("scene_path", scene_path))
				if not p2.is_empty() and ResourceLoader.exists(p2):
					packed2 = load(p2)
			if packed2 == null:
				push_warning("GFFScene: add_scene has no scene to instantiate")
				return
			var inst := packed2.instantiate()
			var iname := String(params.get_string("instance_name", instance_name))
			if not iname.is_empty():
				inst.name = iname
			tree.root.add_child(inst)
			_last_instance = weakref(inst)
			_dbg("added " + str(inst))
		"unload":
			var victim: Node = params.get_node("target_node", null)
			var uname := String(params.get_string("unload_name", unload_name))
			if victim == null and not uname.is_empty():
				victim = tree.root.find_child(uname, true, false)
				if victim == null:
					victim = tree.root.get_node_or_null(uname)
			if victim == null and _last_instance:
				victim = _last_instance.get_ref()
			if victim == null or not is_instance_valid(victim):
				push_warning("GFFScene: unload found no scene root")
				return
			_dbg("unload " + str(victim))
			victim.queue_free()
		"reload":
			tree.reload_current_scene()
		_:
			push_warning("GFFScene: unknown scene_action '", act, "'")

func _packed(params: GFFParams) -> PackedScene:
	var v: Variant = params.get_variant("scene", scene)
	return v if v is PackedScene else null

func _get_default_duration() -> float:
	return 0.0

func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFScene] ", message)
