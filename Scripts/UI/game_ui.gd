extends CanvasLayer
class_name GameUI


@onready var game_world: GameWorld = $"../GameWorld"
@onready var interaction_menu: InteractionMenu = $InteractionMenu
@onready var inventory_menu: InventoryMenu = $InventoryMenu
@onready var inspect_window: InspectWindow = $InspectWindow


func _ready() -> void:
	game_world.inspection_requested.connect(_on_inspection_requested)
	game_world.inventory_requested.connect(_on_inventory_requested)

func _unhandled_input(event: InputEvent) -> void:
	var controlled_entity := (game_world.get_locally_controlled_entity())

	if not controlled_entity:
		return

	if event.is_action_pressed("inventory"):
		_toggle_inventory(controlled_entity)

	if event.is_action_pressed("interact_menu"):
		_open_interaction_menu(controlled_entity)

	if event.is_action_pressed("select"):
		interaction_menu._on_empty_pressed()
	
	if event.is_action_pressed("close_menu"):
		interaction_menu.hide()
		inspect_window.hide()
		inventory_menu.close_inventory()


func _toggle_inventory(controlled_entity: Entity) -> void:
	if inventory_menu.visible:
		inventory_menu.close_inventory()
		return

	interaction_menu.hide()
	inspect_window.hide()

	inventory_menu.show_inventory(controlled_entity, controlled_entity)


func _open_interaction_menu(controlled_entity: Entity) -> void:
	var target := _get_entity_under_mouse(controlled_entity)

	if not target:
		interaction_menu.hide()
		return

	var interactable := target.get_component(
		&"base:interactable"
	) as InteractableComponent

	if not interactable:
		return

	var interactions := interactable.get_interactions(
		controlled_entity
	)

	if interactions.is_empty():
		return

	interaction_menu.show_interactions(
		interactions,
		controlled_entity,
		target
	)


func _get_entity_under_mouse(
	controlled_entity: Entity,
	exclude_self: bool = true,
	is_interactable: bool = true,
	include_areas: bool = true,
	include_bodies: bool = false
) -> Entity:
	if not controlled_entity:
		return null

	var mouse_position := (
		controlled_entity.get_global_mouse_position()
	)

	var space_state := (
		controlled_entity
		.get_world_2d()
		.direct_space_state
	)

	var params := PhysicsPointQueryParameters2D.new()

	params.position = mouse_position
	params.collide_with_areas = include_areas
	params.collide_with_bodies = include_bodies

	var intersections := space_state.intersect_point(
		params
	)

	for intersection in intersections:
		var collider := (
			intersection["collider"] as Node
		)

		var entity := Entity.find_entity(
			collider
		)

		if not entity:
			continue

		if (
			exclude_self
			and entity == controlled_entity
		):
			continue

		if (
			is_interactable
			and not entity.has_component(
				&"base:interactable"
			)
		):
			continue

		return entity

	return null

func _on_inspection_requested(
	_viewer: Entity,
	target: Entity
) -> void:
	interaction_menu.hide()
	inventory_menu.close_inventory()

	inspect_window.show_inspection(
		target
	)


func _on_inventory_requested(viewer: Entity, inv_owner: Entity) -> void:
	interaction_menu.hide()
	inspect_window.hide()

	inventory_menu.show_inventory(viewer,inv_owner)
