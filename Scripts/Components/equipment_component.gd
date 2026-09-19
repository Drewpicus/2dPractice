extends EntityComponent
class_name EquipmentComponent

enum SLOT {
	MAINHAND,
	OFFHAND
}

var equipment: Dictionary[int,Item] = {}

signal equipment_updated

func equip(slot: int, item: Item) -> void:
	equipment[slot] = item
	equipment_updated.emit()

func unequip(slot: int) -> Item:
	var item = equipment.get(slot) as Item
	equipment.erase(slot)
	equipment_updated.emit()
	return item

func get_equipment(slot: int) -> Item:
	return equipment.get(slot)

func has_equipment(slot: int) -> bool:
	return equipment.has(slot)
