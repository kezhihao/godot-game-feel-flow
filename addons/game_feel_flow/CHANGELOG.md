# Changelog

## 2.0.0

Major feature expansion — full feedback-family coverage, subsystems, editor workflow and runtime validation.

### Added

- **Dedicated spring family** — `GFFSpringEffect` base (MOVE_TO / PUNCH, damping, frequency, punch strength) plus 12 dedicated classes: position, rotation, scale, light intensity, light color, camera FOV, camera ortho size, audio pitch, audio volume, material float, UI fill and alpha springs. Built on the new generic `GFFPropertyTarget` (any node property, `shader:` and `material:` paths).
- **Shaker upgrades** — `GFFShaker` gained `shake_frequency`, `smooth_noise` and `shake_direction`; channel payloads accept a `frequency` override.
- **Timeline sequencer** — `GFFSequencer` node + `GFFSequence`/`GFFSequenceItem` resources. Six item types (EFFECT, COMBO, CHANNEL, SIGNAL, METHOD, SOUND), tracks, seek, pause/resume, play speed, looping, play ranges and four signals.
- **Recipes** — `GFFRecipes` static factory with 9 feel-style combos (`recipe_hit`, `recipe_death`, `recipe_explosion`, `recipe_pickup`, `recipe_heal`, `recipe_landing`, `recipe_dash`, `recipe_camera_hit`, `recipe_ui_confirm`).
- **New effect families** — destination transform / rotate-around / look-at / node-state; flicker, material property, UV scroll, sprite sheet, light, environment; camera clip & ortho; audio control/pitch/bus-effect/bus; rigidbody action & collider state; spawn/destroy/pause/looper/dispatch; text & floating text, image; scene & video; haptics & post-process; channel broadcast.
- **Subsystem nodes** — `GFFSoundManager` (pooled flat + positional audio, bus routing, pitch variance), `GFFPool` (object pooling with auto-expand), `GFFHaptics`, `GFFPostProcess` (15-property Environment/CameraAttributes tweens with resource-level restore).
- **Editor preview** — every combo effect row gets a ▶ button wired to the new `GFFPlayer.preview_effect()`; categorized effect picker and per-type icons; `@icon` annotations for all component node classes.

### Fixed

- Spring effects captured state before their lazily-built target existed, leaving MOVE_TO springs unrestored (e.g. `light_color_spring`).
- `post_process` restored property values but not the original `Environment`/`CameraAttributes` resources — engine defaults (e.g. `dof_blur_amount = 0.1`) leaked after play. Now restores the resources themselves.
- `GFFSequencer` item dispatch passed `StringName` where `String` was expected, silently dropping EFFECT/COMBO items.
- `recipe_death` overlapped two writers on `scale`; the spring captured a mid-squash polluted snapshot. Restaggered.

### Validation

All additions verified in-engine against the Feel Lab bench (`tests/feel_lab/feel_lab_3d.tscn`): every effect asserts observable movement and full restoration — **final regression: all suites green, 77 effects / 24 combos registered**.

## 1.0.0

Initial release — 29 built-in effects, 15 combos, `GFFPlayer` Inspector editing, loop modes, custom easing curves, Undo/Redo integration.
