extends RefCounted
class_name RuntimeStateLoader


static func reconstruct(item_states: Array,entity_states: Array,entity_parent: Node) -> Dictionary:
	if not entity_parent:
		push_error("RuntimeStateLoader requires an Entity parent.")
		return {}

	var reconstructed_items: Array[Item] = []
	var reconstructed_entities: Array[Entity] = []

	# PASS 1A:
	# Create every Item and give it its saved runtime identity.
	for state_value in item_states:
		if not state_value is Dictionary:
			push_error("Serialized Item state must be a Dictionary.")
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

		var state := state_value as Dictionary
		var item_id := StringName(state.get("item_id", ""))
		var saved_instance_id := String(state.get("instance_id", ""))

		if not GameID.is_valid(item_id):
			push_error("Invalid saved Item ID: %s" % item_id)
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

		if saved_instance_id.is_empty():
			push_error("Serialized Item is missing an instance ID.")
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

		var definition := DefinitionRegistry.get_item(item_id)

		if not definition:
			push_error("No ItemDefinition registered for saved Item: %s" % item_id)
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

		var item := ItemFactory.build(definition)

		if not item:
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

		if not item.restore_instance_id(saved_instance_id):
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

		reconstructed_items.append(item)

	# PASS 1B:
	# Create every Entity, put it in the tree, and give it its
	# saved runtime identity.
	for state_value in entity_states:
		if not state_value is Dictionary:
			push_error("Serialized Entity state must be a Dictionary.")
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

		var state := state_value as Dictionary
		var entity_id := StringName(state.get("entity_id", ""))
		var saved_instance_id := String(state.get("instance_id", ""))

		if not GameID.is_valid(entity_id):
			push_error("Invalid saved Entity ID: %s" % entity_id)
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

		if saved_instance_id.is_empty():
			push_error("Serialized Entity is missing an instance ID.")
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

		var definition := DefinitionRegistry.get_entity(entity_id)

		if not definition:
			push_error("No EntityDefinition registered for saved Entity: %s" % entity_id)
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

		var entity := EntityFactory.build(definition)

		if not entity:
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

		entity_parent.add_child(entity)

		if not entity.restore_instance_id(saved_instance_id):
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

		reconstructed_entities.append(entity)

	# PASS 2A:
	# All runtime objects now exist and are registered,
	# so Item components may safely resolve object references.
	for index in range(reconstructed_items.size()):
		var item := reconstructed_items[index]
		var state := item_states[index] as Dictionary

		if not item.deserialize_state(state):
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

	# PASS 2B:
	# Entity components can now safely resolve references too.
	for index in range(reconstructed_entities.size()):
		var entity := reconstructed_entities[index]
		var state := entity_states[index] as Dictionary

		if not entity.deserialize_state(state):
			_cleanup(reconstructed_items, reconstructed_entities)
			return {}

	return {"items": reconstructed_items, "entities": reconstructed_entities}


static func _cleanup(items: Array[Item], entities: Array[Entity]) -> void:
	for item in items:
		if item:
			RuntimeObjectRegistry.unregister(item.instance_id, item)

	for entity in entities:
		if entity:
			RuntimeObjectRegistry.unregister(entity.instance_id, entity)

			entity.queue_free()
