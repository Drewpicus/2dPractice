extends EntityComponent
class_name EquipmentComponent

@export var slots: Array[StringName]
@export var use_default_slots: bool = true
var default_slots: Array = [&"mainhand",&"offhand",&"head",&"chest",&"legs",&"feet"]
var equipment: Dictionary[StringName,Item] = {}

signal equipment_updated

func _ready() -> void:
	if use_default_slots:
		slots.append_array(default_slots)

func equip(slot: StringName, item: Item) -> void:
	equipment[slot] = item
	equipment_updated.emit()

func unequip(slot: StringName) -> Item:
	var item = equipment.get(slot) as Item
	equipment.erase(slot)
	equipment_updated.emit()
	return item

func get_equipment(slot: StringName) -> Item:
	return equipment.get(slot)

func has_equipment(slot: StringName) -> bool:
	return equipment.has(slot) != null
