extends Node
class_name WorldReplicationSystem


func track_entity(entity: Entity) -> void:
	if not entity:
		return

	var added_callback := (_on_tracked_component_added.bind(entity))
	var removing_callback := (_on_tracked_component_removing.bind(entity))

	if not entity.component_added.is_connected(added_callback):
		entity.component_added.connect(added_callback)

	if not entity.component_removing.is_connected(removing_callback):
		entity.component_removing.connect(removing_callback)

	for component in entity.get_components():
		_track_component(entity, component)

func untrack_entity(entity: Entity) -> void:
	if not entity:
		return

	var added_callback := (_on_tracked_component_added.bind(entity))
	var removing_callback := (_on_tracked_component_removing.bind(entity))

	if entity.component_added.is_connected(added_callback):
		entity.component_added.disconnect(added_callback)

	if entity.component_removing.is_connected(removing_callback):
		entity.component_removing.disconnect(removing_callback)

	for component in entity.get_components():
		_untrack_component(entity, component)

func track_item(item: Item) -> void:
	if not item:
		return

	var added_callback := (_on_tracked_item_component_added.bind(item))
	var removing_callback := (_on_tracked_item_component_removing.bind(item))

	if not item.component_added.is_connected(added_callback):
		item.component_added.connect(added_callback)

	if not item.component_removing.is_connected(removing_callback):
		item.component_removing.connect(removing_callback)

	for component in item.get_components():
		_track_item_component(item, component)

func untrack_item(item: Item) -> void:
	if not item:
		return

	var added_callback := (_on_tracked_item_component_added.bind(item))
	var removing_callback := (_on_tracked_item_component_removing.bind(item))

	if item.component_added.is_connected(added_callback):
		item.component_added.disconnect(added_callback)

	if item.component_removing.is_connected(removing_callback):
		item.component_removing.disconnect(removing_callback)

	for component in item.get_components():
		_untrack_item_component(item, component)

func _track_component(entity: Entity, component: EntityComponent) -> void:
	if not component:
		return

	var callback := (_on_component_state_changed.bind(entity, component.component_id))

	if not component.state_changed.is_connected(callback):
		component.state_changed.connect(callback)

func _untrack_component(entity: Entity, component: EntityComponent) -> void:
	if not component:
		return

	var callback := (_on_component_state_changed.bind(entity, component.component_id))

	if component.state_changed.is_connected(callback):
		component.state_changed.disconnect(callback)

func _track_item_component(item: Item, component: ItemComponent) -> void:
	if not component:
		return

	var callback := (_on_item_component_state_changed.bind(item, component.component_id))

	if not component.state_changed.is_connected(callback):
		component.state_changed.connect(callback)


func _untrack_item_component(item: Item, component: ItemComponent) -> void:
	if not component:
		return

	var callback := (_on_item_component_state_changed.bind(item, component.component_id))

	if component.state_changed.is_connected(callback):
		component.state_changed.disconnect(callback)


func _on_component_state_changed(entity: Entity, component_id: StringName) -> void:
	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	if not is_instance_valid(entity):
		return

	var component := entity.get_component(component_id)

	if not component:
		return

	_receive_component_state.rpc(entity.instance_id, String(component_id), component.serialize_state())


@rpc("authority", "call_remote", "reliable", 5)
func _receive_component_state(entity_instance_id: String, component_id_string: String, state: Dictionary) -> void:
	if MultiplayerManager.is_world_authority():
		return

	var entity := RuntimeObjectRegistry.get_entity(entity_instance_id)

	if not entity:
		return

	var component_id := StringName(component_id_string)

	if not GameID.is_valid(component_id):
		return

	var component := entity.get_component(component_id)

	if not component:
		return

	component.deserialize_state(state)


func _on_tracked_component_added(component_id: StringName, component: EntityComponent, entity: Entity) -> void:
	_track_component(entity, component)

	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	# PlayerController replication has its
	# own session-specific path.
	if component_id == &"base:player_controller":
		return

	_receive_component_added.rpc(entity.instance_id, String(component_id), component.serialize_state())


@rpc("authority", "call_remote", "reliable", 5)
func _receive_component_added(entity_instance_id: String, component_id_string: String, state: Dictionary) -> void:
	if MultiplayerManager.is_world_authority():
		return

	var entity := RuntimeObjectRegistry.get_entity(entity_instance_id)

	if not entity:
		return

	var component_id := StringName(component_id_string)

	if not GameID.is_valid(component_id):
		return

	if entity.has_component(component_id):
		var existing := entity.get_component(component_id)

		existing.deserialize_state(state)
		return

	var component := entity.add_component(component_id)

	if not component:
		return

	component.deserialize_state(state)


func _on_tracked_component_removing(component_id: StringName, component: EntityComponent, entity: Entity) -> void:
	if (MultiplayerManager.session_active and MultiplayerManager.is_world_authority() and (component_id != &"base:player_controller")):
		_receive_component_removed.rpc(entity.instance_id, String(component_id))

	_untrack_component(entity, component)


@rpc("authority", "call_remote", "reliable", 5)
func _receive_component_removed(entity_instance_id: String, component_id_string: String) -> void:
	if MultiplayerManager.is_world_authority():
		return

	var entity := RuntimeObjectRegistry.get_entity(entity_instance_id)

	if not entity:
		return

	var component_id := StringName(component_id_string)

	if not GameID.is_valid(component_id):
		return

	if not entity.has_component(component_id):
		return

	entity.remove_component(component_id)


func _on_item_component_state_changed(item: Item, component_id: StringName) -> void:
	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	if not item:
		return

	var component := item.get_component(component_id)

	if not component:
		return

	_receive_item_component_state.rpc(item.instance_id, String(component_id), component.serialize_state())


@rpc("authority", "call_remote", "reliable", 5)
func _receive_item_component_state(item_instance_id: String, component_id_string: String, state: Dictionary) -> void:
	if MultiplayerManager.is_world_authority():
		return

	var item := RuntimeObjectRegistry.get_item(item_instance_id)

	if not item:
		return

	var component_id := StringName(component_id_string)

	if not GameID.is_valid(component_id):
		return

	var component := item.get_component(component_id)

	if not component:
		return

	component.deserialize_state(state)


func _on_tracked_item_component_added(component_id: StringName, component: ItemComponent, item: Item) -> void:
	_track_item_component(item, component)

	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	_receive_item_component_added.rpc(item.instance_id, String(component_id), component.serialize_state())


@rpc("authority", "call_remote", "reliable", 5)
func _receive_item_component_added(item_instance_id: String, component_id_string: String, state: Dictionary) -> void:
	if MultiplayerManager.is_world_authority():
		return

	var item := RuntimeObjectRegistry.get_item(item_instance_id)

	if not item:
		return

	var component_id := StringName(component_id_string)

	if not GameID.is_valid(component_id):
		return

	if item.has_component(component_id):
		var existing := item.get_component(component_id)

		existing.deserialize_state(state)
		return

	var component := item.add_component(component_id)

	if not component:
		return

	component.deserialize_state(state)


func _on_tracked_item_component_removing(component_id: StringName, component: ItemComponent, item: Item) -> void:
	if (MultiplayerManager.session_active and MultiplayerManager.is_world_authority()):
		_receive_item_component_removed.rpc(item.instance_id, String(component_id))

	_untrack_item_component(item, component)


@rpc("authority", "call_remote", "reliable", 5)
func _receive_item_component_removed(item_instance_id: String, component_id_string: String) -> void:
	if MultiplayerManager.is_world_authority():
		return

	var item := RuntimeObjectRegistry.get_item(item_instance_id)

	if not item:
		return

	var component_id := StringName(component_id_string)

	if not GameID.is_valid(component_id):
		return

	if not item.has_component(component_id):
		return

	item.remove_component(component_id)
