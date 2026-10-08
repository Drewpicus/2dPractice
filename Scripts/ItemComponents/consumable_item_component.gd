extends ItemComponent
class_name ConsumableItemComponent

##Immediate healing upon consumption
@export var healing: float = 0.0

##Status effects applied when consumed.
##e.g.: [codeblock]
##{
##    "effect_id": "base:burning",
##    "duration_ticks": 5
##}[/codeblock]
@export var status_effects: Array = []

##EntityComponents  added to the consumer.
##e.g.: [codeblock]
##{
##    "component_id": "base:fire_resistant",
##    "parameters": {}
##}[/codeblock]
@export var entity_components_to_add: Array = []

##EntityComponent IDs removed from the consumer.
@export var entity_components_to_remove: Array = []

##Item created after this Item is consumed, e.g. an empty bottle.
##Empty means nothing remains.
@export var remainder_item_id: StringName = &""

##If true, the consumer must have less than maximum health.
@export var require_missing_health: bool = false

##Capabilities the consumer must possess to consume the item, e.g. geophagy.
@export var required_capabilities: Array = []


func _init() -> void:
	component_id = &"base:consumable"


func can_consume(consumer: Entity) -> bool:
	if not consumer:
		return false

	if not root_item:
		return false

	var inventory := consumer.get_component(&"base:inventory") as InventoryComponent

	if not inventory:
		return false

	if root_item not in inventory.items:
		return false

	if require_missing_health:
		var health := consumer.get_component(&"base:health") as HealthComponent

		if not health:
			return false

		if health.is_full_health():
			return false

	if not required_capabilities.is_empty():
		var capabilities := consumer.get_component(&"base:capability") as CapabilityComponent

		if not capabilities:
			return false

		for capability_value in required_capabilities:
			var capability_id := StringName(capability_value)

			if not capabilities.has_capability(capability_id):
				return false

	if not _configuration_is_valid():
		return false

	return true


func apply_to(consumer: Entity) -> bool:
	if not can_consume(consumer):
		return false

	var prepared_effects: Array = []

	var status := consumer.get_component(&"base:status") as StatusComponent

	if not status_effects.is_empty():

		if not status:
			return false

		for effect_value in status_effects:
			var effect_data := effect_value as Dictionary

			var effect_id := StringName(
				effect_data.get("effect_id", ""))

			var effect := StatusEffectRegistry.create_effect(effect_id)

			if not effect:
				return false

			prepared_effects.append({
				"effect": effect,
				"duration_ticks": float(
					effect_data.get(
						"duration_ticks",
						-1.0
					)
				)
			})

	if healing > 0.0:
		HealSystem.apply_healing(consumer,consumer,healing,root_item)

	status = consumer.get_component(&"base:status") as StatusComponent

	if status:
		for prepared in prepared_effects:
			status.apply_effect(prepared["effect"], consumer, prepared["duration_ticks"])

	_apply_component_changes(consumer)

	return true


func _apply_component_changes(consumer: Entity) -> void:
	# Remove first. This intentionally allows a Consumable
	# to replace an existing component by listing the same
	# component in both arrays.
	for component_value in entity_components_to_remove:
		var component_id_to_check := StringName(component_value)

		if consumer.has_component(component_id_to_check):
			consumer.remove_component(component_id_to_check)

	for component_value in entity_components_to_add:
		var component_data := component_value as Dictionary

		var component_id_to_check := StringName(
			component_data.get("component_id", ""))

		if consumer.has_component(component_id_to_check):
			continue

		var parameters = component_data.get("parameters", {})

		consumer.add_component(component_id_to_check, parameters)


func _configuration_is_valid() -> bool:
	for effect_value in status_effects:
		if not effect_value is Dictionary:
			push_error("Consumable status effect must be a Dictionary.")
			return false

		var effect_data := effect_value as Dictionary

		var effect_id := StringName(effect_data.get("effect_id", ""))

		if not GameID.is_valid(effect_id):
			push_error("Invalid Consumable status effect ID: %s" % effect_id)
			return false

	for component_value in entity_components_to_remove:
		var component_id_to_check := StringName(component_value)

		if not GameID.is_valid(component_id):
			push_error("Invalid Consumable component removal ID: %s" % component_id_to_check)
			return false

	for component_value in entity_components_to_add:
		if not component_value is Dictionary:
			push_error(
				"Consumable component addition must be a Dictionary."
			)
			return false

		var component_data := component_value as Dictionary

		var component_id_to_check := StringName(
			component_data.get("component_id", ""))

		if not GameID.is_valid(component_id_to_check):
			push_error("Invalid Consumable component addition ID: %s" % component_id_to_check)
			return false

		if not EntityComponentRegistry.get_component_scene(component_id_to_check):
			push_error("Unregistered EntityComponent ID in Consumable: %s" % component_id_to_check)
			return false

		var parameters = component_data.get("parameters",{})

		if not parameters is Dictionary:
			push_error("Consumable EntityComponent parameters must be a Dictionary.")
			return false

	if (not remainder_item_id.is_empty()) and (not GameID.is_valid(remainder_item_id)):
		push_error("Invalid Consumable remainder Item ID: %s" % remainder_item_id)
		return false

	return true
