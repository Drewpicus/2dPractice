extends EntityComponent
class_name EquipmentComponent

@export var slots: Array
@export var use_default_slots: bool = true
var default_slots: Array[StringName] = [&"mainhand",&"offhand",&"head",&"chest",&"legs",&"feet"]
var equipment: Dictionary[StringName,Item] = {}

signal equipment_updated

func _ready() -> void:
	if use_default_slots:
		slots.append_array(default_slots)
		
	var inventory := get_component(&"inventory") as InventoryComponent
	if inventory:
		inventory.item_removed.connect(_on_item_removed)

func equip(slot: StringName, item: Item) -> bool:
	if not item:
		return false
	
	if slot not in slots:
		return false
	
	var equippable = item.get_component(&"equippable") as EquippableItemComponent
	if not equippable:
		return false
	
	if slot not in equippable.slots:
		return false
	
	var inventory = get_component(&"inventory") as InventoryComponent
	if not inventory:
		return false
		
	if item not in inventory.items:
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
