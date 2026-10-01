extends Node2D
class_name GameWorld

@onready var entities: Node2D = $Entities
var _items: Dictionary[String, Item] = {}

@onready var terrain: TerrainRenderer = $Terrain
@onready var entity_spawner: MultiplayerSpawner = $EntitySpawner

const MOVEMENT_SNAPSHOT_RATE: float = 20.0
const REMOTE_VISUAL_INTERPOLATION_SPEED: float = 50.0
const REMOTE_VISUAL_TELEPORT_DISTANCE: float = 160.0

const COMMAND_INTERACTION := &"base:interaction"
const COMMAND_TAKE_ITEM := &"base:take_item"
const COMMAND_EQUIP_ITEM := &"base:equip_item"
const COMMAND_UNEQUIP_ITEM := &"base:unequip_item"

var _snapshot_timer: float = 0.0
var _last_movement_sequence: Dictionary[int, int] = {}
var _last_simulated_movement_sequence: Dictionary[int, int] = {}
var _network_positions: Dictionary[String, Vector2] = {}
var _network_velocities: Dictionary[String, Vector2] = {}
var _remote_sprite_rest_positions: Dictionary[String, Vector2] = {}

var world_data: WorldData

func _ready() -> void:
	entity_spawner.spawn_function = _spawn_network_entity

	if not MultiplayerManager.peer_left.is_connected(
		_on_peer_left
	):
		MultiplayerManager.peer_left.connect(
			_on_peer_left
		)

func _process(delta: float) -> void:
	if not MultiplayerManager.session_active:
		return

	if MultiplayerManager.is_world_authority():
		return

	for instance_id in _network_positions.keys():
		var entity := RuntimeObjectRegistry.get_entity(instance_id)

		if not entity:
			_network_positions.erase(instance_id)
			_network_velocities.erase(instance_id)
			_remote_sprite_rest_positions.erase(instance_id)
			continue

		var controller := entity.get_component(
			&"base:player_controller"
		) as PlayerControllerComponent

		if controller and controller.is_locally_controlled():
			continue

		_interpolate_remote_visual(
			entity,
			instance_id,
			delta
		)

		if _network_velocities.has(instance_id):
			entity.velocity = _network_velocities[instance_id]


func _physics_process(delta: float) -> void:
	if not MultiplayerManager.session_active:
		return

	if not multiplayer.is_server():
		return

	_snapshot_timer += delta

	var snapshot_interval := (1.0 / MOVEMENT_SNAPSHOT_RATE)

	if _snapshot_timer < snapshot_interval:
		return

	_snapshot_timer -= snapshot_interval

	_send_movement_snapshot()

func generate_world(world_size: Vector2i, _seed: int) -> void:
	var generator := WorldGenerator.new()

	world_data = generator.generate(world_size,_seed)

	terrain.render(world_data)

func cell_to_world(cell: Vector2i) -> Vector2:
	return terrain.to_global(terrain.map_to_local(cell))


func world_to_cell(world_position: Vector2) -> Vector2i:
	return terrain.local_to_map(terrain.to_local(world_position))

static func find_world(node: Node) -> GameWorld:
	while node != null:
		if node is GameWorld:
			return node

		node = node.get_parent()

	return null

func spawn_entity(
	entity_id: StringName,
	entity_position: Vector2,
	runtime_components: Dictionary = {}
) -> Entity:
	if not MultiplayerManager.is_world_authority():
		push_error(
			"Non-authority tried to spawn Entity: %s"
			% entity_id
		)
		return null

	var definition := DefinitionRegistry.get_entity(entity_id)

	if not definition:
		push_error(
			"No EntityDefinition registered for: %s"
			% entity_id
		)
		return null

	var instance_id := RuntimeObjectRegistry.generate_unique_id()

	var spawn_data := {
		"entity_id": String(entity_id),
		"instance_id": instance_id,
		"position": entity_position,
		"runtime_components": runtime_components
	}

	var entity := entity_spawner.spawn(
		spawn_data
	) as Entity

	if entity:
		_track_authoritative_entity(entity)

	return entity

func transfer_player_controller(
	from_entity: Entity,
	to_entity: Entity
) -> bool:
	if (
		MultiplayerManager.session_active
		and not MultiplayerManager.is_world_authority()
	):
		return false

	var controller := from_entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return false

	var peer_id := controller.controller_peer_id

	if not _apply_player_controller_transfer(
		from_entity,
		to_entity
	):
		return false

	if MultiplayerManager.session_active:
		_receive_player_controller_transfer.rpc(
			from_entity.instance_id,
			to_entity.instance_id,
			peer_id
		)

	return true

func _apply_player_controller_transfer(
	from_entity: Entity,
	to_entity: Entity
) -> bool:
	if not from_entity or not to_entity:
		return false

	if to_entity.has_component(
		&"base:player_controller"
	):
		return false

	var controller := from_entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return false

	# Don't leave either body moving from an old input source.
	var old_movement := from_entity.get_component(
		&"base:movement"
	) as MovementComponent

	if old_movement:
		old_movement.input_direction = Vector2.ZERO

	var target_movement := to_entity.get_component(
		&"base:movement"
	) as MovementComponent

	if target_movement:
		target_movement.input_direction = Vector2.ZERO

	controller = from_entity.detach_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return false

	if not to_entity.attach_component(controller):
		from_entity.attach_component(controller)
		return false

	return true

@rpc("authority", "call_remote", "reliable", 4)
func _receive_player_controller_transfer(
	from_instance_id: String,
	to_instance_id: String,
	controller_peer_id: int
) -> void:
	if multiplayer.is_server():
		return

	var from_entity := RuntimeObjectRegistry.get_entity(
		from_instance_id
	)

	var to_entity := RuntimeObjectRegistry.get_entity(
		to_instance_id
	)

	if not from_entity or not to_entity:
		return

	var controller := from_entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	# Sanity check: we're moving the same player's controller.
	if controller.controller_peer_id != controller_peer_id:
		return

	_apply_player_controller_transfer(
		from_entity,
		to_entity
	)

func remove_entity(entity: Entity) -> void:
	if not entity:
		return
	
	if MultiplayerManager.session_active:
		if not multiplayer.is_server():
			return
	
	RuntimeObjectRegistry.unregister(entity.instance_id,entity)

	entity.queue_free()

func get_entities() -> Array[Entity]:
	var result: Array[Entity] = []

	for child in entities.get_children():
		if child is Entity:
			result.append(child)

	return result

func serialize_entities() -> Array:
	var states: Array = []

	for entity in get_entities():
		states.append(entity.serialize_state())

	return states

func get_items() -> Array[Item]:
	var result: Array[Item] = []

	for item in _items.values():
		result.append(item)

	return result

func create_item(item_id: StringName) -> Item:
	if (
		MultiplayerManager.session_active
		and not MultiplayerManager.is_world_authority()
	):
		return null

	var definition := DefinitionRegistry.get_item(item_id)

	if not definition:
		return null

	var item := ItemFactory.build(definition)

	if not item:
		return null

	_items[item.instance_id] = item
	_track_authoritative_item(item)

	if MultiplayerManager.session_active:
		_receive_item_created.rpc(
			String(item.item_id),
			item.instance_id
		)

	return item

@rpc("authority", "call_remote", "reliable", 5)
func _receive_item_created(
	item_id_string: String,
	instance_id: String
) -> void:
	if multiplayer.is_server():
		return

	if _items.has(instance_id):
		return

	var item_id := StringName(item_id_string)

	if not GameID.is_valid(item_id):
		return

	var definition := DefinitionRegistry.get_item(item_id)

	if not definition:
		return

	var item := ItemFactory.build(definition)

	if not item:
		return

	if not item.restore_instance_id(instance_id):
		return

	_items[instance_id] = item

func remove_item(item: Item) -> void:
	if not item:
		return

	if (
		MultiplayerManager.session_active
		and not MultiplayerManager.is_world_authority()
	):
		return

	var instance_id := item.instance_id

	_untrack_authoritative_item(item)

	_items.erase(instance_id)
	RuntimeObjectRegistry.unregister(instance_id, item)

	if MultiplayerManager.session_active:
		_receive_item_removed.rpc(instance_id)

@rpc("authority", "call_remote", "reliable", 5)
func _receive_item_removed(instance_id: String) -> void:
	if multiplayer.is_server():
		return

	var item = _items.get(instance_id)

	if not item:
		return

	_items.erase(instance_id)

	RuntimeObjectRegistry.unregister(
		instance_id,
		item
	)

func serialize_items() -> Array:
	var states: Array = []

	for item in get_items():
		states.append(item.serialize_state())

	return states

## Save game
func serialize_state() -> Dictionary:
	return {
		"items": serialize_items(),
		"entities": serialize_entities()
	}

## Load game from save
func deserialize_state(state: Dictionary) -> bool:
	var item_states = state.get("items", [])
	var entity_states = state.get("entities", [])

	if not item_states is Array:
		push_error("GameWorld item states must be an Array.")
		return false

	if not entity_states is Array:
		push_error("GameWorld entity states must be an Array.")
		return false

	clear_runtime_state()

	var result := RuntimeStateLoader.reconstruct(
		item_states,
		entity_states,
		entities
	)

	if not result.has("items") or not result.has("entities"):
		return false

	for item in result["items"]:
		if item is Item:
			_items[item.instance_id] = item
			if MultiplayerManager.is_world_authority():
				_track_authoritative_item(item)

	return true

func clear_runtime_state() -> void:
	var current_items := get_items()
	var current_entities := get_entities()

	for item in current_items:
		if not item:
			continue

		_untrack_authoritative_item(item)

		RuntimeObjectRegistry.unregister(
			item.instance_id,
			item
		)

	_items.clear()
	
	for entity in current_entities:
		if not entity:
			continue

		RuntimeObjectRegistry.unregister(
			entity.instance_id,
			entity
		)

		# Remove immediately from the container so reconstructed
		# Entities can reuse readable names like "Player".
		if entity.get_parent() == entities:
			entities.remove_child(entity)

		entity.queue_free()

func _spawn_network_entity(data: Variant) -> Node:
	if not data is Dictionary:
		push_error("Network Entity spawn data must be a Dictionary.")
		return null

	var spawn_data := data as Dictionary

	var entity_id := StringName(spawn_data.get("entity_id", ""))
	var instance_id := String(spawn_data.get("instance_id", ""))
	var entity_position = spawn_data.get("position",Vector2.ZERO)

	if not GameID.is_valid(entity_id):
		push_error("Invalid network Entity ID: %s. Likely base: is missing" % entity_id)
		return null

	if instance_id.is_empty():
		push_error("Network Entity spawn is missing an instance ID.")
		return null

	if not entity_position is Vector2:
		push_error("Network Entity position must be a Vector2.")
		return null

	var definition := DefinitionRegistry.get_entity(entity_id)

	if not definition:
		push_error("No EntityDefinition registered for network entity spawn: %s" % entity_id)
		return null

	var entity := EntityFactory.build(definition)

	if not entity:
		return null
	
	if not entity.restore_instance_id(instance_id):
		entity.free()
		return null
	
	var runtime_components = spawn_data.get("runtime_components",{})

	if not runtime_components is Dictionary:
		entity.free()
		return null

	if not _apply_runtime_components(entity, runtime_components):
		entity.free()
		return null
	
	# Give the node the same canon name on every peer.
	entity.name = instance_id

	entity.position = entities.to_local(entity_position)

	print("Spawned ", entity_id, " | ", instance_id, " | peer ", multiplayer.get_unique_id())

	return entity

func _apply_runtime_components(
	entity: Entity,
	runtime_components: Dictionary
) -> bool:
	for component_key in runtime_components:
		var component_id := StringName(component_key)

		if not GameID.is_valid(component_id):
			push_error(
				"Invalid runtime component ID: %s"
				% component_id
			)
			return false

		var parameters = runtime_components[component_key]

		if not parameters is Dictionary:
			push_error(
				"Runtime component parameters must be a Dictionary: %s"
				% component_id
			)
			return false

		var component := entity.add_component(
			component_id,
			parameters
		)

		if not component:
			push_error(
				"Could not add runtime component: %s"
				% component_id
			)
			return false

	return true

func submit_movement_input(entity: Entity, sequence: int, direction: Vector2) -> void:
	if not entity:
		return

	# Normal singleplayer behavior.
	if not MultiplayerManager.session_active:
		_set_entity_movement_input(entity,direction)
		return

	var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	if not controller.is_locally_controlled():
		return

	# Host player can submit directly to the authoritative simulation.
	if multiplayer.is_server():
		_apply_movement_input(multiplayer.get_unique_id(),entity.instance_id,sequence,direction)
		return

	# Client prediction:
	# move our local copy immediately.
	_set_entity_movement_input(
		entity,
		direction,
		sequence
	)

	# Tell the authoritative host what input we used.
	_receive_movement_input.rpc_id(1,entity.instance_id,sequence,direction)

@rpc("any_peer","call_remote","unreliable_ordered",1)
func _receive_movement_input(entity_instance_id: String,sequence: int,direction: Vector2) -> void:
	if not multiplayer.is_server():
		return

	var sender_peer_id := multiplayer.get_remote_sender_id()

	_apply_movement_input(sender_peer_id,entity_instance_id,sequence,direction)

func _apply_movement_input(sender_peer_id: int,entity_instance_id: String,sequence: int,direction: Vector2) -> void:
	var entity := RuntimeObjectRegistry.get_entity(entity_instance_id)

	if not entity:
		return

	var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	# This is the important authority check.
	# A client cannot submit movement for somebody else's controller.
	if controller.controller_peer_id != sender_peer_id:
		return

	var last_sequence := int(
		_last_movement_sequence.get(
			sender_peer_id,
			-1
		)
	)

	if sequence <= last_sequence:
		return

	_last_movement_sequence[sender_peer_id] = sequence

	_set_entity_movement_input(
		entity,
		direction,
		sequence
	)

func _set_entity_movement_input(
	entity: Entity,
	direction: Vector2,
	sequence: int = -1
) -> void:
	var movement := entity.get_component(
		&"base:movement"
	) as MovementComponent

	if not movement:
		return

	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	movement.input_direction = direction

	if sequence >= 0:
		movement.input_sequence = sequence


func record_simulated_movement(
	entity: Entity,
	sequence: int
) -> void:
	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	if not entity or sequence < 0:
		return

	var controller := entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	_last_simulated_movement_sequence[
		controller.controller_peer_id
	] = sequence


func _send_movement_snapshot() -> void:
	var states: Array = []

	for entity in get_entities():
		if not entity.has_component(&"base:movement"):
			continue

		var last_input_sequence := -1

		var controller := entity.get_component(
			&"base:player_controller"
		) as PlayerControllerComponent

		if controller:
			last_input_sequence = int(
				_last_simulated_movement_sequence.get(
					controller.controller_peer_id,
					-1
				)
			)

		states.append({
			"instance_id": entity.instance_id,
			"position": entity.global_position,
			"velocity": entity.velocity,
			"last_input_sequence": last_input_sequence
		})

	if states.is_empty():
		return

	_receive_movement_snapshot.rpc(states)

@rpc("authority","call_remote","unreliable_ordered",2)
func _receive_movement_snapshot(
	states: Array
) -> void:
	if multiplayer.is_server():
		return

	for state_value in states:
		if not state_value is Dictionary:
			continue

		var state := state_value as Dictionary
		var instance_id := String(
			state.get("instance_id", "")
		)
		var server_position = state.get(
			"position",
			Vector2.ZERO
		)
		var velocity = state.get(
			"velocity",
			Vector2.ZERO
		)
		var last_input_sequence := int(
			state.get("last_input_sequence", -1)
		)

		if instance_id.is_empty():
			continue

		if not server_position is Vector2:
			continue

		if not velocity is Vector2:
			continue

		var entity := RuntimeObjectRegistry.get_entity(
			instance_id
		)

		if not entity:
			continue

		var controller := entity.get_component(
			&"base:player_controller"
		) as PlayerControllerComponent

		if controller and controller.is_locally_controlled():
			controller.reconcile_prediction(
				last_input_sequence,
				server_position
			)
			continue

		_network_positions[instance_id] = server_position
		_network_velocities[instance_id] = velocity

		_apply_remote_snapshot(
			entity,
			instance_id,
			server_position
		)


func _apply_remote_snapshot(
	entity: Entity,
	instance_id: String,
	target_position: Vector2
) -> void:
	var sprite := entity.get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	var old_entity_position := entity.global_position
	var movement_distance := old_entity_position.distance_to(
		target_position
	)

	if sprite and not _remote_sprite_rest_positions.has(
		instance_id
	):
		_remote_sprite_rest_positions[instance_id] = (
			sprite.position
		)

	var old_visual_position := Vector2.ZERO

	if sprite:
		old_visual_position = sprite.global_position

	# Physics/collision uses the newest authoritative snapshot immediately.
	entity.global_position = target_position

	if not sprite:
		return

	var rest_position := _remote_sprite_rest_positions.get(
		instance_id,
		sprite.position
	) as Vector2

	if movement_distance > REMOTE_VISUAL_TELEPORT_DISTANCE:
		sprite.position = rest_position
		return

	# Preserve the previous rendered position, then visually catch the sprite
	# up to the body's authoritative physics transform.
	sprite.global_position = old_visual_position


func _interpolate_remote_visual(
	entity: Entity,
	instance_id: String,
	delta: float
) -> void:
	var sprite := entity.get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if not sprite:
		return

	if not _remote_sprite_rest_positions.has(instance_id):
		_remote_sprite_rest_positions[instance_id] = (
			sprite.position
		)

	var rest_position := _remote_sprite_rest_positions[
		instance_id
	]

	var interpolation_amount := (
		1.0
		- exp(
			-REMOTE_VISUAL_INTERPOLATION_SPEED
			* delta
		)
	)

	sprite.position = sprite.position.lerp(
		rest_position,
		interpolation_amount
	)

func submit_command(
	command_id: StringName,
	actor: Entity,
	arguments: Dictionary = {}
) -> void:
	if not actor:
		return

	var controller := actor.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if not controller.is_locally_controlled():
		return

	if MultiplayerManager.is_world_authority():
		_apply_command(
			multiplayer.get_unique_id(),
			command_id,
			arguments
		)
		return

	_receive_command.rpc_id(
		1,
		String(command_id),
		arguments
	)

@rpc("any_peer", "call_remote", "reliable", 3)
func _receive_command(
	command_id_string: String,
	arguments: Dictionary
) -> void:
	if not MultiplayerManager.is_world_authority():
		return

	_apply_command(
		multiplayer.get_remote_sender_id(),
		StringName(command_id_string),
		arguments
	)

func _apply_command(
	sender_peer_id: int,
	command_id: StringName,
	arguments: Dictionary
) -> void:
	match command_id:
		COMMAND_INTERACTION:
			_apply_interaction_request(
				sender_peer_id,
				StringName(
					arguments.get("interaction_id", "")
				),
				String(
					arguments.get("interactor_id", "")
				),
				String(
					arguments.get("target_id", "")
				)
			)

		COMMAND_TAKE_ITEM:
			_apply_take_item_request(
				sender_peer_id,
				String(
					arguments.get("viewer_id", "")
				),
				String(
					arguments.get("source_id", "")
				),
				String(
					arguments.get("item_id", "")
				)
			)

		COMMAND_EQUIP_ITEM:
			_apply_equip_item_request(
				sender_peer_id,
				String(
					arguments.get("entity_id", "")
				),
				String(
					arguments.get("item_id", "")
				),
				StringName(
					arguments.get("slot", "")
				)
			)

		COMMAND_UNEQUIP_ITEM:
			_apply_unequip_item_request(
				sender_peer_id,
				String(
					arguments.get("entity_id", "")
				),
				StringName(
					arguments.get("slot", "")
				)
			)

		_:
			push_warning(
				"Unknown command ID: %s"
				% command_id
			)

func submit_interaction(
	interaction: Interaction,
	interactor: Entity,
	target: Entity
) -> void:
	if not interaction or not interactor or not target:
		return

	if not interaction.can_perform(
		interactor,
		target
	):
		return

	if not interaction.requires_authority():
		interaction.perform(
			interactor,
			target
		)
		return

	submit_command(
		COMMAND_INTERACTION,
		interactor,
		{
			"interaction_id": String(
				interaction.interaction_id
			),
			"interactor_id": interactor.instance_id,
			"target_id": target.instance_id
		}
	)

func _apply_interaction_request(
	sender_peer_id: int,
	interaction_id: StringName,
	interactor_instance_id: String,
	target_instance_id: String
) -> void:
	var interactor := RuntimeObjectRegistry.get_entity(
		interactor_instance_id
	)

	var target := RuntimeObjectRegistry.get_entity(
		target_instance_id
	)

	if not interactor or not target:
		return

	var controller := interactor.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	# Client may only act through the Entity it currently controls.
	if controller.controller_peer_id != sender_peer_id:
		return

	var interactable := target.get_component(
		&"base:interactable"
	) as InteractableComponent

	if not interactable:
		return

	# Reconstruct the interaction from the HOST'S world state.
	var selected_interaction: Interaction

	for interaction in interactable.get_interactions(interactor):
		if interaction.interaction_id == interaction_id:
			selected_interaction = interaction
			break

	if not selected_interaction:
		return

	if not selected_interaction.requires_authority():
		return

	if not selected_interaction.can_perform(
		interactor,
		target
	):
		return

	selected_interaction.perform(
		interactor,
		target
	)

func _track_authoritative_entity(entity: Entity) -> void:
	if not entity:
		return

	var added_callback := _on_tracked_component_added.bind(entity)
	var removing_callback := _on_tracked_component_removing.bind(entity)

	if not entity.component_added.is_connected(added_callback):
		entity.component_added.connect(added_callback)

	if not entity.component_removing.is_connected(removing_callback):
		entity.component_removing.connect(removing_callback)

	for component in entity.get_components():
		_track_component(entity, component)

func _track_authoritative_item(item: Item) -> void:
	if not item:
		return

	var added_callback := _on_tracked_item_component_added.bind(item)
	var removing_callback := _on_tracked_item_component_removing.bind(item)

	if not item.component_added.is_connected(added_callback):
		item.component_added.connect(added_callback)

	if not item.component_removing.is_connected(removing_callback):
		item.component_removing.connect(removing_callback)

	for component in item.get_components():
		_track_item_component(item, component)

func _track_item_component(
	item: Item,
	component: ItemComponent
) -> void:
	if not component:
		return

	var callback := _on_item_component_state_changed.bind(
		item,
		component.component_id
	)

	if not component.state_changed.is_connected(callback):
		component.state_changed.connect(callback)

func _untrack_item_component(
	item: Item,
	component: ItemComponent
) -> void:
	if not component:
		return

	var callback := _on_item_component_state_changed.bind(
		item,
		component.component_id
	)

	if component.state_changed.is_connected(callback):
		component.state_changed.disconnect(callback)

func _on_item_component_state_changed(
	item: Item,
	component_id: StringName
) -> void:
	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	if not item:
		return

	var component := item.get_component(component_id)

	if not component:
		return

	_receive_item_component_state.rpc(
		item.instance_id,
		String(component_id),
		component.serialize_state()
	)

@rpc("authority", "call_remote", "reliable", 5)
func _receive_item_component_state(
	item_instance_id: String,
	component_id_string: String,
	state: Dictionary
) -> void:
	if multiplayer.is_server():
		return

	var item := RuntimeObjectRegistry.get_item(
		item_instance_id
	)

	if not item:
		return

	var component_id := StringName(
		component_id_string
	)

	if not GameID.is_valid(component_id):
		return

	var component := item.get_component(component_id)

	if not component:
		return

	component.deserialize_state(state)

func _on_tracked_item_component_added(
	component_id: StringName,
	component: ItemComponent,
	item: Item
) -> void:
	_track_item_component(
		item,
		component
	)

	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	_receive_item_component_added.rpc(
		item.instance_id,
		String(component_id),
		component.serialize_state()
	)

@rpc("authority", "call_remote", "reliable", 5)
func _receive_item_component_added(
	item_instance_id: String,
	component_id_string: String,
	state: Dictionary
) -> void:
	if multiplayer.is_server():
		return

	var item := RuntimeObjectRegistry.get_item(
		item_instance_id
	)

	if not item:
		return

	var component_id := StringName(
		component_id_string
	)

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

func _on_tracked_item_component_removing(
	component_id: StringName,
	component: ItemComponent,
	item: Item
) -> void:
	if (
		MultiplayerManager.session_active
		and MultiplayerManager.is_world_authority()
	):
		_receive_item_component_removed.rpc(
			item.instance_id,
			String(component_id)
		)

	_untrack_item_component(
		item,
		component
	)

@rpc("authority", "call_remote", "reliable", 5)
func _receive_item_component_removed(
	item_instance_id: String,
	component_id_string: String
) -> void:
	if multiplayer.is_server():
		return

	var item := RuntimeObjectRegistry.get_item(
		item_instance_id
	)

	if not item:
		return

	var component_id := StringName(
		component_id_string
	)

	if not GameID.is_valid(component_id):
		return

	if not item.has_component(component_id):
		return

	item.remove_component(component_id)

func _untrack_authoritative_item(item: Item) -> void:
	if not item:
		return

	var added_callback := _on_tracked_item_component_added.bind(item)
	var removing_callback := _on_tracked_item_component_removing.bind(item)

	if item.component_added.is_connected(added_callback):
		item.component_added.disconnect(added_callback)

	if item.component_removing.is_connected(removing_callback):
		item.component_removing.disconnect(removing_callback)

	for component in item.get_components():
		_untrack_item_component(item, component)

func _on_tracked_component_added(
	component_id: StringName,
	component: EntityComponent,
	entity: Entity
) -> void:
	_track_component(
		entity,
		component
	)

	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	# PlayerController transfer has its own replication
	# because controller_peer_id is session-specific.
	if component_id == &"base:player_controller":
		return

	_receive_component_added.rpc(
		entity.instance_id,
		String(component_id),
		component.serialize_state()
	)

@rpc("authority", "call_remote", "reliable", 5)
func _receive_component_added(
	entity_instance_id: String,
	component_id_string: String,
	state: Dictionary
) -> void:
	if multiplayer.is_server():
		return

	var entity := RuntimeObjectRegistry.get_entity(
		entity_instance_id
	)

	if not entity:
		return

	var component_id := StringName(
		component_id_string
	)

	if not GameID.is_valid(component_id):
		return

	# Defensive: if it somehow already exists,
	# just accept the authoritative state.
	if entity.has_component(component_id):
		var existing := entity.get_component(
			component_id
		)

		existing.deserialize_state(state)
		return

	var component := entity.add_component(
		component_id
	)

	if not component:
		return

	component.deserialize_state(state)

@rpc("authority", "call_remote", "reliable", 5)
func _receive_component_removed(
	entity_instance_id: String,
	component_id_string: String
) -> void:
	if multiplayer.is_server():
		return

	var entity := RuntimeObjectRegistry.get_entity(
		entity_instance_id
	)

	if not entity:
		return

	var component_id := StringName(
		component_id_string
	)

	if not GameID.is_valid(component_id):
		return

	if not entity.has_component(component_id):
		return

	entity.remove_component(component_id)

func _on_tracked_component_removing(
	component_id: StringName,
	component: EntityComponent,
	entity: Entity
) -> void:
	if (
		MultiplayerManager.session_active
		and MultiplayerManager.is_world_authority()
		and component_id != &"base:player_controller"
	):
		_receive_component_removed.rpc(
			entity.instance_id,
			String(component_id)
		)

	_untrack_component(
		entity,
		component
	)

func _track_component(
	entity: Entity,
	component: EntityComponent
) -> void:
	if not component:
		return

	var callback := _on_component_state_changed.bind(
		entity,
		component.component_id
	)

	if not component.state_changed.is_connected(callback):
		component.state_changed.connect(callback)


func _untrack_component(
	entity: Entity,
	component: EntityComponent
) -> void:
	if not component:
		return

	var callback := _on_component_state_changed.bind(
		entity,
		component.component_id
	)

	if component.state_changed.is_connected(callback):
		component.state_changed.disconnect(callback)

func _on_component_state_changed(
	entity: Entity,
	component_id: StringName
) -> void:
	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	if not is_instance_valid(entity):
		return

	var component := entity.get_component(component_id)

	if not component:
		return

	_receive_component_state.rpc(
		entity.instance_id,
		String(component_id),
		component.serialize_state()
	)

@rpc("authority", "call_remote", "reliable", 5)
func _receive_component_state(
	entity_instance_id: String,
	component_id_string: String,
	state: Dictionary
) -> void:
	if multiplayer.is_server():
		return

	var entity := RuntimeObjectRegistry.get_entity(
		entity_instance_id
	)

	if not entity:
		return

	var component_id := StringName(component_id_string)

	if not GameID.is_valid(component_id):
		return

	var component := entity.get_component(component_id)

	if not component:
		return

	component.deserialize_state(state)

func submit_take_item(
	viewer: Entity,
	source: Entity,
	item: Item
) -> void:
	if not viewer or not source or not item:
		return

	submit_command(
		COMMAND_TAKE_ITEM,
		viewer,
		{
			"viewer_id": viewer.instance_id,
			"source_id": source.instance_id,
			"item_id": item.instance_id
		}
	)

func _apply_take_item_request(
	sender_peer_id: int,
	viewer_instance_id: String,
	source_instance_id: String,
	item_instance_id: String
) -> void:
	var viewer := RuntimeObjectRegistry.get_entity(
		viewer_instance_id
	)

	var source := RuntimeObjectRegistry.get_entity(
		source_instance_id
	)

	var item := RuntimeObjectRegistry.get_item(
		item_instance_id
	)

	if not viewer or not source or not item:
		return

	var controller := viewer.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	_perform_take_item(
		viewer,
		source,
		item
	)

func _perform_take_item(
	viewer: Entity,
	source: Entity,
	item: Item
) -> bool:
	if viewer == source:
		return false

	var viewer_inventory := viewer.get_component(
		&"base:inventory"
	) as InventoryComponent

	var source_inventory := source.get_component(
		&"base:inventory"
	) as InventoryComponent

	if not viewer_inventory or not source_inventory:
		return false

	if item not in source_inventory.items:
		return false

	var interactor := viewer.get_component(
		&"base:interactor"
	) as InteractorComponent

	if not interactor:
		return false

	if (
		viewer.global_position.distance_to(
			source.global_position
		) > interactor.reach
	):
		return false

	var taken_item := source_inventory.remove_item(item)

	if not taken_item:
		return false

	viewer_inventory.add_item(taken_item)

	return true

func submit_equip_item(
	entity: Entity,
	item: Item,
	slot: StringName
) -> void:
	if not entity or not item:
		return

	submit_command(
		COMMAND_EQUIP_ITEM,
		entity,
		{
			"entity_id": entity.instance_id,
			"item_id": item.instance_id,
			"slot": String(slot)
		}
	)

func _apply_equip_item_request(
	sender_peer_id: int,
	entity_instance_id: String,
	item_instance_id: String,
	slot: StringName
) -> void:
	var entity := RuntimeObjectRegistry.get_entity(
		entity_instance_id
	)

	var item := RuntimeObjectRegistry.get_item(
		item_instance_id
	)

	if not entity or not item:
		return

	var controller := entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	_perform_equip_item(
		entity,
		item,
		slot
	)

func _perform_equip_item(
	entity: Entity,
	item: Item,
	slot: StringName
) -> bool:
	var equipment := entity.get_component(
		&"base:equipment"
	) as EquipmentComponent

	if not equipment:
		return false

	return equipment.equip(
		slot,
		item
	)

func submit_unequip_item(
	entity: Entity,
	slot: StringName
) -> void:
	if not entity:
		return

	submit_command(
		COMMAND_UNEQUIP_ITEM,
		entity,
		{
			"entity_id": entity.instance_id,
			"slot": String(slot)
		}
	)

func _apply_unequip_item_request(
	sender_peer_id: int,
	entity_instance_id: String,
	slot: StringName
) -> void:
	var entity := RuntimeObjectRegistry.get_entity(
		entity_instance_id
	)

	if not entity:
		return

	var controller := entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	_perform_unequip_item(
		entity,
		slot
	)

func _perform_unequip_item(
	entity: Entity,
	slot: StringName
) -> bool:
	var equipment := entity.get_component(
		&"base:equipment"
	) as EquipmentComponent

	if not equipment:
		return false

	return equipment.unequip(slot) != null

func _on_peer_left(peer_id: int) -> void:
	if not MultiplayerManager.session_active:
		return

	if not MultiplayerManager.is_world_authority():
		return

	_last_movement_sequence.erase(peer_id)
	_last_simulated_movement_sequence.erase(peer_id)

	for entity in get_entities():
		var controller := entity.get_component(
			&"base:player_controller"
		) as PlayerControllerComponent

		if not controller:
			continue

		if controller.controller_peer_id != peer_id:
			continue

		_remove_disconnected_player_controller(
			entity,
			peer_id
		)

func _remove_disconnected_player_controller(
	entity: Entity,
	peer_id: int
) -> void:
	if not entity:
		return

	var controller := entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != peer_id:
		return

	var movement := entity.get_component(
		&"base:movement"
	) as MovementComponent

	if movement:
		movement.input_direction = Vector2.ZERO

	entity.velocity = Vector2.ZERO

	entity.remove_component(
		&"base:player_controller"
	)

	if MultiplayerManager.session_active:
		_receive_player_controller_removed.rpc(
			entity.instance_id,
			peer_id
		)

@rpc("authority", "call_remote", "reliable", 4)
func _receive_player_controller_removed(
	entity_instance_id: String,
	peer_id: int
) -> void:
	if multiplayer.is_server():
		return

	var entity := RuntimeObjectRegistry.get_entity(
		entity_instance_id
	)

	if not entity:
		return

	var controller := entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != peer_id:
		return

	var movement := entity.get_component(
		&"base:movement"
	) as MovementComponent

	if movement:
		movement.input_direction = Vector2.ZERO

	entity.velocity = Vector2.ZERO

	entity.remove_component(
		&"base:player_controller"
	)
