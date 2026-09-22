extends RefCounted
class_name GameResolution

var resolution_id: StringName
var cancelled: bool = false


func cancel() -> void:
	cancelled = true
