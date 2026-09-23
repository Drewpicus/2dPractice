##Gives the Entity health and max health, meaning it can be damaged,
##heal, and have its health depleted
# TODO: Implement way for health to scale with max health changes

extends EntityComponent
class_name HealthComponent

##Max health of entity, minimum 1
@export var max_health : int = 10
##Defaults to max health unless a starting health is chosen
@export var starting_health : int = -1

var _restoring_state: bool = false

var health: int:
	set(new_health):
		var old_health := health
		health = max(new_health, 0)

		if _restoring_state:
			return

		health_changed.emit(health)

		if health <= 0 and old_health > 0:
			health_depleted.emit()

signal health_changed(new_health : int)
signal max_health_changed(new_max_health : int)
signal health_depleted

func _ready() -> void:
	max_health = max(max_health,1)
	if starting_health > -1:
		health = starting_health
	else:
		health = max_health

#Action functions

##Damages Entity for [param amount] HP
func damage(amount: int) -> int:
	return _change_health(-1 * amount)
	
##Heals Entity for [param amount] HP
func heal(amount: int) -> int:
	return _change_health(amount)

##Changes health by amount, negative values will damage and positive values will heal.
##Returns new health.
func _change_health(amount : int) -> int:
	health = clamp(health + amount,0,max_health)
	return health

##Changes max health by amount, negative values lower it and positive values raise it.
##If clamp_health is true, health will be set to max if max is lowered below current health.
##Returns new max health.
func change_max_health(amount : int, clamp_health : bool = true) -> int:
	var old_max_health := max_health
	max_health = max(max_health+amount,1)
	if clamp_health:
		health = clamp(health,0,max_health)
	if max_health != old_max_health:
		max_health_changed.emit(max_health)
	return max_health

##Sets health to amount. If respect_max is true, it automatically trims any health excess of max.
##Returns new health.
func set_health(amount : int, respect_max : bool = true) -> int:
	health = max(amount,0)
	if respect_max:
		health = min(health,max_health)
	return health

##Sets max health to amount.
##If clamp_health is true, health will be set to max if max is lowered below current health.
##Returns new max health.
func set_max_health(amount : int, clamp_health : bool = true) -> int:
	var old_max_health := max_health
	max_health = max(amount,1)
	if clamp_health:
		health = clamp(health,0,max_health)
	if max_health != old_max_health:
		max_health_changed.emit(max_health)
	return max_health

##Returns health
func get_health() -> int:
	return health

##Returns max health
func get_max_health() -> int:
	return max_health

##True if health is greater than 0
func is_alive() -> bool:
	return health > 0

##True if health is greater than or equal to max
func is_full_health() -> bool:
	return health >= max_health

##This component allows the Entity to be able to be attacked
func get_interaction_suggestions() -> Array[StringName]:
	return [&"base:attack"]

##This component saves this component's state
func serialize_state() -> Dictionary:
	return {
		"health": health,
		"max_health": max_health
	}

##This component loads this component's state quietly
func deserialize_state(state: Dictionary) -> void:
	_restoring_state = true

	if state.has("max_health"):
		max_health = int(state["max_health"])

	if state.has("health"):
		health = int(state["health"])

	_restoring_state = false
