extends Node
class_name EntityComponent

@export var component_id: StringName

var root_entity: Entity

func _set_owner(owner: Entity) -> void:
	root_entity = owner

	if not root_entity.component_added.is_connected(_handle_component_added):
		root_entity.component_added.connect(_handle_component_added)

	if not root_entity.component_removing.is_connected(_handle_component_removing):
		root_entity.component_removing.connect(_handle_component_removing)


func _clear_owner() -> void:
	if root_entity:
		if root_entity.component_added.is_connected(_handle_component_added):
			root_entity.component_added.disconnect(_handle_component_added)

		if root_entity.component_removing.is_connected(_handle_component_removing):
			root_entity.component_removing.disconnect(_handle_component_removing)

	root_entity = null

## Called when this component is added to an Entity.
func on_added() -> void:
	pass

## Called just before this component is removed from its Entity.
func on_removing() -> void:
	pass

## Called when another component is added to the same Entity.
func on_component_added(_component_id: StringName,_component: EntityComponent) -> void:
	pass

## Called just before another component is removed from the same Entity.
func on_component_removing(_component_id: StringName,_component: EntityComponent) -> void:
	pass

func _handle_component_added(component_id: StringName,component: EntityComponent) -> void:
	if component == self:
		return

	on_component_added(component_id, component)

func _handle_component_removing(component_id: StringName,component: EntityComponent) -> void:
	if component == self:
		return

	on_component_removing(component_id, component)


func get_component(component_id: StringName) -> EntityComponent:
	if root_entity == null:
		return null

	return root_entity.get_component(component_id)


func has_component(component_id: StringName) -> bool:
	if root_entity == null:
		return false

	return root_entity.has_component(component_id)


func get_interaction_suggestions() -> Array[StringName]:
	return []
