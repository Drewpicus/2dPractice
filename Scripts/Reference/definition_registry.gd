extends RefCounted
class_name DefinitionRegistry

static var _entity_definitions: Dictionary[StringName, EntityDefinition] = {}
static var _item_definitions: Dictionary[StringName, ItemDefinition] = {}


static func register_entity(definition: EntityDefinition) -> bool:
	if not definition:
		return false

	if not GameID.is_valid(definition.entity_id):
		push_error("Cannot register EntityDefinition with invalid ID: %s" % definition.entity_id)
		return false

	if _entity_definitions.has(definition.entity_id):
		push_error("EntityDefinition ID already registered: %s" % definition.entity_id)
		return false

	_entity_definitions[definition.entity_id] = definition
	return true


static func register_item(definition: ItemDefinition) -> bool:
	if not definition:
		return false

	if not GameID.is_valid(definition.item_id):
		push_error("Cannot register ItemDefinition with invalid ID: %s"% definition.item_id)
		return false

	if _item_definitions.has(definition.item_id):
		push_error("ItemDefinition ID already registered: %s" % definition.item_id)
		return false

	_item_definitions[definition.item_id] = definition
	return true


static func get_entity(entity_id: StringName) -> EntityDefinition:
	return _entity_definitions.get(entity_id)


static func get_item(item_id: StringName) -> ItemDefinition:
	return _item_definitions.get(item_id)


static func has_entity(entity_id: StringName) -> bool:
	return _entity_definitions.has(entity_id)


static func has_item(item_id: StringName) -> bool:
	return _item_definitions.has(item_id)


static func clear() -> void:
	_entity_definitions.clear()
	_item_definitions.clear()
