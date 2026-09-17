extends EntityComponent
class_name PlayerControllerComponent

@export var movement_component : MovementComponent
@export var hitbox : Area2D
@export var interaction_menu: InteractionMenu

func _ready() -> void:
	var component_folder = get_parent()
	if not component_folder:
		push_warning(self," has no Components node, Player Controller will be disabled")
		return
	
	if not movement_component:
		movement_component = component_folder.get_node_or_null("MovementComponent")
	if not hitbox:
		hitbox = component_folder.get_parent().get_node_or_null("Hitbox")
	if not interaction_menu:
		interaction_menu = get_tree().root.get_node_or_null("Main/UI/InteractionMenu")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("space") and hitbox:
		hitbox.activate_for_one_frame()
		print("hitbox active")
	if not movement_component:
		return
	var dir = Input.get_vector("move_left","move_right","move_up","move_down")
	movement_component.input_direction = dir

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact_menu"):
		var mouse_position := root_entity.get_global_mouse_position()
		var world := root_entity.get_world_2d().direct_space_state
		var params := PhysicsPointQueryParameters2D.new()
		params.position = mouse_position
		params.collide_with_areas = true
		params.collide_with_bodies = true
		var intersections := world.intersect_point(params)
		var visible_interactions: Array
		var found_target := false
		for intersection in intersections:
			if intersection["collider"] is Entity:
				if intersection["collider"] == root_entity:
					continue
				if not intersection["collider"].has_component(&"interactable"):
					continue
				visible_interactions = intersection["collider"].get_component(&"interactable").get_interactions(root_entity)
				if not visible_interactions.is_empty():
					interaction_menu.show_interactions(visible_interactions,root_entity,intersection["collider"])
					found_target = true
				break
		if not found_target:
			interaction_menu.hide.call_deferred()
	if event.is_action_pressed("select"):
		interaction_menu._on_empty_pressed()
