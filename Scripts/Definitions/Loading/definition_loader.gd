extends RefCounted
class_name DefinitionLoader

const ITEM_DIRECTORY := "res://Data/Items"
const ENTITY_DIRECTORY := "res://Data/Entities"
const ELEMENT_DIRECTORY := "res://Data/Elements"
const WEAPONTYPE_DIRECTORY := "res://Data/WeaponTypes"
const FACTION_DIRECTORY := "res://Data/Factions"

##Builds the entire [DefinitionRegistry]
static func load_all_definitions() -> void:
	DefinitionRegistry.clear()

	_load_named_directory(ITEM_DIRECTORY,"item")
	_load_named_directory(ENTITY_DIRECTORY,"entity")
	_load_named_directory(ELEMENT_DIRECTORY,"element")
	_load_named_directory(WEAPONTYPE_DIRECTORY,"weapontype")

##Loads the directory from the [param directory_path] and registers all the files in the
##[DefinitionRegistry]. [param directory_name] is a [String] like "entity" or "weapontype"
static func _load_named_directory(directory_path: String, directory_name: String) -> void:
	var files := DirAccess.get_files_at(directory_path)
	files.sort()

	for file_name in files:
		if not file_name.ends_with(".json"):
			continue

		var path := directory_path.path_join(file_name)
		
		var load_definition_callable: Callable = Callable(DefinitionLoader, "load_" + directory_name + "_definition").bind(path)
		
		if not load_definition_callable.is_valid():
			push_error("Invalid directory name for definition loading: %s" % directory_name)
			return
		
		var definition = load_definition_callable.call()

		if definition:
			
			var register_callable: Callable = Callable(DefinitionRegistry, "register_" + directory_name).bind(definition)
			if not register_callable.is_valid():
				push_error("Invalid directory name for registration: %s" % directory_name)
				return
				
			register_callable.call()

static func load_entity_definition(path: String) -> EntityDefinition:
	var data := _load_json(path)

	if data.is_empty():
		return null

	var definition := EntityDefinition.new()

	definition.entity_id = StringName(data.get("entity_id", ""))

	if not GameID.is_valid(definition.entity_id):
		push_error(
			"Invalid entity ID in definition %s: %s" % [path, definition.entity_id])
		return null

	definition.entity_name = String(data.get("entity_name", ""))
	definition.solid = bool(data.get("solid", true))
	definition.draw_layer = int(data.get("draw_layer", 0))

	var sprite_path := String(data.get("sprite", ""))

	if not sprite_path.is_empty():
		var sprite_resource := load(sprite_path)

		if not sprite_resource is Texture2D:
			push_error(
				"Entity definition sprite is not a Texture2D: %s" % sprite_path)
			return null

		definition.sprite = sprite_resource as Texture2D

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
	
	definition.description = String(data.get("description", ""))
	
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

static func load_element_definition(path: String) -> ElementDefinition:
	var data := _load_json(path)

	if data.is_empty():
		return null

	var definition := ElementDefinition.new()

	definition.element_id = StringName(data.get("element_id", ""))

	if not GameID.is_valid(definition.element_id):
		push_error("Invalid element ID in definition %s: %s" % [path, definition.element_id])
		return null

	definition.element_name = String(data.get("element_name", ""))

	return definition

static func load_weapontype_definition(path: String) -> WeaponTypeDefinition:
	var data := _load_json(path)

	if data.is_empty():
		return null

	var definition := WeaponTypeDefinition.new()

	definition.weapontype_id = StringName(data.get("weapontype_id", ""))

	if not GameID.is_valid(definition.weapontype_id):
		push_error("Invalid weapontype ID in definition %s: %s" % [path, definition.weapontype_id])
		return null

	definition.weapontype_name = String(data.get("weapontype_name", ""))

	return definition

static func load_faction_definition(
	path: String
) -> FactionDefinition:
	var data := _load_json(
		path
	)

	if data.is_empty():
		return null

	var definition := FactionDefinition.new()

	definition.faction_id = StringName(
		data.get(
			"faction_id",
			""
		)
	)

	if not GameID.is_valid(
		definition.faction_id
	):
		push_error(
			"Invalid faction ID in definition %s: %s"
			% [
				path,
				definition.faction_id
			]
		)
		return null

	definition.faction_name = String(
		data.get(
			"faction_name",
			""
		)
	)

	var relation_data = data.get(
		"default_relations",
		{}
	)

	if not relation_data is Dictionary:
		push_error(
			"Faction relations must be a Dictionary: %s"
			% path
		)
		return null

	for target_key in relation_data:
		var target_id := StringName(
			target_key
		)

		if not GameID.is_valid(
			target_id
		):
			push_error(
				"Invalid faction relation ID in %s: %s"
				% [
					path,
					target_id
				]
			)
			return null

		definition.default_relations[
			target_id
		] = int(
			relation_data[target_key]
		)

	return definition

##Returns a [Dictionary] from a JSON file at [param path]
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

##The Variant [param data] must be a Dictionary with a type and data, for example:
##[codeblock]
##{
##	"type" : "circle",
##	"radius" : 16.0
##}[/codeblock]
static func _load_collision_shape(data: Variant, definition_path: String) -> Shape2D:
	if not data is Dictionary:
		push_error("Collision definition must be an object in: %s" % definition_path)
		return null

	var collision := data as Dictionary
	var shape_type := String(collision.get("type", ""))

	match shape_type:
		"circle":
			var radius := float(collision.get("radius", 0.0))

			if radius <= 0.0:
				push_error("Circle collision radius must be greater than 0 in: %s" % definition_path)
				return null

			var shape := CircleShape2D.new()
			shape.radius = radius
			return shape

		"rectangle":
			var size_data = collision.get("size", [])

			if not size_data is Array or size_data.size() != 2:
				push_error("Rectangle collision size must be [width, height] in: %s" % definition_path)
				return null

			var shape := RectangleShape2D.new()
			shape.size = Vector2(float(size_data[0]),float(size_data[1]))
			return shape

		"capsule":
			var radius := float(collision.get("radius", 0.0))
			var height := float(collision.get("height", 0.0))

			if radius <= 0.0 or height <= 0.0:
				push_error("Capsule collision dimensions must be greater than 0 in: %s" % definition_path)
				return null

			var shape := CapsuleShape2D.new()
			shape.radius = radius
			shape.height = height
			return shape

		_:
			push_error("Unknown collision type '%s' in: %s" % [shape_type, definition_path])
			return null
