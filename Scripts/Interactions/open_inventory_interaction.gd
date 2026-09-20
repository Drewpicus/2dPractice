extends Interaction
class_name OpenInventoryInteraction

func _init() -> void:
	interaction_id = &"open_inventory"
	interaction_name = "Open Inventory"

func can_perform(_interactor: Entity, _target: Entity) -> bool:
	if not _interactor.has_component(&"interactor"):
		return false
	if not _target.has_component(&"inventory"):
		return false
	if _interactor.global_position.distance_to(_target.global_position) > _interactor.get_component(&"interactor").reach:
		return false
	return true

func perform(_interactor: Entity, _target: Entity) -> void:
	var inventory_menu := _interactor.get_tree().root.get_node_or_null(
		"Main/UI/InventoryMenu"
	) as InventoryMenu

	if not inventory_menu:
		return

	inventory_menu.show_inventory(_interactor, _target)
