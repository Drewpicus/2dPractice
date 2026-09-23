extends EntityComponent
class_name EquipmentComponent

@export var slots: Array
@export var use_default_slots: bool = true
var default_slots: Array[StringName] = [&"mainhand",&"offhand",&"head",&"chest",&"legs",&"feet"]
var equipment: Dictionary[StringName,Item] = {}
var _inventory: InventoryComponent

signal equipment_updated

func on_added() -> void:
	if use_default_slots:
		for slot in default_slots:
			if slot not in slots:
				slots.append(slot)

	watch_sibling(&"base:inventory", _set_inventory)

func _set_inventory(inventory: InventoryComponent) -> void:
	if _inventory == inventory:
		return

	if _inventory:
		if _inventory.item_removed.is_connected(_on_item_removed):
			_inventory.item_removed.disconnect(_on_item_removed)

	_inventory = inventory

	if _inventory:
		if not _inventory.item_removed.is_connected(_on_item_removed):
			_inventory.item_removed.connect(_on_item_removed)

func equip(slot: StringName, item: Item) -> bool:
	if not item:
		return false
	
	if slot not in slots:
		return false
	
	var equippable = item.get_component(&"base:equippable") as EquippableItemComponent
	if not equippable:
		return false
	
	if slot not in equippable.slots:
		return false
	
	if not _inventory:
		return false

	if item not in _inventory.items:
		return false
	
	for existing_slot in slots:
		if get_equipment(existing_slot) == item:
			unequip(existing_slot)
	equipment[slot] = item
	equipment_updated.emit()
	return true

func unequip(slot: StringName) -> Item:
	var item = equipment.get(slot) as Item
	equipment.erase(slot)
	equipment_updated.emit()
	return item

func get_equipment(slot: StringName) -> Item:
	return equipment.get(slot)

func has_equipment(slot: StringName) -> bool:
	return equipment.get(slot) != null

func _on_item_removed(item: Item) -> void:
	for slot in equipment.keys():
		if item == equipment.get(slot) as Item:
			unequip(slot)

func serialize_state() -> Dictionary:
	var serialized_slots: Array[String] = []

	for slot in slots:
		serialized_slots.append(String(slot))

	var serialized_equipment := {}

	for slot in equipment:
		var item := equipment[slot] as Item

		if item:
			serialized_equipment[String(slot)] = item.instance_id

	return {
		"slots": serialized_slots,
		"equipment": serialized_equipment
	}

func deserialize_state(state: Dictionary) -> void:
	if state.has("slots"):
		var saved_slots = state["slots"]

		if saved_slots is Array:
			slots.clear()

			for slot_value in saved_slots:
				slots.append(StringName(slot_value))

	equipment.clear()

	var saved_equipment = state.get("equipment", {})

	if not saved_equipment is Dictionary:
		push_error("Serialized equipment must be a Dictionary.")
		return

	for slot_key in saved_equipment:
		var slot := StringName(slot_key)
		var item_instance_id := String(saved_equipment[slot_key])
		var item := RuntimeObjectRegistry.get_item(item_instance_id)

		if not item:
			push_error(
				"Could not restore equipped Item instance: %s"
				% item_instance_id
			)
			continue

		equipment[slot] = item
