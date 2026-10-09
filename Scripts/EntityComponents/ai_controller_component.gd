extends EntityComponent
class_name AIControllerComponent

var movement_component : MovementComponent
var pc_component : PlayerControllerComponent

var direction_timer : float = 1.0
var dir : Vector2 = Vector2.ZERO
var enabled := true

func on_added() -> void:
	dir = new_direction()
	watch_sibling(&"base:movement", _set_movement_component)
	watch_sibling(&"base:player_controller", _set_pc_component)

func _set_movement_component(component: MovementComponent) -> void:
	movement_component = component

func _set_pc_component(component: PlayerControllerComponent) -> void:
	pc_component = component
	enabled = pc_component == null

func _process(delta: float) -> void:
	if not MultiplayerManager.is_world_authority():
		return

	if not enabled:
		return

	var combat_component := get_component(
		&"base:combat"
	) as CombatComponent

	if (
		combat_component
		and combat_component.current_combat
		and combat_component.current_combat.started
	):
		if movement_component:
			movement_component.input_direction = Vector2.ZERO

		if combat_component.current_combat.is_active(
			root_entity
		):
			_take_combat_turn(
				combat_component.current_combat
			)

		return

	if not movement_component:
		return

	direction_timer -= delta

	if direction_timer <= 0:
		dir = new_direction()
		direction_timer += 1

	movement_component.input_direction = dir

func new_direction() -> Vector2:
	var new_dir : Vector2
	new_dir.x = (randf()*2)-1
	new_dir.y = (randf()*2)-1
	return new_dir

func _take_combat_turn(
	combat: Combat
) -> void:
	var target := _get_nearest_opponent(
		combat
	)

	if target:
		_try_attack(
			target
		)

	# The attack may have killed the last opponent,
	# which would have ended this Combat.
	var combat_component := get_component(
		&"base:combat"
	) as CombatComponent

	if (
		combat_component
		and combat_component.current_combat == combat
		and combat.started
		and combat.is_active(root_entity)
	):
		combat.end_turn(
			root_entity
		)

func _get_nearest_opponent(
	combat: Combat
) -> Entity:
	var nearest: Entity
	var nearest_distance := INF

	for opponent in combat.get_opponents(
		root_entity
	):
		if not is_instance_valid(opponent):
			continue

		var distance := (
			root_entity.global_position.distance_squared_to(
				opponent.global_position
			)
		)

		if distance < nearest_distance:
			nearest = opponent
			nearest_distance = distance

	return nearest

func _try_attack(
	target: Entity
) -> bool:
	var interactable := target.get_component(
		&"base:interactable"
	) as InteractableComponent

	if not interactable:
		return false

	for interaction in interactable.get_interactions(
		root_entity
	):
		if interaction.interaction_id != &"base:attack":
			continue

		if not interaction.can_perform(
			root_entity,
			target
		):
			return false

		interaction.perform(
			root_entity,
			target
		)

		return true

	return false
