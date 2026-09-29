extends EntityComponent
class_name MovementComponent

@export var base_speed : float = 200

var player_controller: PlayerControllerComponent
var input_direction : Vector2 = Vector2.ZERO

func on_added() -> void:
	watch_sibling(&"base:player_controller",_set_player_controller)

func _ready() -> void:
	call_deferred("_update_network_collision")

func _physics_process(_delta: float) -> void:
	if not root_entity:
		return

	if (MultiplayerManager.session_active and not MultiplayerManager.is_world_authority()):
		if not player_controller:
			return

		if not player_controller.is_locally_controlled():
			return

	root_entity.velocity = (input_direction.normalized() * base_speed)
	root_entity.move_and_slide()

func _set_player_controller(
	component: PlayerControllerComponent
) -> void:
	player_controller = component

	if is_node_ready():
		_update_network_collision()


func _update_network_collision() -> void:
	if not root_entity:
		return

	# Offline and host:
	# all real physics bodies participate normally.
	if MultiplayerManager.is_world_authority():
		root_entity.set_physical_collision_enabled(true)
		return

	# Client:
	# only our predicted controlled mover participates
	# in dynamic physics.
	var locally_controlled := (
		player_controller
		and player_controller.is_locally_controlled()
	)

	root_entity.set_physical_collision_enabled(
		locally_controlled
	)
