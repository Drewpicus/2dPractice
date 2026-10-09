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
