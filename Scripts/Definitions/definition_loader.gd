extends RefCounted
class_name DefinitionLoader

static func load_item_definition(path: String) -> ItemDefinition:
	var data := _load_json(path)

	if data.is_empty():
		return null

	var definition := ItemDefinition.new()

	definition.item_id = StringName(data.get("item_id", ""))

	if not GameID.is_valid(definition.item_id):
		push_error("Invalid item ID in definition %s: %s" % [path, definition.item_id])
		return null

	definition.item_name = String(data.get("item_name", ""))

	var sprite_path := String(data.get("sprite", ""))

	if not sprite_path.is_empty():
		var sprite_resource := load(sprite_path)

		if not sprite_resource is Texture2D:
			push_error("Item definition sprite is not a Texture2D: %s" % sprite_path)
			return null

		definition.sprite = sprite_resource as Texture2D

	var component_data = data.get("components", [])

	if not component_data is Array:
		push_error("Item definition components must be an Array: %s" % path)
		return null

	for component_value in component_data:
		if not component_value is Dictionary:
			push_error("Invalid component entry in item definition: %s" % path)
			return null

		var component_dictionary := component_value as Dictionary
		var component_definition := ItemComponentDefinition.new()

		component_definition.component_id = StringName(component_dictionary.get("component_id", ""))

		if not GameID.is_valid(component_definition.component_id):
			push_error("Invalid ItemComponent ID in %s: %s" % [path, component_definition.component_id])
			return null

		var parameters = component_dictionary.get("parameters", {})

		if not parameters is Dictionary:
			push_error("Component parameters must be a Dictionary in: %s" % path)
			return null

		component_definition.parameters = parameters
		definition.components.append(component_definition)

	return definition


static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Definition file does not exist: %s" % path)
		return {}

	var text := FileAccess.get_file_as_string(path)

	var json := JSON.new()
	var error := json.parse(text)

	if error != OK:
		push_error("Failed to parse JSON %s at line %s: %s" % [path,json.get_error_line(),json.get_error_message()])
		return {}

	if not json.data is Dictionary:
		push_error("Definition JSON root must be an object: %s" % path)
		return {}

	return json.data as Dictionary
