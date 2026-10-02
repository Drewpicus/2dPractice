extends Interaction
class_name PickUpItemInteraction


func _init() -> void:
	interaction_id = &"base:pick_up_item"
	interaction_name = "Pick Up"


func can_perform(
	interactor: Entity,
	target: Entity
) -> bool:
	var interactor_component := interactor.get_component(
		&"base:interactor"
	) as InteractorComponent

	if not interactor_component:
		return false

	var inventory := interactor.get_component(
		&"base:inventory"
	) as InventoryComponent

	if not inventory:
		return false

	var dropped_item := target.get_component(
		&"base:dropped_item"
	) as DroppedItemComponent

	if not dropped_item:
		return false

	if not dropped_item.get_item():
		return false

	if (
		interactor.global_position.distance_to(
			target.global_position
		)
		> interactor_component.reach
	):
		return false

	return true


func perform(
	interactor: Entity,
	target: Entity
) -> void:
	var dropped_item := target.get_component(
		&"base:dropped_item"
	) as DroppedItemComponent

	var inventory := interactor.get_component(
		&"base:inventory"
	) as InventoryComponent

	if not dropped_item or not inventory:
		return

	var item := dropped_item.get_item()

	if not item:
		return

	var world := GameWorld.find_world(target)

	if not world:
		return

	inventory.add_item(item)
	world.remove_entity(target)


func requires_authority() -> bool:
	return true
