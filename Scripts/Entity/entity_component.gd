extends Node
class_name EntityComponent

@export var component_id: StringName

var root_entity: Entity
var _sibling_watchers: Dictionary[StringName, Array] = {}

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

	_sibling_watchers.clear()
	root_entity = null

## Called when this component is added to an Entity.
func on_added() -> void:
	pass

## Called just before this component is removed from its Entity.
func on_removing() -> void:
	pass

## Called when another component is added to the same Entity.
func on_sibling_added(_component_id: StringName,_component: EntityComponent) -> void:
	pass

## Called just before another component is removed from the same Entity.
func on_sibling_removing(_component_id: StringName,_component: EntityComponent) -> void:
	pass

func watch_sibling(_component_id: StringName, callback: Callable) -> void:
	if not callback.is_valid():
		return

	if not _sibling_watchers.has(_component_id):
		_sibling_watchers[_component_id] = []

	if callback not in _sibling_watchers[_component_id]:
		_sibling_watchers[_component_id].append(callback)

	callback.call(get_component(_component_id))

func _handle_component_added(_component_id: StringName,component: EntityComponent) -> void:
	if component == self:
		return
	
	_notify_sibling_watchers(_component_id, component)
	on_sibling_added(_component_id, component)

func _handle_component_removing(_component_id: StringName,component: EntityComponent) -> void:
	if component == self:
		return
	
	_notify_sibling_watchers(_component_id, null)
	on_sibling_removing(_component_id, component)

func _notify_sibling_watchers(_component_id: StringName,component: EntityComponent) -> void:
	if not _sibling_watchers.has(_component_id):
		return

	for callback in _sibling_watchers[_component_id]:
		callback.call(component)

func get_component(_component_id: StringName) -> EntityComponent:
	if root_entity == null:
		return null

	return root_entity.get_component(_component_id)

func has_component(_component_id: StringName) -> bool:
	if root_entity == null:
		return false

	return root_entity.has_component(_component_id)

func get_interaction_suggestions() -> Array[StringName]:
	return []
