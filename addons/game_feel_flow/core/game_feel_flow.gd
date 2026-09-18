extends Node

## Game Feel Flow
##
## Global singleton providing shortcut APIs and effect management

const GFFEventScript = preload("res://addons/game_feel_flow/effects/events/gff_event.gd")
const GFFSignalScript = preload("res://addons/game_feel_flow/effects/events/gff_signal.gd")
const GFFMethodScript = preload("res://addons/game_feel_flow/effects/events/gff_method.gd")
# Preload: headless runs have no editor class cache, so uncached class_name
# identifiers would fail at parse time.
const GFFSpringTweenerScript = preload("res://addons/game_feel_flow/core/tweeners/gff_spring_tweener.gd")
const GFFChannelBusScript = preload("res://addons/game_feel_flow/core/channels/gff_channel_bus.gd")
const GFFChannelBroadcastScript = preload("res://addons/game_feel_flow/effects/events/gff_channel_broadcast.gd")
const GFFSquashAndStretchScript = preload("res://addons/game_feel_flow/effects/transform/gff_squash_and_stretch.gd")
const GFFWiggleScript = preload("res://addons/game_feel_flow/effects/transform/gff_wiggle.gd")
const GFFDestinationTransformScript = preload("res://addons/game_feel_flow/effects/transform/gff_destination_transform.gd")
const GFFRotateAroundScript = preload("res://addons/game_feel_flow/effects/transform/gff_rotate_around.gd")
const GFFLookAtScript = preload("res://addons/game_feel_flow/effects/transform/gff_look_at.gd")
const GFFNodeStateScript = preload("res://addons/game_feel_flow/effects/logic/gff_node_state.gd")
const GFFFlickerScript = preload("res://addons/game_feel_flow/effects/materials/gff_flicker.gd")
const GFFMaterialPropertyScript = preload("res://addons/game_feel_flow/effects/materials/gff_material_property.gd")
const GFFUVScrollScript = preload("res://addons/game_feel_flow/effects/materials/gff_uv_scroll.gd")
const GFFSpriteSheetScript = preload("res://addons/game_feel_flow/effects/materials/gff_sprite_sheet.gd")
const GFFLightScript = preload("res://addons/game_feel_flow/effects/rendering/gff_light.gd")
const GFFEnvironmentScript = preload("res://addons/game_feel_flow/effects/rendering/gff_environment.gd")
const GFFCameraPropertyScript = preload("res://addons/game_feel_flow/effects/rendering/gff_camera_property.gd")
const GFFAudioControlScript = preload("res://addons/game_feel_flow/effects/audio/gff_audio_control.gd")
const GFFAudioBusEffectScript = preload("res://addons/game_feel_flow/effects/audio/gff_audio_bus_effect.gd")
const GFFAudioBusScript = preload("res://addons/game_feel_flow/effects/audio/gff_audio_bus.gd")
const GFFRigidbodyActionScript = preload("res://addons/game_feel_flow/effects/physics/gff_rigidbody_action.gd")
const GFFColliderStateScript = preload("res://addons/game_feel_flow/effects/physics/gff_collider_state.gd")
const GFFSpawnScript = preload("res://addons/game_feel_flow/effects/logic/gff_spawn.gd")
const GFFPauseScript = preload("res://addons/game_feel_flow/effects/logic/gff_pause.gd")
const GFFLooperScript = preload("res://addons/game_feel_flow/effects/logic/gff_looper.gd")
const GFFDispatchScript = preload("res://addons/game_feel_flow/effects/logic/gff_dispatch.gd")
const GFFTextScript = preload("res://addons/game_feel_flow/effects/ui/gff_text.gd")
const GFFFloatingTextScript = preload("res://addons/game_feel_flow/effects/ui/gff_floating_text.gd")
const GFFImageScript = preload("res://addons/game_feel_flow/effects/ui/gff_image.gd")
const GFFSceneScript = preload("res://addons/game_feel_flow/effects/logic/gff_scene.gd")
const GFFVideoPlayerScript = preload("res://addons/game_feel_flow/effects/audio/gff_video_player.gd")
const GFFHapticsScript = preload("res://addons/game_feel_flow/effects/events/gff_haptics.gd")
const GFFPostProcessScript = preload("res://addons/game_feel_flow/effects/rendering/gff_post_process.gd")
const GFFRecipesScript = preload("res://addons/game_feel_flow/core/gff_recipes.gd")
# Dedicated spring family (M6) — one class per Feel MMF_*Spring variant.
const GFFPositionSpringScript = preload("res://addons/game_feel_flow/effects/springs/gff_position_spring.gd")
const GFFRotationSpringScript = preload("res://addons/game_feel_flow/effects/springs/gff_rotation_spring.gd")
const GFFScaleSpringScript = preload("res://addons/game_feel_flow/effects/springs/gff_scale_spring.gd")
const GFFLightIntensitySpringScript = preload("res://addons/game_feel_flow/effects/springs/gff_light_intensity_spring.gd")
const GFFLightColorSpringScript = preload("res://addons/game_feel_flow/effects/springs/gff_light_color_spring.gd")
const GFFCameraFovSpringScript = preload("res://addons/game_feel_flow/effects/springs/gff_camera_fov_spring.gd")
const GFFCameraOrthoSpringScript = preload("res://addons/game_feel_flow/effects/springs/gff_camera_ortho_spring.gd")
const GFFAudioPitchSpringScript = preload("res://addons/game_feel_flow/effects/springs/gff_audio_pitch_spring.gd")
const GFFAudioVolumeSpringScript = preload("res://addons/game_feel_flow/effects/springs/gff_audio_volume_spring.gd")
const GFFMaterialFloatSpringScript = preload("res://addons/game_feel_flow/effects/springs/gff_material_float_spring.gd")
const GFFUIFillSpringScript = preload("res://addons/game_feel_flow/effects/springs/gff_ui_fill_spring.gd")
const GFFAlphaSpringScript = preload("res://addons/game_feel_flow/effects/springs/gff_alpha_spring.gd")

# ===== Signals =====
signal effect_started(effect_name: String)
signal effect_finished(effect_name: String)

# ===== Properties =====
var debug_enabled: bool = false
var _effect_registry: Dictionary = {}
var _combo_registry: Dictionary = {}
var _overlap_manager: Node = null
var _effect_stack: GFFEffectStack = null
var _channel_bus = null  # GFFChannelBus

# ===== Lifecycle =====

func _ready() -> void:
	print("Game Feel Flow: Initializing...")
	GFFEffectConfigManager.register_all()
	_register_effects()
	_register_combos()
	_effect_stack = GFFEffectStack.new()
	_effect_stack.effect_started.connect(_on_stack_effect_started)
	_effect_stack.effect_finished.connect(_on_stack_effect_finished)
	print("Game Feel Flow: Ready (", _effect_registry.size(), " effects, ", _combo_registry.size(), " combos)")

# ===== Core API =====

func _resolve_target_for_effect(effect: GFFEffect, target: Node) -> Node:
	## If the effect is a camera effect but the target is not a camera, auto-find the current viewport's active camera
	if effect is GFFEffectCommon:
		var common := effect as GFFEffectCommon
		if common.target and (
			common.target is GFFCameraOffsetTarget
			or common.target is GFFCameraZoomTarget
			or common.target is GFFCameraFovTarget
		):
			if not (target is Camera2D or target is Camera3D):
				var viewport := target.get_viewport()
				if viewport:
					var cam2d := viewport.get_camera_2d()
					if cam2d:
						return cam2d
					var cam3d := viewport.get_camera_3d()
					if cam3d:
						return cam3d
				push_warning("GameFeelFlow: Camera effect requires a Camera2D/Camera3D target, none found for ", target.name)
	return target


func play(effect, target: Node, params = null) -> void:
	## Play effect
	## effect: String | GFFEffect | GFFCombo
	if debug_enabled:
		print("GameFeelFlow: Playing effect on ", target.name)

	# Find GFFPlayer
	var player = _find_player(target)

	if player:
		# Play via GFFPlayer
		await player.play(effect, params)
	else:
		# Play directly through the global effect stack
		if effect is String:
			var feedback = get_effect(effect)
			if feedback:
				feedback = feedback.duplicate(true)
				target = _resolve_target_for_effect(feedback, target)
				var started := _effect_stack.play(feedback, target, _ensure_params(params))
				if started:
					effect_started.emit(effect)
					await feedback.finished
					effect_finished.emit(effect)
			else:
				push_warning("GameFeelFlow: Effect not found: ", effect)
		elif effect is GFFEffect:
			target = _resolve_target_for_effect(effect, target)
			var started := _effect_stack.play(effect, target, _ensure_params(params))
			if started:
				var effect_name: String = effect.label if effect.label else "unknown"
				effect_started.emit(effect_name)
				await effect.finished
				effect_finished.emit(effect_name)
		elif effect is GFFCombo:
			var combo: GFFCombo = effect.duplicate(true)
			effect_started.emit(combo.label if combo.label else "unknown")
			await combo.execute(target, _ensure_params(params))
			effect_finished.emit(combo.label if combo.label else "unknown")

func play_combo(combo, target: Node, params = null) -> void:
	## Play combo effect
	## combo: String | GFFCombo
	if debug_enabled:
		print("GameFeelFlow: Playing combo on ", target.name)

	# Find GFFPlayer
	var player = _find_player(target)

	if player:
		# Play via GFFPlayer
		await player.play_combo(combo, params)
	else:
		# Play directly
		if combo is String:
			var combo_resource = get_combo(combo)
			if combo_resource:
				combo_resource = combo_resource.duplicate(true)
				effect_started.emit(combo)
				await combo_resource.execute(target, _ensure_params(params))
				effect_finished.emit(combo)
			else:
				push_warning("GameFeelFlow: Combo not found: ", combo)
		elif combo is GFFCombo:
			effect_started.emit(combo.label if combo.label else "unknown")
			await combo.execute(target, _ensure_params(params))
			effect_finished.emit(combo.label if combo.label else "unknown")

func play_global(effect, params = null) -> void:
	## Play global effect (no target node needed, e.g. freeze frame, time scale)
	## effect: String | GFFEffect
	var tree = Engine.get_main_loop()
	if not tree is SceneTree:
		push_warning("GameFeelFlow: SceneTree not available for global effect")
		return
	await play(effect, tree.root, params)

func stop(target: Node) -> void:
	## Stop all effects on target (GFFPlayer-owned and global stack).
	stop_all(target)

func stop_all(node: Node = null) -> void:
	## Stop all effects. If a node is provided, only stop effects on that node
	## and its descendants (including GFFPlayer-owned effects and global-stack effects).
	if node:
		for player in _find_players(node):
			player.stop()
		if _effect_stack:
			_effect_stack.stop_by_target(node)
	else:
		if _effect_stack:
			_effect_stack.clear()

# ===== Registration =====

func register_effect(name: String, effect: GFFEffect) -> void:
	## Register effect
	_effect_registry[name] = effect

func register_combo(name: String, combo: GFFCombo) -> void:
	## Register combo
	_combo_registry[name] = combo

func register_target(key: String, script: Script) -> void:
	## Register a custom target type for Pro or user extensions
	GFFEffectRegistry.register_target(key, script)

func register_tweener(key: String, script: Script) -> void:
	## Register a custom tweener type for Pro or user extensions
	GFFEffectRegistry.register_tweener(key, script)

func register_preset(name: String, target_key: String, tweener_key: String) -> void:
	## Register a custom effect preset for Pro or user extensions
	GFFEffectRegistry.register_preset(name, target_key, tweener_key)

func get_effect(name: String) -> GFFEffect:
	## Get effect
	return _effect_registry.get(name)

func get_combo(name: String) -> GFFCombo:
	## Get combo
	return _combo_registry.get(name)

func get_effect_names() -> Array:
	## Get all effect names
	return _effect_registry.keys()

func get_combo_names() -> Array:
	## Get all combo names
	return _combo_registry.keys()

func get_all_effects() -> Dictionary:
	## Get all effects (read-only)
	return _effect_registry.duplicate()

func get_all_combos() -> Dictionary:
	## Get all combos (read-only)
	return _combo_registry.duplicate()

# ===== Signal System =====

func emit(event: String, data: Dictionary = {}) -> void:
	## Emit event
	if event in _signal_listeners:
		for callback in _signal_listeners[event]:
			callback.call(data)

func listen(event: String, callback: Callable) -> void:
	## Listen to event
	if event not in _signal_listeners:
		_signal_listeners[event] = []
	_signal_listeners[event].append(callback)

func unlisten(event: String, callback: Callable) -> void:
	## Stop listening
	if event in _signal_listeners:
		_signal_listeners[event].erase(callback)

# ===== Channel Bus =====
## Channel-scoped pub/sub (Feel MMChannel + MMEventManager equivalent).
## Channels: int / StringName / GFFChannel asset; listeners may pass null to
## receive an event on every channel (wildcard).

func _get_channel_bus():
	if _channel_bus == null:
		_channel_bus = GFFChannelBusScript.new()
		_channel_bus.debug_enabled = debug_enabled
	return _channel_bus

func broadcast_channel(channel: Variant, event: StringName, payload: Dictionary = {}) -> int:
	## Deliver payload to all listeners of `event` on `channel` (plus wildcard listeners).
	## Returns how many callbacks were invoked.
	return _get_channel_bus().broadcast(channel, event, payload)

func listen_channel(channel: Variant, event: StringName, callback: Callable) -> void:
	## Subscribe `callback(payload)` to `event` on `channel`. channel=null listens everywhere.
	_get_channel_bus().subscribe(channel, event, callback)

func unlisten_channel(channel: Variant, event: StringName, callback: Callable) -> void:
	_get_channel_bus().unsubscribe(channel, event, callback)

# ===== Debug Methods =====

func set_debug(enabled: bool) -> void:
	## Set debug mode
	debug_enabled = enabled

# ===== Internal Methods =====

var _signal_listeners: Dictionary = {}

func _register_effects() -> void:
	## Register built-in effects
	# Shake series
	_effect_registry["shake_position"] = GFFEffectRegistry.create_effect("position", "shake")
	_effect_registry["shake_scale"] = GFFEffectRegistry.create_effect("scale", "shake")
	_effect_registry["shake_rotation"] = GFFEffectRegistry.create_effect("rotation", "shake")

	# Punch series — relative BY_AMOUNT + elastic return to origin
	_effect_registry["punch_position"] = GFFEffectRegistry.create_effect("position", "elastic")
	var punch_scale := GFFEffectRegistry.create_effect("scale", "elastic") as GFFEffectCommon
	var punch_scale_target := punch_scale.target as GFFScaleTarget
	punch_scale_target.mode = GFFScaleTarget.Mode.BY_AMOUNT
	punch_scale_target.target_value = Vector3(0.25, 0.25, 0.0)
	(punch_scale.tweener as GFFElasticTweener).punch_mode = GFFElasticTweener.PunchMode.TO_ORIGIN
	_effect_registry["punch_scale"] = punch_scale
	_effect_registry["punch_rotation"] = GFFEffectRegistry.create_effect("rotation", "elastic")

	# Curved series
	_effect_registry["curved_position"] = GFFEffectRegistry.create_effect("position", "linear")
	_effect_registry["curved_scale"] = GFFEffectRegistry.create_effect("scale", "linear")
	_effect_registry["curved_rotation"] = GFFEffectRegistry.create_effect("rotation", "linear")

	# Special effects
	_effect_registry["flash"] = GFFEffectRegistry.create_effect("color", "flash")
	_effect_registry["color"] = GFFEffectRegistry.create_effect("color", "color")
	var alpha_effect := GFFEffectRegistry.create_effect("alpha", "linear") as GFFEffectCommon
	(alpha_effect.target as GFFAlphaTarget).target_alpha = 0.0
	alpha_effect.restore_after_play = true
	alpha_effect.restore_mode = GFFEffect.RestoreMode.GRADUAL
	alpha_effect.restore_duration = 0.25
	_effect_registry["alpha"] = alpha_effect

	# Camera effects
	_effect_registry["camera_shake"] = GFFEffectRegistry.create_effect("camera_offset", "shake")
	_effect_registry["camera_zoom"] = GFFEffectRegistry.create_effect("camera_zoom", "linear")
	_effect_registry["camera_fov"] = GFFEffectRegistry.create_effect("camera_fov", "linear")

	# Spring series — damped-oscillator punch (Feel-style squash & stretch feel)
	# Dedicated spring classes — same tuned defaults the lab baselines expect.
	_effect_registry["spring_scale"] = GFFScaleSpringScript.new()
	_effect_registry["spring_position"] = GFFPositionSpringScript.new()
	_effect_registry["spring_rotation"] = GFFRotationSpringScript.new()
	# M6 dedicated spring family registrations.
	_effect_registry["light_intensity_spring"] = GFFLightIntensitySpringScript.new()
	_effect_registry["light_color_spring"] = GFFLightColorSpringScript.new()
	_effect_registry["camera_fov_spring"] = GFFCameraFovSpringScript.new()
	_effect_registry["camera_ortho_spring"] = GFFCameraOrthoSpringScript.new()
	_effect_registry["audio_pitch_spring"] = GFFAudioPitchSpringScript.new()
	_effect_registry["audio_volume_spring"] = GFFAudioVolumeSpringScript.new()
	_effect_registry["material_float_spring"] = GFFMaterialFloatSpringScript.new()
	_effect_registry["ui_fill_spring"] = GFFUIFillSpringScript.new()
	_effect_registry["alpha_spring"] = GFFAlphaSpringScript.new()

	# Transform punch family — squash & stretch + wiggle (Feel transform feedbacks)
	var squash := GFFSquashAndStretchScript.new()
	squash.axis = GFFSquashAndStretchScript.Axis.Y
	squash.squash_amount = 0.4
	_effect_registry["squash_stretch"] = squash

	var wiggle_pos := GFFWiggleScript.new()
	wiggle_pos.wiggle_property = GFFWiggleScript.WiggleProperty.POSITION
	wiggle_pos.amplitude = Vector3(0.25, 0.25, 0.0)
	wiggle_pos.frequency = 6.0
	_effect_registry["wiggle_position"] = wiggle_pos

	var wiggle_rot := GFFWiggleScript.new()
	wiggle_rot.wiggle_property = GFFWiggleScript.WiggleProperty.ROTATION
	wiggle_rot.amplitude = Vector3(0.0, 12.0, 0.0)
	_effect_registry["wiggle_rotation"] = wiggle_rot

	# Channel broadcast — fires an event on a channel; remote receivers react.
	var channel_bcast := GFFChannelBroadcastScript.new()
	channel_bcast.channel_mode = GFFChannelBroadcastScript.ChannelMode.INT
	channel_bcast.channel = 0
	_effect_registry["channel_broadcast"] = channel_bcast

	# Batch A remaining transform feedbacks — destination/orbit/look + node state
	var dest_tf := GFFDestinationTransformScript.new()
	dest_tf.duration = 0.8
	_effect_registry["destination_transform"] = dest_tf

	var orbit := GFFRotateAroundScript.new()
	orbit.total_angle_deg = 360.0
	orbit.duration = 1.2
	_effect_registry["rotate_around"] = orbit

	var look := GFFLookAtScript.new()
	look.turn_speed_deg = 540.0
	_effect_registry["look_at"] = look

	var node_state := GFFNodeStateScript.new()
	node_state.action = &"toggle"
	_effect_registry["node_state"] = node_state

	# Batch B — material / rendering effects (Feel render-side feedbacks)
	var flicker := GFFFlickerScript.new()
	flicker.flicker_mode = GFFFlickerScript.FlickerMode.COLOR
	flicker.rate_hz = 18.0
	_effect_registry["flicker"] = flicker

	var mat_prop := GFFMaterialPropertyScript.new()
	mat_prop.property_name = &"metallic"
	mat_prop.to_value = 0.9
	_effect_registry["material_property"] = mat_prop

	var uv := GFFUVScrollScript.new()
	uv.uv_mode = GFFUVScrollScript.UVMode.SCROLL
	uv.scroll_velocity = Vector3(0.5, 0.0, 0.0)
	_effect_registry["uv_scroll"] = uv

	var sheet := GFFSpriteSheetScript.new()
	sheet.fps = 8.0
	_effect_registry["sprite_sheet"] = sheet

	var light_fx := GFFLightScript.new()
	light_fx.light_property = GFFLightScript.LightProp.ENERGY
	light_fx.to_value = 0.15
	_effect_registry["light"] = light_fx

	var env_fx := GFFEnvironmentScript.new()
	env_fx.env_property = GFFEnvironmentScript.EnvProp.AMBIENT_ENERGY
	env_fx.to_value = 0.15
	_effect_registry["environment"] = env_fx

	# Batch C — camera lens properties (Feel camera feedbacks)
	var cam_clip := GFFCameraPropertyScript.new()
	cam_clip.camera_property = GFFCameraPropertyScript.CamProp.NEAR
	cam_clip.to_value = 3.0
	_effect_registry["camera_clip"] = cam_clip

	var cam_ortho := GFFCameraPropertyScript.new()
	cam_ortho.camera_property = GFFCameraPropertyScript.CamProp.ORTHO_SIZE
	cam_ortho.to_value = 8.0
	cam_ortho.force_orthogonal = true
	_effect_registry["camera_ortho"] = cam_ortho

	# Batch D — audio: player control + bus effects + bus snapshot
	var audio_play := GFFAudioControlScript.new()
	audio_play.action = &"play"
	_effect_registry["audio_control"] = audio_play

	var audio_pitch := GFFAudioControlScript.new()
	audio_pitch.action = &"pitch"
	audio_pitch.to_value = 0.5
	_effect_registry["audio_pitch"] = audio_pitch

	var bus_fx := GFFAudioBusEffectScript.new()
	bus_fx.effect_type = GFFAudioBusEffectScript.EffectType.LOWPASS
	bus_fx.param_name = &"cutoff_hz"
	bus_fx.to_value = 800.0
	_effect_registry["audio_bus_effect"] = bus_fx

	var bus_snap := GFFAudioBusScript.new()
	bus_snap.bus_action = GFFAudioBusScript.BusAction.VOLUME
	bus_snap.to_value = -12.0
	_effect_registry["audio_bus"] = bus_snap

	# Batch E — physics: rigidbody actions + collider state
	var rb_action := GFFRigidbodyActionScript.new()
	rb_action.action = &"force"
	rb_action.force = Vector3(6.0, 0.0, 0.0)
	_effect_registry["rigidbody_action"] = rb_action

	var collider := GFFColliderStateScript.new()
	collider.action = &"toggle"
	_effect_registry["collider_state"] = collider

	# Batch F — lifecycle/logic: spawn/destroy, pause/hold/signal-wait, looper, dispatch
	var spawn_fx := GFFSpawnScript.new()
	spawn_fx.action = &"spawn"
	_effect_registry["spawn"] = spawn_fx

	var destroy_fx := GFFSpawnScript.new()
	destroy_fx.action = &"destroy"
	_effect_registry["destroy"] = destroy_fx

	var pause_fx := GFFPauseScript.new()
	pause_fx.wait_mode = &"time"
	_effect_registry["pause"] = pause_fx

	var looper_fx := GFFLooperScript.new()
	looper_fx.repeat_count = 2
	_effect_registry["looper"] = looper_fx

	var dispatch_fx := GFFDispatchScript.new()
	dispatch_fx.dispatch_action = &"play"
	_effect_registry["dispatch"] = dispatch_fx

	# Batch G — UI/text: label typewriter+color, floating text, image/fill
	var text_fx := GFFTextScript.new()
	text_fx.text_mode = &"typewriter"
	_effect_registry["text"] = text_fx

	var float_text := GFFFloatingTextScript.new()
	float_text.duration = 0.8
	_effect_registry["floating_text"] = float_text

	var image_fx := GFFImageScript.new()
	image_fx.image_mode = &"fill"
	_effect_registry["image"] = image_fx

	# Batch H — scene/media: scene load-add-unload + video player control
	var scene_fx := GFFSceneScript.new()
	scene_fx.scene_action = &"add_scene"
	_effect_registry["scene"] = scene_fx

	var video_fx := GFFVideoPlayerScript.new()
	video_fx.video_action = &"play"
	_effect_registry["video"] = video_fx

	# M3 — subsystems: haptics + deep post-processing
	var haptics := GFFHapticsScript.new()
	haptics.haptic_mode = &"handheld"
	_effect_registry["haptics"] = haptics

	var post := GFFPostProcessScript.new()
	post.post_prop = GFFPostProcessScript.PostProp.GLOW_BLOOM
	post.to_value = 0.3
	_effect_registry["post_process"] = post

	# Keep old screen flash effect
	_effect_registry["camera_flash"] = GFFCameraFlash.new()

	# Audio effects
	_effect_registry["sound"] = GFFSound.new()
	_effect_registry["audio_volume"] = GFFAudioVolume.new()

	# Time effects
	_effect_registry["freeze_frame"] = GFFFreezeFrame.new()
	_effect_registry["time_scale"] = GFFTimeScale.new()

	# Particle effects
	_effect_registry["particles"] = GFFParticles.new()
	_effect_registry["gpu_particles"] = GFFGPUParticles.new()

	# Physics effects
	_effect_registry["impulse"] = GFFImpulse.new()
	_effect_registry["velocity"] = GFFVelocity.new()

	# Animation effects
	_effect_registry["tween"] = GFFTween.new()
	_effect_registry["animator"] = GFFAnimator.new()

	# Event effects
	_effect_registry["event"] = GFFEventScript.new()
	_effect_registry["signal"] = GFFSignalScript.new()
	_effect_registry["method"] = GFFMethodScript.new()

	# Keep old names as aliases
	_effect_registry["shake"] = _effect_registry["shake_position"]
	_effect_registry["punch"] = _effect_registry["punch_position"]

	print("Game Feel Flow: Registered ", _effect_registry.size(), " effects")

func _register_combos() -> void:
	## Register built-in combos
	_combo_registry["hit_light"] = GFFCombo.hit_light()
	_combo_registry["hit_medium"] = GFFCombo.hit_medium()
	_combo_registry["hit_heavy"] = GFFCombo.hit_heavy()
	_combo_registry["hit_critical"] = GFFCombo.hit_critical()
	_combo_registry["death"] = GFFCombo.death()
	_combo_registry["death_explosion"] = GFFCombo.death_explosion()
	_combo_registry["pickup"] = GFFCombo.pickup()
	_combo_registry["pickup_coin"] = GFFCombo.pickup_coin()
	_combo_registry["pickup_health"] = GFFCombo.pickup_health()
	_combo_registry["pickup_power"] = GFFCombo.pickup_power()
	_combo_registry["explosion"] = GFFCombo.explosion()
	_combo_registry["explosion_small"] = GFFCombo.explosion_small()
	_combo_registry["explosion_large"] = GFFCombo.explosion_large()
	_combo_registry["ui_button_press"] = GFFCombo.ui_button_press()
	_combo_registry["ui_notification"] = GFFCombo.ui_notification()

	# GF-100 — Feel-style recipe combos on the M1–M3 effect family
	_combo_registry["recipe_hit"] = GFFRecipesScript.recipe_hit()
	_combo_registry["recipe_death"] = GFFRecipesScript.recipe_death()
	_combo_registry["recipe_explosion"] = GFFRecipesScript.recipe_explosion()
	_combo_registry["recipe_pickup"] = GFFRecipesScript.recipe_pickup()
	_combo_registry["recipe_heal"] = GFFRecipesScript.recipe_heal()
	_combo_registry["recipe_landing"] = GFFRecipesScript.recipe_landing()
	_combo_registry["recipe_dash"] = GFFRecipesScript.recipe_dash()
	_combo_registry["recipe_camera_hit"] = GFFRecipesScript.recipe_camera_hit()
	_combo_registry["recipe_ui_confirm"] = GFFRecipesScript.recipe_ui_confirm()

func _find_player(target: Node) -> GFFPlayer:
	## Recursively find GFFPlayer node
	if target is GFFPlayer:
		return target
	for child in target.get_children():
		if child is GFFPlayer:
			return child
		var found = _find_player(child)
		if found:
			return found
	return null

func _find_players(node: Node) -> Array[GFFPlayer]:
	## Recursively find all GFFPlayer nodes under the given node
	var players: Array[GFFPlayer] = []
	if node is GFFPlayer:
		players.append(node)
	for child in node.get_children():
		if child is GFFPlayer:
			players.append(child)
		else:
			players.append_array(_find_players(child))
	return players

func _on_stack_effect_started(effect_id: String) -> void:
	if debug_enabled:
		print("GameFeelFlow: Stack started ", effect_id)

func _on_stack_effect_finished(effect_id: String) -> void:
	if debug_enabled:
		print("GameFeelFlow: Stack finished ", effect_id)

func _ensure_params(params) -> GFFParams:
	## Ensure params is a GFFParams type
	if params == null:
		return GFFParams.create()
	elif params is float or params is int:
		return GFFParams.create(params)
	elif params is Dictionary:
		return GFFParams.from_dict(params)
	elif params is GFFParams:
		return params
	else:
		return GFFParams.create()
