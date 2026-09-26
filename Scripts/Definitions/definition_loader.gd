extends RefCounted
class_name DefinitionLoader

const ITEM_DIRECTORY := "res://Data/Items"
const ENTITY_DIRECTORY := "res://Data/Entities"


static func load_all_definitions() -> void:
	DefinitionRegistry.clear()

	_load_item_directory(ITEM_DIRECTORY)
	_load_entity_directory(ENTITY_DIRECTORY)


static func _load_item_directory(directory_path: String) -> void:
	var files := DirAccess.get_files_at(directory_path)
	files.sort()

	for file_name in files:
		if not file_name.ends_with(".json"):
			continue

		var path := directory_path.path_join(file_name)
		var definition := load_item_definition(path)

		if definition:
			DefinitionRegistry.register_item(definition)


static func _load_entity_directory(directory_path: String) -> void:
	var files := DirAccess.get_files_at(directory_path)
	files.sort()

	for file_name in files:
		if not file_name.ends_with(".json"):
			continue

		var path := directory_path.path_join(file_name)
		var definition := load_entity_definition(path)

		if definition:
			DefinitionRegistry.register_entity(definition)

static func load_entity_definition(path: String) -> EntityDefinition:
	var data := _load_json(path)

	if data.is_empty():
		return null

	var definition := EntityDefinition.new()

	definition.entity_id = StringName(data.get("entity_id", ""))

	if not GameID.is_valid(definition.entity_id):
		push_error(
			"Invalid entity ID in definition %s: %s"
			% [path, definition.entity_id]
		)
		return null

	definition.entity_name = String(data.get("entity_name", ""))
	definition.solid = bool(data.get("solid", true))

	var sprite_path := String(data.get("sprite", ""))

	if not sprite_path.is_empty():
		var sprite_resource := load(sprite_path)

		if not sprite_resource is Texture2D:
			push_error(
				"Entity definition sprite is not a Texture2D: %s"
				% sprite_path
			)
			return null

		definition.sprite = sprite_resource as Texture2D
		
		definition.sprite_orientation = StringName(data.get("sprite_orientation", ""))

	if data.has("collision"):
		definition.collision_shape = _load_collision_shape(data["collision"], path)

		if not definition.collision_shape:
			return null

	var component_data = data.get("components", [])

	if not component_data is Array:
		push_error("Entity definition components must be an Array: %s" % path)
		return null

	for component_value in component_data:
		if not component_value is Dictionary:
			push_error("Invalid component entry in entity definition: %s" % path)
			return null

		var component_dictionary := component_value as Dictionary
		var component_definition := EntityComponentDefinition.new()

		component_definition.component_id = StringName(
			component_dictionary.get("component_id", "")
		)

		if not GameID.is_valid(component_definition.component_id):
			push_error("Invalid EntityComponent ID in %s: %s" % [path, component_definition.component_id])
			return null

		var parameters = component_dictionary.get("parameters", {})

		if not parameters is Dictionary:
			push_error("Component parameters must be a Dictionary in: %s" % path)
			return null

		component_definition.parameters = parameters
		definition.components.append(component_definition)

	return definition

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

static func _load_collision_shape(data: Variant, definition_path: String) -> Shape3D:
	if not data is Dictionary:
		push_error("Collision definition must be an object in: %s" % definition_path)
		return null

	var collision := data as Dictionary
	var shape_type := String(collision.get("type", ""))

	match shape_type:
		"sphere":
			var radius := float(collision.get("radius", 0.0))

			if radius <= 0.0:
				push_error("Sphere collision radius must be greater than 0 in: %s" % definition_path)
				return null

			var shape := SphereShape3D.new()
			shape.radius = radius
			return shape

		"box":
			var size_data = collision.get("size", [])

			if not size_data is Array or size_data.size() != 3:
				push_error("Box collision size must be [width, height, depth] in: %s" % definition_path)
				return null

			var shape := BoxShape3D.new()
			shape.size = Vector3(float(size_data[0]), float(size_data[1]), float(size_data[2]))
			return shape

		"capsule":
			var radius := float(collision.get("radius", 0.0))
			var height := float(collision.get("height", 0.0))

			if radius <= 0.0 or height <= 0.0:
				push_error("Capsule collision dimensions must be greater than 0 in: %s" % definition_path)
				return null

			var shape := CapsuleShape3D.new()
			shape.radius = radius
			shape.height = height
			return shape

		"cylinder":
			var radius := float(collision.get("radius", 0.0))
			var height := float(collision.get("height", 0.0))

			if radius <= 0.0 or height <= 0.0:
				push_error("Cylinder collision dimensions must be greater than 0 in: %s" % definition_path)
				return null

			var shape := CylinderShape3D.new()
			shape.radius = radius
			shape.height = height
			return shape

		_:
			push_error("Unknown collision type '%s' in: %s" % [shape_type, definition_path])
			return null
