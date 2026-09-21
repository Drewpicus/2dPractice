extends Interaction
class_name PickpocketInteraction

func _init() -> void:
	interaction_id = &"pickpocket"
	interaction_name = "Pickpocket"

func can_perform(_interactor: Entity, _target: Entity) -> bool:
	if not _interactor.has_component(&"base:interactor"):
		return false
	if not _target.has_component(&"base:inventory"):
		return false
	if _interactor.global_position.distance_to(_target.global_position) > _interactor.get_component(&"base:interactor").reach:
		return false
	return true

func perform(_interactor: Entity, _target: Entity) -> void:
	var inventory_menu := _interactor.get_tree().root.get_node_or_null(
		"Main/UI/InventoryMenu"
	) as InventoryMenu

	if not inventory_menu:
		return

	inventory_menu.show_inventory(_interactor, _target)
