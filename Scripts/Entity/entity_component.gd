extends Node
class_name EntityComponent

@export var component_id: StringName

var root_entity: Entity
var _sibling_watchers: Dictionary[StringName, Array] = {}

func _set_owner(entity: Entity) -> void:
	root_entity = entity

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

func watch_sibling(sibling_id: StringName, callback: Callable) -> void:
	if not callback.is_valid():
		return

	if not _sibling_watchers.has(sibling_id):
		_sibling_watchers[sibling_id] = []

	if callback not in _sibling_watchers[sibling_id]:
		_sibling_watchers[sibling_id].append(callback)

	callback.call(get_component(sibling_id))

func unwatch_sibling(sibling_id: StringName, callback: Callable) -> void:
	if not _sibling_watchers.has(sibling_id):
		return

	_sibling_watchers[sibling_id].erase(callback)

	if _sibling_watchers[sibling_id].is_empty():
		_sibling_watchers.erase(sibling_id)

func _handle_component_added(target_id: StringName,component: EntityComponent) -> void:
	if component == self:
		return
	
	_notify_sibling_watchers(target_id, component)
	on_sibling_added(target_id, component)

func _handle_component_removing(target_id: StringName,component: EntityComponent) -> void:
	if component == self:
		return
	
	_notify_sibling_watchers(target_id, null)
	on_sibling_removing(target_id, component)

func _notify_sibling_watchers(target_id: StringName,component: EntityComponent) -> void:
	if not _sibling_watchers.has(target_id):
		return

	for callback in _sibling_watchers[target_id]:
		callback.call(component)

func get_component(target_id: StringName) -> EntityComponent:
	if root_entity == null:
		return null

	return root_entity.get_component(target_id)

func has_component(target_id: StringName) -> bool:
	if root_entity == null:
		return false

	return root_entity.has_component(target_id)

func get_interaction_suggestions() -> Array[StringName]:
	return []

## Called when this Entity receives a GameEvent.
func on_event(_event: GameEvent) -> void:
	pass

## Called when this owner is resolving a GameResolution.
func on_resolution(_resolution: GameResolution) -> void:
	pass

func contribute_modifier(resolution: GameResolution,modifier: ResolutionModifier) -> bool:
	if not resolution or not modifier:
		return false

	return resolution.add_modifier(modifier, self)
