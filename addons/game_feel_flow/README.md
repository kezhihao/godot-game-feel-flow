# Game Feel Flow

One-stop game feel (juice) system for Godot — 77 composable effects, 24 ready-made combos, a dedicated spring family, shakers, a timeline sequencer, channel/event messaging and a full Inspector workflow.

[![Godot Engine](https://img.shields.io/badge/Godot%20Engine-4.4+-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Docs](https://img.shields.io/badge/Docs-Online-blue)](https://indieshade.github.io/godot-plugin-game-feel-flow/)

> This file ships inside `addons/game_feel_flow/` so Asset Library installs always keep the license and docs entry points with the plugin.

## Enable

1. Open **Project → Project Settings → Plugins**
2. Enable **Game Feel Flow**

The plugin registers a `GameFeelFlow` autoload singleton and a `GFFPlayer` Inspector extension automatically.

## Quick start

```gdscript
# Method 1: GFUtil shortcuts (fastest)
GFUtil.hit(self, 2.0)
GFUtil.death(self)
GFUtil.pickup(self)

# Method 2: GameFeelFlow singleton — play any registered effect or combo
GameFeelFlow.play("squash_stretch", self)
GameFeelFlow.play_combo("recipe_hit", self, {"intensity": 2.0})

# Method 3: GFFPlayer node — author combos in the Inspector, preview each effect
$GFFPlayer.play("hit", {"intensity": 2.0})
$GFFPlayer.preview_effect(my_effect)   # single-effect preview (Inspector ▶ button path)
```

## Feature highlights

- **77 registered effects** — transform, springs, rendering/material, camera, audio, physics, lifecycle/logic, UI/text, scene/media
- **24 combos** — 15 classic presets (hits, deaths, pickups, explosions, UI) + 9 feel-style recipes (`recipe_hit`, `recipe_death`, `recipe_pickup`, `recipe_camera_hit`, …)
- **Dedicated spring family** — damped-oscillator MOVE_TO / PUNCH springs for position, rotation, scale, light intensity & color, camera FOV & ortho size, audio pitch & volume, material floats, UI fill and alpha
- **Shakers** — position/rotation/scale shake components with smooth-noise, frequency control and directional shake
- **GFFSequencer** — timeline sequencer driving effects, combos, channel broadcasts, signals, methods and sounds with seek/pause/loop
- **Channel system** — broadcast/receiver event bus (`GFFChannelBus`, `GFFChannelReceiver`) for decoupled feedback
- **Editor tooling** — per-effect ▶ preview buttons on every combo row, categorized effect picker, per-type icons
- **Utility nodes** — `GFFPool` (object pooling), `GFFSoundManager` (pooled audio with bus routing & pitch variance), `GFFSpringComponent`
- **Subsystem effects** — `haptics` (controller/device vibration) and `post_process` (15-property WorldEnvironment + camera attribute tweens)

## Effect catalog

| Family | Keys |
|---|---|
| Shake / punch / curved | `shake_position`, `shake_scale`, `shake_rotation`, `punch_position`, `punch_scale`, `punch_rotation`, `curved_position`, `curved_scale`, `curved_rotation` |
| Springs | `spring_scale`, `spring_position`, `spring_rotation`, `light_intensity_spring`, `light_color_spring`, `camera_fov_spring`, `camera_ortho_spring`, `audio_pitch_spring`, `audio_volume_spring`, `material_float_spring`, `ui_fill_spring`, `alpha_spring` |
| Transform | `squash_stretch`, `wiggle_position`, `wiggle_rotation`, `destination_transform`, `rotate_around`, `look_at`, `node_state` |
| Rendering / material | `flicker`, `material_property`, `uv_scroll`, `sprite_sheet`, `light`, `environment`, `flash`, `color`, `alpha`, `camera_flash`, `post_process` |
| Camera | `camera_shake`, `camera_zoom`, `camera_fov`, `camera_clip`, `camera_ortho` |
| Audio | `sound`, `audio_volume`, `audio_control`, `audio_pitch`, `audio_bus_effect`, `audio_bus` |
| Physics | `impulse`, `velocity`, `rigidbody_action`, `collider_state` |
| Lifecycle / logic | `spawn`, `destroy`, `pause`, `looper`, `dispatch`, `event`, `signal`, `method`, `tween`, `animator`, `channel_broadcast` |
| UI / text / media | `text`, `floating_text`, `image`, `scene`, `video`, `haptics`, `freeze_frame`, `time_scale`, `particles`, `gpu_particles` |

List everything at runtime with `GameFeelFlow.get_effect_names()`.

## Node components

| Node | Purpose |
|---|---|
| `GFFPlayer` | Inspector-authored combo player; per-effect preview via `preview_effect()` |
| `GFFShaker` | Continuous/triggered shake on a node (smooth noise, frequency, direction) |
| `GFFSpringComponent` | Always-on spring on a node property, driven by channels |
| `GFFChannelReceiver` | Listens on a channel/event and plays an effect on its target |
| `GFFSequencer` | Plays a `GFFSequence` timeline (EFFECT/COMBO/CHANNEL/SIGNAL/METHOD/SOUND items) |
| `GFFPool` | Node pool with auto-expand, visibility toggling, `return_all()` |
| `GFFSoundManager` | Pooled flat + positional audio players, bus routing, pitch variance |

## Editor workflow

- Select a `GFFPlayer` to edit its combos directly in the Inspector: add rows, pick effects from the categorized picker, reorder, tune timing.
- Every effect row has a ▶ button that plays just that effect on the player's target — no scene run required.
- Combo-level Play/Stop buttons run the whole sequence.
- All effect types resolve a themed icon automatically (`gff_<name>.gd` → `icon_<name>.svg`).

## Try these scenes first

1. `examples/showcase.tscn` — Free reel (**16:9**)
2. `examples/onboarding.tscn` — GFFPlayer + combos walkthrough
3. `examples/effect_library.tscn` — Full effect catalog / lab
4. `examples/demo_combo_workflow.tscn` — combo authoring workflow
5. `examples/main_2d.tscn` / `examples/main_3d.tscn` — integration demos

## Validation

The project ships a headless-runnable validation bench (`tests/feel_lab/feel_lab_3d.tscn` inside the source repository — not part of the addon) that plays every subsystem against live nodes and asserts both *movement* and *full restoration*. Current regression: **all suites green** across springs, shakers, channels, sequencer, recipes, pooling, audio, physics, UI and editor preview paths.

## Documentation & source

- Repository: https://github.com/kezhihao/godot-game-feel-flow
- Upstream project (MIT): https://github.com/IndieShade/godot-plugin-game-feel-flow
- Original docs: https://indieshade.github.io/godot-plugin-game-feel-flow/
- Pro extension: https://indieshade.itch.io/game-feel-flow-pro

## License

MIT License — see [LICENSE](LICENSE).
