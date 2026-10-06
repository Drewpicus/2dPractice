##

extends RefCounted
class_name ResolutionModifier

enum PRIORITY_STAGE {
	FIRST = 0,
	EARLY_TRANSFORMATION = 100,
	ADDITION_SUBTRACTION = 200,
	MULTIPLICATION = 300,
	MIN_MAX_CLAMP = 400,
	PERMISSION = 500,
	FINAL_OVERRIDE = 600
}

## Lower priorities are applied earlier.
##100  Early transformations/replacements
##200  Flat additions/subtractions
##300  Multipliers
##400  Minimums, maximums, clamps
##500  Permission / blocking
##600  Special case absolute final overrides
var priority: int = 0
var source: Object
var submission_order: int = -1

## What this modifier does to a resolution.
func apply(_resolution: GameResolution) -> void:
	pass
