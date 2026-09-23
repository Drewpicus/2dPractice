extends RefCounted
class_name ResolutionModifier

## Lower priorities are applied earlier.
var priority: int = 0
var source: Object
var _submission_order: int = -1

## What this modifier does to a resolution.
func apply(_resolution: GameResolution) -> void:
	pass
