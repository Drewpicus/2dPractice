extends RefCounted
class_name SaveManager

const SAVE_VERSION: int = 1
const DEFAULT_SAVE_PATH: String = "user://save.json"


static func save_world(world: GameWorld, path: String = DEFAULT_SAVE_PATH) -> bool:
	if not world:
		return false

	var save_data := {"version": SAVE_VERSION, "world": world.serialize_state()}

	var file := FileAccess.open(path, FileAccess.WRITE)

	if not file:
		push_error("Could not open save file for writing: %s" % path)
		return false

	file.store_string(
		JSON.stringify(save_data, "\t")
	)

	return true


static func load_world(world: GameWorld, path: String = DEFAULT_SAVE_PATH) -> bool:
	if not world:
		return false

	if not FileAccess.file_exists(path):
		push_error("Save file does not exist: %s" % path)
		return false

	var text := FileAccess.get_file_as_string(path)

	var json := JSON.new()
	var error := json.parse(text)

	if error != OK:
		push_error(
			"Failed to parse save file at line %s: %s"
			% [
				json.get_error_line(),
				json.get_error_message()
			]
		)
		return false

	if not json.data is Dictionary:
		push_error("Save file root must be an object.")
		return false

	var save_data := json.data as Dictionary

	var version := int(save_data.get("version", -1))

	if version != SAVE_VERSION:
		push_error(
			"Unsupported save version: %s"
			% version
		)
		return false

	var world_state = save_data.get("world", {})

	if not world_state is Dictionary:
		push_error("Save file world state must be an object.")
		return false

	return world.deserialize_state(world_state)
