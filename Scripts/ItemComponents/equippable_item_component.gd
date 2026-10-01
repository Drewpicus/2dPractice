extends ItemComponent
class_name EquippableItemComponent

@export var slots: Array

func _init() -> void:
	component_id = &"base:equippable"

func serialize_state() -> Dictionary:
	var serialized_slots: Array[String] = []

	for slot in slots:
		serialized_slots.append(String(slot))

	return {
		"slots": serialized_slots
	}


func deserialize_state(state: Dictionary) -> void:
	var saved_slots = state.get("slots", [])

	if not saved_slots is Array:
		return

	slots.clear()

	for slot in saved_slots:
		slots.append(StringName(slot))
