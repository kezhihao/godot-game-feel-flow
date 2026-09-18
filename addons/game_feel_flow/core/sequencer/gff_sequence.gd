@tool
class_name GFFSequence
extends Resource

## Game Feel Flow Sequence
##
## A timeline resource: an ordered list of GFFSequenceItem entries plus an
## optional explicit [member duration]. Equivalent of Feel's MMSequence.
## Edit items directly in the Inspector (array of resources), or build
## sequences in code.

@export var items: Array[GFFSequenceItem] = []
## Total timeline length. 0 = auto-computed from items (max start+duration).
@export var duration: float = 0.0
## Optional label for debugging / tooling.
@export var display_name: String = ""

func get_duration() -> float:
	if duration > 0.0:
		return duration
	var end_t: float = 0.0
	for it: GFFSequenceItem in items:
		if it == null:
			continue
		end_t = maxf(end_t, it.start_time + it.duration)
	return end_t

func get_sorted_items() -> Array[GFFSequenceItem]:
	var out: Array[GFFSequenceItem] = []
	for it: GFFSequenceItem in items:
		if it != null:
			out.append(it)
	out.sort_custom(func(a: GFFSequenceItem, b: GFFSequenceItem) -> bool: return a.start_time < b.start_time)
	return out

func items_at(track_idx: int) -> Array[GFFSequenceItem]:
	var out: Array[GFFSequenceItem] = []
	for it: GFFSequenceItem in items:
		if it != null and it.track_idx == track_idx:
			out.append(it)
	return out

func track_count() -> int:
	var n: int = 0
	for it: GFFSequenceItem in items:
		if it != null:
			n = maxi(n, it.track_idx + 1)
	return n
