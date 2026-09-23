extends RefCounted
class_name GameResolution

var resolution_id: StringName
var resolved: bool = false
var cancelled: bool = false

var _modifiers: Array[ResolutionModifier] = []
var _next_submission_order: int = 0
var _applying_modifiers: bool = false

func cancel() -> void:
	cancelled = true

func add_modifier(modifier: ResolutionModifier,source: Object = null) -> bool:
	if not modifier:
		return false

	if _applying_modifiers:
		push_error("Cannot add a ResolutionModifier while modifiers are being applied.")
		return false

	modifier.source = source
	modifier._submission_order = _next_submission_order
	_next_submission_order += 1

	_modifiers.append(modifier)
	return true

func apply_modifiers() -> void:
	_modifiers.sort_custom(_sort_modifiers)

	_applying_modifiers = true

	for modifier in _modifiers:
		modifier.apply(self)

	_applying_modifiers = false
	resolved = true


func _sort_modifiers(a: ResolutionModifier,b: ResolutionModifier) -> bool:
	if a.priority == b.priority:
		return a._submission_order < b._submission_order

	return a.priority < b.priority
