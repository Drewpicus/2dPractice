##Handles validity of definition IDs. If any entity, item, etc. definition doesn't have a
##valid namespaced ID, it will fail [method GameID.is_valid()].

extends RefCounted
class_name GameID

##The namespace used by the base game. Modded/extra content might have a different namespace
##so there won't be conflict if two sources both add something called "lightsaber" for example.
const DEFAULT_NAMESPACE: StringName = &"base"

##True if [param id] is a valid [GameID], whether or not it actually exists or refers to anything
static func is_valid(id: StringName) -> bool:
	if id.is_empty():
		return false
	
	var id_string := String(id)
	
	var parts = id_string.split(":")
	if parts.size() != 2:
		return false
	
	return _is_valid_part(parts[0]) and _is_valid_part(parts[1])

##Returns a [StringName] from [param local_id] and a namespace (default is "base") that is a valid [GameID]
static func make(local_id: StringName, default_namespace: StringName = DEFAULT_NAMESPACE) -> StringName:
	var id := StringName("%s:%s" % [default_namespace,local_id])
	
	if not is_valid(id):
		push_error("Invalid game ID: %s" % id)
		return &""
	
	return id

##False if illegal characters are used to make a [GameID]
static func _is_valid_part(part: String) -> bool:
	if part.is_empty():
		return false
	
	for character in part:
		if not (character >= "a" and character <= "z"
		or character >= "0" and character <= "9"
		or character == "_"
		or character == "-"):
			return false
	return true
