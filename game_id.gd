extends RefCounted
class_name GameID

const DEFAULT_NAMESPACE: StringName = &"base"

static func is_valid(id: StringName) -> bool:
	if id.is_empty():
		return false
	
	var id_string := String(id)
	
	var parts = id_string.split(":")
	if parts.size() != 2:
		return false
	
	return _is_valid_part(parts[0]) and _is_valid_part(parts[1])

static func make(local_id: StringName, default_namespace: StringName = DEFAULT_NAMESPACE) -> StringName:
	var id := StringName("%s:%s" % [default_namespace,local_id])
	
	if not is_valid(id):
		push_error("Invalid game ID: %s" % id)
		return &""
	
	return id

static func _is_valid_part(part: String) -> bool:
	if part.is_empty():
		return false
	
	for char in part:
		if not (char >= "a" and char <= "z"
		or char >= "0" and char <= "9"
		or char == "_"
		or char == "-"):
			return false
	return true
