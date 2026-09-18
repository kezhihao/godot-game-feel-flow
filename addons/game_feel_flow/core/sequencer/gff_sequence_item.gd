@tool
class_name GFFSequenceItem
extends Resource

## Game Feel Flow Sequence Item
##
## One timed entry on a GFFSequence timeline — the Godot counterpart of
## Feel's MMSequenceTrack items. When the sequencer's playhead crosses
## [member start_time] the item fires once (or spans over [member duration]).
##
## Types:
##   EFFECT   — play a registered effect by name on a target node
##   COMBO    — play a registered combo by name on a target node
##   CHANNEL  — broadcast an event on a channel (GF-02 bus)
##   SIGNAL   — emit the sequencer's item_signal with this item's id
##   METHOD   — call a method on the target node
##   SOUND    — play an AudioStream (flat or positional via target)

enum ItemType { EFFECT, COMBO, CHANNEL, SIGNAL, METHOD, SOUND }

@export var id: String = ""
@export var start_time: float = 0.0
## 0 = instant trigger. >0 spans the item: effect params get this duration.
@export var duration: float = 0.0
@export var track_idx: int = 0
@export var item_type: ItemType = ItemType.SIGNAL

@export_group("Payload")
## Registered effect/combo name (EFFECT/COMBO), event name (CHANNEL),
## or method name (METHOD). id is used for SIGNAL items.
@export var name_key: StringName = &""
@export var channel: int = -1
@export var params: Dictionary = {}
## Target override: resolved against the sequencer node (or the scene when
## the sequencer is not in the tree). Empty = sequencer's default_target.
@export var target_path: NodePath = NodePath("")
## AudioStream to play for SOUND items.
@export var stream: AudioStream = null

@export var debug_enabled: bool = false
