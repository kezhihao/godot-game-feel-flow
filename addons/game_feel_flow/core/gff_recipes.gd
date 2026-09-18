@tool
class_name GFFRecipes
extends RefCounted

## Game Feel Flow Recipe Library (GF-100)
##
## Feel-style signature combos rebuilt on the M1–M3 effect family
## (squash & stretch, flicker, wiggle, spring tweeners, freeze frame,
## floating text, haptics). Each static method returns a ready GFFCombo;
## GameFeelFlow registers them in the combo registry at startup.
## Unlike the 2D-oriented built-ins in GFFCombo these recipes are
## target-agnostic and work on Node3D / Node2D / Control alike.

const GFFSquashAndStretchScript := preload("res://addons/game_feel_flow/effects/transform/gff_squash_and_stretch.gd")
const GFFWiggleScript := preload("res://addons/game_feel_flow/effects/transform/gff_wiggle.gd")
const GFFFlickerScript := preload("res://addons/game_feel_flow/effects/materials/gff_flicker.gd")
const GFFFloatingTextScript := preload("res://addons/game_feel_flow/effects/ui/gff_floating_text.gd")
const GFFHapticsScript := preload("res://addons/game_feel_flow/effects/events/gff_haptics.gd")
const GFFFreezeFrameScript := preload("res://addons/game_feel_flow/effects/time/gff_freeze_frame.gd")
const GFFEffectCommonScript := preload("res://addons/game_feel_flow/effects/curved/gff_effect_common.gd")
const GFFPositionTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_position_target.gd")
const GFFScaleTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_scale_target.gd")
const GFFColorTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_color_target.gd")
const GFFCameraOffsetTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_camera_offset_target.gd")
const GFFCameraFovTargetScript := preload("res://addons/game_feel_flow/core/targets/gff_camera_fov_target.gd")
const GFFShakeTweenerScript := preload("res://addons/game_feel_flow/core/tweeners/gff_shake_tweener.gd")
const GFFSpringTweenerScript := preload("res://addons/game_feel_flow/core/tweeners/gff_spring_tweener.gd")
const GFFElasticTweenerScript := preload("res://addons/game_feel_flow/core/tweeners/gff_elastic_tweener.gd")
const GFFFlashTweenerScript := preload("res://addons/game_feel_flow/core/tweeners/gff_flash_tweener.gd")
const GFFLinearTweenerScript := preload("res://addons/game_feel_flow/core/tweeners/gff_linear_tweener.gd")

static var debug_enabled := false

static func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFRecipes] ", message)

# ===== Combat =====

static func recipe_hit() -> GFFCombo:
	## Signature damage feel: squash down + red flicker + micro freeze.
	var combo := GFFCombo.new()
	combo.label = "recipe_hit"
	var squash := GFFSquashAndStretchScript.new()
	squash.squash_amount = 0.35
	squash.duration = 0.18
	combo.add_entry(squash, 0.0, 0.18, 0)
	combo.add_entry(_flicker(Color(1.0, 0.2, 0.15), 14.0), 0.0, 0.25, 1)
	combo.add_entry(_freeze(0.05), 0.02, 0.05, 2)
	return combo

static func recipe_death() -> GFFCombo:
	## Death: big squash + red flicker + floating "KO" + spring shrink.
	## Scale writers are sequenced: the spring bump starts only after the
	## squash finishes and restores — overlapping same-property effects each
	## snapshot "initial" at their own start, so the later one would restore
	## a mid-squash value over the earlier one's restoration.
	var combo := GFFCombo.new()
	combo.label = "recipe_death"
	var squash := GFFSquashAndStretchScript.new()
	squash.squash_amount = 0.6
	squash.duration = 0.3
	combo.add_entry(squash, 0.0, 0.3, 0)
	combo.add_entry(_flicker(Color(1.0, 0.1, 0.1), 10.0), 0.0, 0.5, 1)
	combo.add_entry(_spring_scale(Vector3(-0.4, -0.4, -0.4), 5.0), 0.35, 0.5, 2)
	combo.add_entry(_floating_text("KO", Color(1.0, 0.25, 0.2)), 0.05, 0.9, 3)
	return combo

static func recipe_explosion() -> GFFCombo:
	## Explosion: heavy shake + orange flicker + freeze + spring pop.
	var combo := GFFCombo.new()
	combo.label = "recipe_explosion"
	combo.add_entry(_shake(Vector3(0.35, 0.35, 0.0), 0.4), 0.0, 0.4, 0)
	combo.add_entry(_flicker(Color(1.0, 0.55, 0.1), 16.0), 0.0, 0.3, 1)
	combo.add_entry(_freeze(0.06), 0.05, 0.06, 2)
	combo.add_entry(_spring_scale(Vector3(0.35, 0.35, 0.35), 7.0), 0.08, 0.5, 3)
	return combo

# ===== Pickups / rewards =====

static func recipe_pickup() -> GFFCombo:
	## Pickup: spring pop + wiggle + gold flash + floating "+1".
	var combo := GFFCombo.new()
	combo.label = "recipe_pickup"
	combo.add_entry(_spring_scale(Vector3(0.3, 0.3, 0.3), 8.0), 0.0, 0.45, 0)
	var wig := GFFWiggleScript.new()
	wig.wiggle_property = GFFWiggleScript.WiggleProperty.POSITION
	wig.amplitude = Vector3(0.0, 0.25, 0.0)
	wig.frequency = 3.0
	wig.duration = 0.4
	combo.add_entry(wig, 0.0, 0.4, 1)
	combo.add_entry(_flash(Color(1.0, 0.85, 0.2), 0.12), 0.0, 0.12, 2)
	combo.add_entry(_floating_text("+1", Color(1.0, 0.9, 0.2)), 0.0, 0.8, 3)
	return combo

static func recipe_heal() -> GFFCombo:
	## Heal: green flash + soft spring bump + floating "+HP".
	var combo := GFFCombo.new()
	combo.label = "recipe_heal"
	combo.add_entry(_flash(Color(0.25, 1.0, 0.35), 0.15), 0.0, 0.15, 0)
	combo.add_entry(_spring_scale(Vector3(0.18, 0.18, 0.18), 6.0), 0.0, 0.5, 1)
	combo.add_entry(_floating_text("+HP", Color(0.3, 1.0, 0.4)), 0.05, 0.8, 2)
	return combo

# ===== Traversal =====

static func recipe_landing() -> GFFCombo:
	## Landing impact: squash + small downward shake.
	var combo := GFFCombo.new()
	combo.label = "recipe_landing"
	var squash := GFFSquashAndStretchScript.new()
	squash.squash_amount = 0.3
	squash.duration = 0.15
	combo.add_entry(squash, 0.0, 0.15, 0)
	combo.add_entry(_shake(Vector3(0.0, 0.08, 0.0), 0.12), 0.0, 0.12, 1)
	return combo

static func recipe_dash() -> GFFCombo:
	## Dash: forward punch + X-axis stretch (axis set to X for lateral dash feel).
	var combo := GFFCombo.new()
	combo.label = "recipe_dash"
	combo.add_entry(_punch_position(Vector3(0.0, 0.0, -0.6), 0.25), 0.0, 0.25, 0)
	var squash := GFFSquashAndStretchScript.new()
	squash.axis = GFFSquashAndStretchScript.Axis.X
	squash.squash_amount = 0.25
	squash.duration = 0.3
	combo.add_entry(squash, 0.0, 0.3, 1)
	return combo

# ===== Camera / UI =====

static func recipe_camera_hit() -> GFFCombo:
	## Camera-side impact (target = Camera3D): shake + FOV punch + freeze.
	var combo := GFFCombo.new()
	combo.label = "recipe_camera_hit"
	var shake := GFFEffectCommonScript.new()
	var cam_t := GFFCameraOffsetTargetScript.new()
	var cam_tw := GFFShakeTweenerScript.new()
	cam_tw.amplitude = 0.3
	shake.target = cam_t
	shake.tweener = cam_tw
	shake.duration = 0.35
	combo.add_entry(shake, 0.0, 0.35, 0)
	combo.add_entry(_camera_fov(-12.0, 0.3), 0.0, 0.3, 1)
	combo.add_entry(_freeze(0.05), 0.03, 0.05, 2)
	return combo

static func recipe_ui_confirm() -> GFFCombo:
	## UI confirm (target = Control): press punch + flash + joy haptic tick.
	var combo := GFFCombo.new()
	combo.label = "recipe_ui_confirm"
	combo.add_entry(_punch_scale(Vector3(-0.15, -0.15, 0.0), 0.12), 0.0, 0.12, 0)
	combo.add_entry(_flash(Color.WHITE, 0.05), 0.0, 0.05, 1)
	var haptics := GFFHapticsScript.new()
	haptics.haptic_mode = &"joy"
	haptics.weak = 0.3
	haptics.strong = 0.5
	haptics.duration = 0.1
	combo.add_entry(haptics, 0.0, 0.1, 2)
	return combo

# ===== Effect builders (preload-based, headless safe) =====

static func _flicker(color: Color, rate: float) -> GFFEffect:
	var e := GFFFlickerScript.new()
	e.flicker_mode = GFFFlickerScript.FlickerMode.COLOR
	e.flicker_color = color
	e.rate_hz = rate
	return e

static func _freeze(dur: float) -> GFFEffect:
	var e := GFFFreezeFrameScript.new()
	e.duration = dur
	return e

static func _floating_text(text: String, color: Color) -> GFFEffect:
	var e := GFFFloatingTextScript.new()
	e.text = text
	e.color = color
	e.distance = 1.2
	e.duration = 0.8
	return e

static func _shake(amplitude: Vector3, dur: float) -> GFFEffect:
	var e := GFFEffectCommonScript.new()
	var t := GFFPositionTargetScript.new()
	var tw := GFFShakeTweenerScript.new()
	tw.amplitude = amplitude.length()
	e.target = t
	e.tweener = tw
	e.duration = dur
	return e

static func _spring_scale(amount: Vector3, freq: float) -> GFFEffect:
	var e := GFFEffectCommonScript.new()
	var t := GFFScaleTargetScript.new()
	t.mode = GFFScaleTargetScript.Mode.BY_AMOUNT
	t.target_value = amount
	var tw := GFFSpringTweenerScript.new()
	tw.spring_mode = GFFSpringTweenerScript.SpringMode.PUNCH
	tw.frequency = freq
	tw.damping = 0.35
	e.target = t
	e.tweener = tw
	e.duration = 0.6
	return e

static func _camera_fov(delta_fov: float, dur: float) -> GFFEffect:
	var e := GFFEffectCommonScript.new()
	var t := GFFCameraFovTargetScript.new()
	t.mode = GFFCameraFovTargetScript.Mode.BY_AMOUNT
	t.target_value = delta_fov
	var tw := GFFSpringTweenerScript.new()
	tw.spring_mode = GFFSpringTweenerScript.SpringMode.PUNCH
	tw.frequency = 6.0
	e.target = t
	e.tweener = tw
	e.duration = dur
	return e

static func _punch_position(amount: Vector3, dur: float) -> GFFEffect:
	var e := GFFEffectCommonScript.new()
	var t := GFFPositionTargetScript.new()
	t.mode = GFFPositionTargetScript.Mode.BY_AMOUNT
	t.target_value = amount
	var tw := GFFSpringTweenerScript.new()
	tw.spring_mode = GFFSpringTweenerScript.SpringMode.PUNCH
	tw.frequency = 7.0
	e.target = t
	e.tweener = tw
	e.duration = dur
	return e

static func _punch_scale(amount: Vector3, dur: float) -> GFFEffect:
	var e := GFFEffectCommonScript.new()
	var t := GFFScaleTargetScript.new()
	t.mode = GFFScaleTargetScript.Mode.BY_AMOUNT
	t.target_value = amount
	var tw := GFFElasticTweenerScript.new()
	tw.punch_mode = GFFElasticTweenerScript.PunchMode.TO_ORIGIN
	e.target = t
	e.tweener = tw
	e.duration = dur
	return e

static func _flash(color: Color, dur: float) -> GFFEffect:
	var e := GFFEffectCommonScript.new()
	var t := GFFColorTargetScript.new()
	var tw := GFFFlashTweenerScript.new()
	tw.flash_color = color
	e.target = t
	e.tweener = tw
	e.duration = dur
	return e
