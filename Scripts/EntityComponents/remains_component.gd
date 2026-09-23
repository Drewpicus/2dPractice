##Contains a reference to the type of remains left behind by this Entity when
##they die, be it a corpse or a puddle of goo. Remains inherit inventory.

extends EntityComponent
class_name RemainsComponent

@export var remains_id: StringName

func spawn_remains() -> Entity:
	if not GameID.is_valid(remains_id):
		push_error("Invalid remains ID: %s" % remains_id)
		return null

	var world := GameWorld.find_world(root_entity)

	if not world:
		push_error("Could not find GameWorld for remains spawn.")
		return null

	var remains_entity := world.spawn_entity(remains_id, root_entity.global_position)

	if not remains_entity:
		return null

	var inventory = get_component(&"base:inventory") as InventoryComponent
	if inventory:
		var remains_inventory = remains_entity.get_component(&"base:inventory") as InventoryComponent
		if remains_inventory:
			var all_items = inventory.take_all_items()
			remains_inventory.add_items(all_items)
		
	return remains_entity
