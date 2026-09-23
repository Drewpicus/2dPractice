extends Resource
class_name ItemComponent

var component_id: StringName
var root_item: Item
var _sibling_watchers: Dictionary[StringName, Array] = {}

func _set_owner(item: Item) -> void:
	root_item = item

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

	_sibling_watchers.clear()
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

func _handle_component_added(target_id: StringName,component: ItemComponent) -> void:
	if component == self:
		return
	
	_notify_sibling_watchers(target_id, component)
	on_sibling_added(target_id, component)


func _handle_component_removing(target_id: StringName,component: ItemComponent) -> void:
	if component == self:
		return

	_notify_sibling_watchers(target_id, null)
	on_sibling_removing(target_id, component)

func _notify_sibling_watchers(target_id: StringName,component: ItemComponent) -> void:
	if not _sibling_watchers.has(target_id):
		return

	for callback in _sibling_watchers[target_id]:
		callback.call(component)

func get_component(target_id: StringName) -> ItemComponent:
	if root_item == null:
		return null

	return root_item.get_component(target_id)

func has_component(target_id: StringName) -> bool:
	if root_item == null:
		return false

	return root_item.has_component(target_id)

## Called when this Item receives a GameEvent.
func on_event(_event: GameEvent) -> void:
	pass

## Called when this owner is resolving a GameResolution.
func on_resolution(_resolution: GameResolution) -> void:
	pass

func contribute_modifier(resolution: GameResolution,modifier: ResolutionModifier) -> bool:
	if not resolution or not modifier:
		return false

	return resolution.add_modifier(modifier, self)
