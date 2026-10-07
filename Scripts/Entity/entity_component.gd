##A component that lends its properties to its [member root_entity].
##They exist as [Node] or [Node2D] and can have children, usually [Area2D].

extends Node
class_name EntityComponent

##A namespaced ID unique to this component, e.g. &"base:health"
@export var component_id: StringName

##The [Entity] this component modifies
var root_entity: Entity
##List of sibling components to watch for, along with an [Array] of
##functions to call whenever the matching component is added or removed
var _sibling_watchers: Dictionary[StringName, Array] = {}
var _creation_parameters: Dictionary = {}

signal state_changed

##Assigns an [Entity] this component modifies, and connects the entity's added and removing
##signals. This is the first step, with [method on_added] firing next, and [method _handle_component_added]
##firing thirdly.
func _set_owner(entity: Entity) -> void:
	root_entity = entity

	if not root_entity.component_added.is_connected(_handle_component_added):
		root_entity.component_added.connect(_handle_component_added)

	if not root_entity.component_removing.is_connected(_handle_component_removing):
		root_entity.component_removing.connect(_handle_component_removing)

##Unlinks an [Entity]'s signals from this component and unlinks it from both the
##[member root_entity] and all its siblings.
func _clear_owner() -> void:
	if root_entity:
		if root_entity.component_added.is_connected(_handle_component_added):
			root_entity.component_added.disconnect(_handle_component_added)

		if root_entity.component_removing.is_connected(_handle_component_removing):
			root_entity.component_removing.disconnect(_handle_component_removing)

	_sibling_watchers.clear()
	root_entity = null

##Called when this component is added to an [Entity].
func on_added() -> void:
	pass

##Called just before this component is removed from its [Entity].
func on_removing() -> void:
	pass

##Called when another component is added to the same [Entity].
func on_sibling_added(_component_id: StringName,_component: EntityComponent) -> void:
	pass

##Called just before another component is removed from the same [Entity].
func on_sibling_removing(_component_id: StringName,_component: EntityComponent) -> void:
	pass

##Adds a type of component by its [param sibling_id] to [member _sibling_watchers], along
##with a function ([param callback]) to run whenever the watched sibling is added or removed.
##Multiple [param callback]s can be tied to one sibling.
func watch_sibling(sibling_id: StringName, callback: Callable) -> void:
	if not callback.is_valid():
		return

	if not _sibling_watchers.has(sibling_id):
		_sibling_watchers[sibling_id] = []

	if callback not in _sibling_watchers[sibling_id]:
		_sibling_watchers[sibling_id].append(callback)

	callback.call(get_component(sibling_id))

##Removes [param callback] from watching any sibling components. If a sibling has no functions
##left tied to it in [member _sibling_watchers], the sibling's [param sibling_id] is
##removed from [member _sibling_watchers] entirely.
func unwatch_sibling(sibling_id: StringName, callback: Callable) -> void:
	if not _sibling_watchers.has(sibling_id):
		return

	_sibling_watchers[sibling_id].erase(callback)

	if _sibling_watchers[sibling_id].is_empty():
		_sibling_watchers.erase(sibling_id)

##When a component is added, forward its [member component_id] (as [param target_id]) and the
##component object itself to any components plugged into [method on_sibling_added] or that
##have the added component as a sibling to watch.
func _handle_component_added(target_id: StringName, component: EntityComponent) -> void:
	if component == self:
		return
	
	_notify_sibling_watchers(target_id, component)
	on_sibling_added(target_id, component)

##When a component is about to be removed, forward its [member component_id] (as [param target_id]) and the
##component object itself to any components plugged into [method on_sibling_removing] or that
##have the removing component as a sibling to watch.
func _handle_component_removing(target_id: StringName, component: EntityComponent) -> void:
	if component == self:
		return
	
	_notify_sibling_watchers(target_id, null)
	on_sibling_removing(target_id, component)

##Calls every function this component tied to [param target_id]
func _notify_sibling_watchers(target_id: StringName, component: EntityComponent) -> void:
	if not _sibling_watchers.has(target_id):
		return

	for callback in _sibling_watchers[target_id]:
		callback.call(component)

##Returns the [EntityComponent] attached to the same [Entity] from its [member component_id]
func get_component(target_id: StringName) -> EntityComponent:
	if root_entity == null:
		return null

	return root_entity.get_component(target_id)

##True if the [member root_entity] also has the ID'd component
func has_component(target_id: StringName) -> bool:
	if root_entity == null:
		return false

	return root_entity.has_component(target_id)

##Returns an [Array] of [Interaction] suggestions by ID, meant to be
##overwritten by components with specific [Interaction]s they enable.
##e.g. [InfoComponent] suggests the interaction [code]&"base:inspect"[/code]
func get_interaction_suggestions() -> Array[StringName]:
	return []

##Returns an [Array] of blocked [Interaction]s by ID, meant to be
##overwritten by components with specific [Interaction]s they forbid.
##e.g. [LockedComponent] might block the interaction [code]&"base:open_door"[/code]
func get_blocked_interactions() -> Array[StringName]:
	return []

##Called when this Entity receives a GameEvent.
func on_event(_event: GameEvent) -> void:
	pass

##Called when this owner is resolving a GameResolution.
func on_resolution(_resolution: GameResolution) -> void:
	pass

##Usually called in [method on_resolution] to add a [param modifier] to [param resolution].
##The [param modifier] should be a new, complete [ResolutionModifier] object which can
##be created with something like [code]StatusDurationModifier.new()[/code]
func contribute_modifier(resolution: GameResolution, modifier: ResolutionModifier) -> bool:
	if not resolution or not modifier:
		return false

	return resolution.add_modifier(modifier, self)

##Returns this component's mutable runtime state.
func serialize_state() -> Dictionary:
	return {}

##Restores this component's mutable runtime state.
func deserialize_state(_state: Dictionary) -> void:
	pass

##Tells the game world this component's state changed, prompting the world
##authority to align the state across all clients on a server.
func notify_state_changed() -> void:
	state_changed.emit()

func _set_creation_parameters(
	parameters: Dictionary
) -> void:
	_creation_parameters = parameters.duplicate(true)


func get_creation_parameters() -> Dictionary:
	return _creation_parameters.duplicate(true)
