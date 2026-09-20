##Contains a reference to the type of remains left behind by this Entity when
##they die, be it a corpse or a puddle of goo. Remains inherit inventory.

extends EntityComponent
class_name RemainsComponent

@export var remains: EntityDefinition

func spawn_remains() -> Entity:
	var remains_entity: Entity
	if remains:
		remains_entity = EntityFactory.spawn(remains,root_entity.global_position,root_entity.get_parent())
		
		var inventory = get_component(&"inventory") as InventoryComponent
		if inventory:
			var remains_inventory = remains_entity.get_component(&"inventory") as InventoryComponent
			if remains_inventory:
				var all_items = inventory.take_all_items()
				remains_inventory.add_items(all_items)
		
	return remains_entity
