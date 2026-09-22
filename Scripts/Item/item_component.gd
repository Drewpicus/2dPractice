extends Resource
class_name ItemComponent

var component_id: StringName
var root_item: Item

func _set_owner(owner: Item) -> void:
	root_item = owner

	if not root_item.component_added.is_connected(_handle_component_added):
		root_item.component_added.connect(_handle_component_added)

	if not root_item.component_removing.is_connected(_handle_component_removing):
		root_item.component_removing.connect(_handle_component_removing)

func _clear_owner() -> void:
	if root_item:
		if root_item.component_added.is_connected(_handle_component_added):
			root_item.component_added.disconnect(_handle_component_added)

		if root_item.component_removing.is_connected(_handle_component_removing):
			root_item.component_removing.disconnect(_handle_component_removing)

	root_item = null

## Called when this component is added to an Item.
func on_added() -> void:
	pass

## Called just before this component is removed from its Item.
func on_removing() -> void:
	pass

## Called when another component is added to the same Item.
func on_sibling_added(_component_id: StringName,_component: ItemComponent) -> void:
	pass

## Called just before another component is removed from the same Item.
func on_sibling_removing(_component_id: StringName,_component: ItemComponent) -> void:
	pass

func _handle_component_added(_component_id: StringName,component: ItemComponent) -> void:
	if component == self:
		return

	on_sibling_added(_component_id, component)


func _handle_component_removing(_component_id: StringName,component: ItemComponent) -> void:
	if component == self:
		return

	on_sibling_removing(_component_id, component)

func get_component(_component_id: StringName) -> ItemComponent:
	if root_item == null:
		return null

	return root_item.get_component(_component_id)

func has_component(_component_id: StringName) -> bool:
	if root_item == null:
		return false

	return root_item.has_component(_component_id)
