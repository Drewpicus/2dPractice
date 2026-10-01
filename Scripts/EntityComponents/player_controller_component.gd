extends EntityComponent
class_name PlayerControllerComponent

@export var movement_component : MovementComponent
@export var interaction_menu: InteractionMenu
@export var inventory_menu: InventoryMenu

@export var controller_peer_id: int = 0

const PREDICTION_HISTORY_LIMIT: int = 120
const PREDICTION_CORRECTION_SPEED: float = 12.0
const HARD_PREDICTION_CORRECTION_DISTANCE: float = 160.0

var movement_sequence: int = 0
var predicted_positions: Dictionary[int, Vector2] = {}
var pending_correction: Vector2 = Vector2.ZERO
var last_reconciled_sequence: int = -1

@onready var player_camera: Camera2D = $Camera2D

func on_added() -> void:
	predicted_positions.clear()
	pending_correction = Vector2.ZERO
	last_reconciled_sequence = -1
	watch_sibling(&"base:movement",_set_movement_component)

func _set_movement_component(component: MovementComponent) -> void:
	movement_component = component

func _ready() -> void:
	var component_folder = get_parent()
	if not component_folder:
		push_warning(self," has no Components node, Player Controller will be disabled")
		return
	if not inventory_menu:
		inventory_menu = get_tree().root.get_node_or_null("Main/UI/InventoryMenu")
	if not interaction_menu:
		interaction_menu = get_tree().root.get_node_or_null("Main/UI/InteractionMenu")
	
	_update_local_control()

func _physics_process(_delta: float) -> void:
	if not is_locally_controlled():
		return

	if not movement_component:
		return

	var direction := Input.get_vector("move_left","move_right","move_up","move_down")

	movement_sequence += 1

	var world := GameWorld.find_world(root_entity)

	if not world:
		return

	world.submit_movement_input(root_entity, movement_sequence, direction)

	if MultiplayerManager.session_active and not multiplayer.is_server():
		_apply_prediction_correction(_delta)

func record_predicted_position(sequence: int) -> void:
	if sequence < 0:
		return

	if not root_entity:
		return

	predicted_positions[sequence] = root_entity.global_position
	predicted_positions.erase(
		sequence - PREDICTION_HISTORY_LIMIT
	)


func reconcile_prediction(
	sequence: int,
	server_position: Vector2
) -> void:
	if sequence <= last_reconciled_sequence:
		return

	if not predicted_positions.has(sequence):
		return

	var predicted_position := predicted_positions[sequence]
	var correction := server_position - predicted_position

	last_reconciled_sequence = sequence
	_discard_acknowledged_predictions(sequence)

	if correction.length() > HARD_PREDICTION_CORRECTION_DISTANCE:
		root_entity.global_position += correction
		_shift_prediction_history(correction)
		pending_correction = Vector2.ZERO
		return

	# Keep only the newest estimate. Adding successive estimates together
	# would apply the same positional error more than once.
	pending_correction = correction


func _apply_prediction_correction(delta: float) -> void:
	if not root_entity:
		return

	if pending_correction.length_squared() < 0.0001:
		pending_correction = Vector2.ZERO
		return

	var correction_amount := (
		1.0 - exp(-PREDICTION_CORRECTION_SPEED * delta)
	)

	var correction_step := (
		pending_correction * correction_amount
	)

	root_entity.global_position += correction_step
	pending_correction -= correction_step

	# Future acknowledgements are compared against prediction history.
	# Shift that history by corrections we've already applied so the same
	# error is not counted again.
	_shift_prediction_history(correction_step)


func _shift_prediction_history(offset: Vector2) -> void:
	if offset == Vector2.ZERO:
		return

	for sequence in predicted_positions.keys():
		predicted_positions[sequence] += offset


func _discard_acknowledged_predictions(
	acknowledged_sequence: int
) -> void:
	for sequence in predicted_positions.keys():
		if sequence <= acknowledged_sequence:
			predicted_positions.erase(sequence)


func _unhandled_input(event: InputEvent) -> void:
	if not is_locally_controlled():
		return
	if event.is_action_pressed("inventory"):
		if inventory_menu.visible:
			inventory_menu.close_inventory()
		else:
			interaction_menu.hide()
			inventory_menu.show_inventory(root_entity, root_entity)
	if event.is_action_pressed("interact_menu"):
		var target := _get_entity_under_mouse()
		if not target:
			interaction_menu.hide()
			return
		var visible_interactions: Array
		if not target.has_component(&"base:interactable"):
			return
		visible_interactions = target.get_component(&"base:interactable").get_interactions(root_entity)
		if not visible_interactions.is_empty():
			interaction_menu.show_interactions(visible_interactions,root_entity,target)
	if event.is_action_pressed("select"):
		interaction_menu._on_empty_pressed()
	_quick_action(event,"quick_attack",&"base:health",&"base:attack")
	_quick_action(event,"quick_inspect",&"base:info",&"base:inspect",_get_entity_under_mouse(false))

func _quick_action(event: InputEvent, input: StringName, component: StringName, interaction: StringName, target: Variant = _get_entity_under_mouse()):
	if event.is_action_pressed(input):
		if not target:
			return
		if not target.has_component(component):
			return
		var interactions: Array[Interaction] = target.get_component(&"base:interactable").get_interactions(root_entity)
		var selected_interaction: Interaction
		if not interactions.is_empty():
			for created_interaction in interactions:
				if created_interaction.interaction_id == interaction:
					selected_interaction = created_interaction
					if selected_interaction:
						var world := GameWorld.find_world(root_entity)
						if not world:
							return
						world.submit_interaction(selected_interaction,root_entity,target)


##Returns the first Entity at your mouse position. 
##[param exclude_self] can be toggled off if you want to also include the root entity. 
##[param is_interactable] can be toggled off to include non-interactable entities. 
##[param include_areas] and [param include_bodies] set the PhysicsPointQueryParameters. 
func _get_entity_under_mouse(exclude_self: bool = true, is_interactable: bool = true, include_areas: bool = true, include_bodies: bool = false) -> Entity:
	if not root_entity:
		return null
	var mouse_position := root_entity.get_global_mouse_position()
	var world := root_entity.get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = mouse_position
	params.collide_with_areas = include_areas
	params.collide_with_bodies = include_bodies
	var intersections := world.intersect_point(params)
	for intersection in intersections:
		var collider := intersection["collider"] as Node
		var entity := Entity.find_entity(collider)

		if not entity:
			continue

		if exclude_self and entity == root_entity:
			continue

		if is_interactable and not entity.has_component(&"base:interactable"):
			continue

		return entity
	return null

## Returns this component's mutable runtime state.
func serialize_state() -> Dictionary:
	var zoom_x := player_camera.zoom.x
	var zoom_y := player_camera.zoom.y
	return {
		"camera_zoom": [zoom_x,zoom_y]
	}

## Restores this component's mutable runtime state.
func deserialize_state(_state: Dictionary) -> void:
	var zoom_array = _state.get("camera_zoom")
	player_camera.zoom.x = zoom_array[0]
	player_camera.zoom.y = zoom_array[1]

func set_controller_peer(peer_id: int) -> void:
	controller_peer_id = peer_id

	if is_node_ready():
		_update_local_control()


func is_locally_controlled() -> bool:
	if not MultiplayerManager.session_active:
		return true

	return controller_peer_id == multiplayer.get_unique_id()

func _update_local_control() -> void:
	player_camera.enabled = is_locally_controlled()
