extends RefCounted
class_name DefinitionRegistry

static var _entity_definitions: Dictionary[StringName, EntityDefinition] = {}
static var _item_definitions: Dictionary[StringName, ItemDefinition] = {}
static var _element_definitions: Dictionary[StringName, ElementDefinition] = {}
static var _weapontype_definitions: Dictionary[StringName, WeaponTypeDefinition] = {}
static var _faction_definitions: Dictionary[StringName, FactionDefinition] = {}

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

static func register_element(definition: ElementDefinition) -> bool:
	if not definition:
		return false

	if not GameID.is_valid(definition.element_id):
		push_error("Cannot register ElementDefinition with invalid ID: %s" % definition.element_id)
		return false

	if _element_definitions.has(definition.element_id):
		push_error("ElementDefinition ID already registered: %s" % definition.element_id)
		return false

	_element_definitions[definition.element_id] = definition
	return true

static func register_weapontype(definition: WeaponTypeDefinition) -> bool:
	if not definition:
		return false

	if not GameID.is_valid(definition.weapontype_id):
		push_error("Cannot register WeaponTypeDefinition with invalid ID: %s" % definition.weapontype_id)
		return false

	if _weapontype_definitions.has(definition.weapontype_id):
		push_error("WeaponTypeDefinition ID already registered: %s" % definition.weapontype_id)
		return false

	_weapontype_definitions[definition.weapontype_id] = definition
	return true

static func register_faction(
	definition: FactionDefinition
) -> bool:
	if not definition:
		return false

	if not GameID.is_valid(
		definition.faction_id
	):
		return false

	if _faction_definitions.has(
		definition.faction_id
	):
		push_error(
			"FactionDefinition ID already registered: %s"
			% definition.faction_id
		)
		return false

	_faction_definitions[
		definition.faction_id
	] = definition

	return true



static func get_entity(entity_id: StringName) -> EntityDefinition:
	return _entity_definitions.get(entity_id)

static func get_item(item_id: StringName) -> ItemDefinition:
	return _item_definitions.get(item_id)

static func get_element(element_id: StringName) -> ElementDefinition:
	return _element_definitions.get(element_id)

static func get_weapontype(weapontype_id: StringName) -> WeaponTypeDefinition:
	return _weapontype_definitions.get(weapontype_id)

static func get_faction(
	faction_id: StringName
) -> FactionDefinition:
	return _faction_definitions.get(
		faction_id
	)

static func has_entity(entity_id: StringName) -> bool:
	return _entity_definitions.has(entity_id)

static func has_item(item_id: StringName) -> bool:
	return _item_definitions.has(item_id)

static func has_element(element_id: StringName) -> bool:
	return _element_definitions.has(element_id)
	
static func has_weapontype(weapontype_id: StringName) -> bool:
	return _weapontype_definitions.has(weapontype_id)

static func has_faction(
	faction_id: StringName
) -> bool:
	return _faction_definitions.has(
		faction_id
	)

static func clear() -> void:
	_entity_definitions.clear()
	_item_definitions.clear()
	_element_definitions.clear()
	_weapontype_definitions.clear()
	_faction_definitions.clear()
