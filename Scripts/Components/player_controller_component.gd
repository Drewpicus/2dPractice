extends EntityComponent
class_name PlayerControllerComponent

@export var movement_component : MovementComponent
@export var interaction_menu: InteractionMenu
@export var inventory_menu: InventoryMenu

func _ready() -> void:
	var component_folder = get_parent()
	if not component_folder:
		push_warning(self," has no Components node, Player Controller will be disabled")
		return
	if not inventory_menu:
		inventory_menu = get_tree().root.get_node_or_null("Main/UI/InventoryMenu")
	movement_component = get_component(&"movement")
	if not interaction_menu:
		interaction_menu = get_tree().root.get_node_or_null("Main/UI/InteractionMenu")

func _process(_delta: float) -> void:
	if not movement_component:
		return
	var dir = Input.get_vector("move_left","move_right","move_up","move_down")
	movement_component.input_direction = dir

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
		if not target.has_component(&"interactable"):
			return
		visible_interactions = target.get_component(&"interactable").get_interactions(root_entity)
		if not visible_interactions.is_empty():
			interaction_menu.show_interactions(visible_interactions,root_entity,target)
	if event.is_action_pressed("select"):
		interaction_menu._on_empty_pressed()
	_quick_action(event,"quick_attack",&"health",&"attack")
	_quick_action(event,"quick_inspect",&"info",&"inspect",_get_entity_under_mouse(false))
	_quick_action(event,"test",&"inventory",&"pickpocket")

func _quick_action(event: InputEvent, input: StringName, component: StringName, interaction: StringName, target: Variant = _get_entity_under_mouse()):
	if event.is_action_pressed(input):
		if not target:
			return
		if not target.has_component(component):
			return
		var interactions: Array[Interaction] = target.get_component(&"interactable").get_interactions(root_entity)
		var selected_interaction: Interaction
		if not interactions.is_empty():
			for created_interaction in interactions:
				if created_interaction.interaction_id == interaction:
					selected_interaction = created_interaction
		if selected_interaction:
			if selected_interaction.can_perform(root_entity,target):
				selected_interaction.perform(root_entity,target)


##Returns the first Entity at your mouse position. 
##[param exclude_self] can be toggled off if you want to also include the root entity. 
##[param is_interactable] can be toggled off to include non-interactable entities. 
##[param include_areas] and [param include_bodies] set the PhysicsPointQueryParameters. 
func _get_entity_under_mouse(exclude_self: bool = true, is_interactable: bool = true, include_areas: bool = true, include_bodies: bool = true) -> Entity:
	var mouse_position := root_entity.get_global_mouse_position()
	var world := root_entity.get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = mouse_position
	params.collide_with_areas = include_areas
	params.collide_with_bodies = include_bodies
	var intersections := world.intersect_point(params)
	for intersection in intersections:
		if intersection["collider"] is Entity:
			if exclude_self:
				if intersection["collider"] == root_entity:
					continue
			if is_interactable:
				if not intersection["collider"].has_component(&"interactable"):
					continue
			return intersection["collider"]
	return null
