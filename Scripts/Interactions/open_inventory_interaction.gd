extends Interaction
class_name OpenInventoryInteraction

func _init() -> void:
	interaction_id = &"base:open_inventory"
	interaction_name = "Open Inventory"

func can_perform(_interactor: Entity, _target: Entity) -> bool:
	if not _interactor.has_component(&"base:interactor"):
		return false
	if not _target.has_component(&"base:inventory"):
		return false
	if _interactor.global_position.distance_to(_target.global_position) > _interactor.get_component(&"base:interactor").reach:
		return false
	return true

func perform(
	interactor: Entity,
	target: Entity
) -> void:
	var world := GameWorld.find_world(
		interactor
	)

	if not world:
		return

	world.request_inventory(
		interactor,
		target
	)
