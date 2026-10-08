extends CanvasLayer
class_name GameUI


@onready var game_world: GameWorld = $"../GameWorld"
@onready var interaction_menu: InteractionMenu = $InteractionMenu
@onready var inventory_menu: InventoryMenu = $InventoryMenu
@onready var inspect_window: InspectWindow = $InspectWindow
@onready var ability_menu: AbilityMenu = $AbilityMenu
@onready var ability_targeting: AbilityTargeting = $AbilityTargeting


func _ready() -> void:
	game_world.inspection_requested.connect(_on_inspection_requested)
	game_world.inventory_requested.connect(_on_inventory_requested)
	ability_menu.ability_selected.connect(_on_ability_selected)
		
	ability_targeting.requirement_changed.connect(
		_on_ability_requirement_changed
	)

	inventory_menu.item_chosen.connect(
		_on_ability_item_chosen
	)

	inventory_menu.item_selection_cancelled.connect(
		_on_ability_item_selection_cancelled
	)

func _unhandled_input(event: InputEvent) -> void:
	var controlled_entity := (
		game_world.get_locally_controlled_entity()
	)

	if not controlled_entity:
		return

	if event.is_action_pressed("abilities"):
		if ability_targeting.is_targeting():
			ability_targeting.cancel()

		if ability_menu.visible:
			ability_menu.close_menu()
		else:
			interaction_menu.hide()
			inventory_menu.close_inventory()
			inspect_window.hide()

			ability_menu.show_abilities(
				controlled_entity
			)

		return

	if event.is_action_pressed("select"):
		if ability_targeting.is_targeting():
			_provide_ability_target(
				controlled_entity
			)

			get_viewport().set_input_as_handled()
			return

		# Shift + left click belongs to quick attack,
		# not ordinary click-to-move.
		if (
			event is InputEventMouseButton
			and event.shift_pressed
		):
			return

		interaction_menu._on_empty_pressed()

		game_world.submit_move_to(
			controlled_entity,
			controlled_entity.get_global_mouse_position()
		)

		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("inventory"):
		_toggle_inventory(controlled_entity)

	if event.is_action_pressed("interact_menu"):
		_open_interaction_menu(controlled_entity)

	if event.is_action_pressed("close_menu"):
		ability_targeting.cancel()
		ability_menu.close_menu()
		interaction_menu.hide()
		inspect_window.hide()
		inventory_menu.close_inventory()


func _toggle_inventory(
	controlled_entity: Entity
) -> void:
	if inventory_menu.visible:
		if inventory_menu.is_selecting_item():
			ability_targeting.cancel()

		inventory_menu.close_inventory()
		return

	if ability_targeting.is_targeting():
		ability_targeting.cancel()

	interaction_menu.hide()
	inspect_window.hide()

	inventory_menu.show_inventory(
		controlled_entity,
		controlled_entity
	)


func _open_interaction_menu(
	controlled_entity: Entity
) -> void:
	if ability_targeting.is_targeting():
		ability_targeting.cancel()

	var target := _get_entity_under_mouse(
		controlled_entity
	)

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

func _on_ability_selected(
	ability: Ability,
	user: Entity
) -> void:
	ability_targeting.begin(
		ability,
		user
	)


func _provide_ability_target(
	controlled_entity: Entity
) -> void:
	var requirement = (
		ability_targeting
		.get_current_requirement()
	)

	match requirement:
		Ability.TARGET_TYPE.POSITION:
			ability_targeting.provide_position(
				controlled_entity
				.get_global_mouse_position()
			)

		Ability.TARGET_TYPE.ENTITY:
			var target := _get_entity_under_mouse(
				controlled_entity,
				false,
				false,
				true,
				true
			)

			if target:
				ability_targeting.provide_entity(
					target
				)

func _on_ability_requirement_changed(
	requirement: Variant
) -> void:
	match requirement:
		Ability.TARGET_TYPE.ITEM:
			var controlled_entity := (
				game_world.get_locally_controlled_entity()
			)

			if not controlled_entity:
				ability_targeting.cancel()
				return

			interaction_menu.hide()
			inspect_window.hide()

			inventory_menu.show_inventory(
				controlled_entity,
				controlled_entity,
				true
			)

func _on_ability_item_chosen(
	item: Item
) -> void:
	if not ability_targeting.is_targeting():
		return

	ability_targeting.provide_item(item)


func _on_ability_item_selection_cancelled() -> void:
	if not ability_targeting.is_targeting():
		return

	if (
		ability_targeting.get_current_requirement()
		== Ability.TARGET_TYPE.ITEM
	):
		ability_targeting.cancel()
