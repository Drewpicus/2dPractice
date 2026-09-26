extends EntityComponent
class_name PlayerControllerComponent

@export var movement_component : MovementComponent
@export var interaction_menu: InteractionMenu
@export var inventory_menu: InventoryMenu
@export var rotate_speed: float = 1.6

@onready var camera_pivot: Node3D = $CameraPivot
@onready var player_camera: Camera3D = $CameraPivot/Camera3D

func _ready() -> void:
	var component_folder = get_parent()
	if not component_folder:
		push_warning(self," has no Components node, Player Controller will be disabled")
		return
	if not inventory_menu:
		inventory_menu = get_tree().root.get_node_or_null("Main/UI/InventoryMenu")
	movement_component = get_component(&"base:movement")
	if not interaction_menu:
		interaction_menu = get_tree().root.get_node_or_null("Main/UI/InteractionMenu")

func _process(delta: float) -> void:
	if camera_pivot:
		var rotate_input := Input.get_axis("rotate_left", "rotate_right")
		if rotate_input != 0.0:
			camera_pivot.rotation.y -= rotate_input * rotate_speed * delta

	if not movement_component:
		return

	var input := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if not player_camera:
		movement_component.input_direction = input
		return

	var forward := -player_camera.global_basis.z
	var right := player_camera.global_basis.x

	forward.y = 0.0
	right.y = 0.0

	forward = forward.normalized()
	right = right.normalized()

	var world_direction := (
		right * input.x
		+ forward * -input.y
	)

	movement_component.input_direction = Vector2(
		world_direction.x,
		world_direction.z
	)

func _unhandled_input(event: InputEvent) -> void:
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
			if selected_interaction.can_perform(root_entity,target):
				selected_interaction.perform(root_entity,target)


##Returns the first Entity under the mouse via a 3D camera ray.
##[param exclude_self] can be toggled off if you want to also include the root entity.
##[param is_interactable] can be toggled off to include non-interactable entities.
##[param include_areas] and [param include_bodies] set the PhysicsRayQueryParameters3D.
func _get_entity_under_mouse(exclude_self: bool = true, is_interactable: bool = true, include_areas: bool = true, include_bodies: bool = true) -> Entity:
	if not player_camera:
		return null

	var mouse_position := get_viewport().get_mouse_position()
	var origin := player_camera.project_ray_origin(mouse_position)
	var direction := player_camera.project_ray_normal(mouse_position)
	var endpoint := origin + direction * 1000.0

	var query := PhysicsRayQueryParameters3D.create(origin, endpoint)
	query.collide_with_areas = include_areas
	query.collide_with_bodies = include_bodies

	if exclude_self:
		var exclude: Array[RID] = [root_entity.get_rid()]
		var interactable_node: Node = root_entity.get_component(&"base:interactable")
		if interactable_node is CollisionObject3D:
			exclude.append((interactable_node as CollisionObject3D).get_rid())
		query.exclude = exclude

	var result := root_entity.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null

	var collider := result["collider"] as Node
	var entity := Entity.find_entity(collider)

	if not entity:
		return null

	if exclude_self and entity == root_entity:
		return null

	if is_interactable and not entity.has_component(&"base:interactable"):
		return null

	return entity

## Returns this component's mutable runtime state.
func serialize_state() -> Dictionary:
	if not player_camera or not camera_pivot:
		return {}

	return {
		"camera_size": player_camera.size,
		"camera_yaw": camera_pivot.rotation.y
	}

## Restores this component's mutable runtime state.
func deserialize_state(_state: Dictionary) -> void:
	if not player_camera or not camera_pivot:
		return

	if _state.has("camera_size"):
		player_camera.size = float(_state["camera_size"])
	if _state.has("camera_yaw"):
		camera_pivot.rotation.y = float(_state["camera_yaw"])
