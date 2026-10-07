extends Node
class_name WorldTickSystem


@export var tick_interval: float = 5.0

var _elapsed: float = 0.0
var _tick_index: int = 0

@onready var world: GameWorld = get_parent() as GameWorld


func _process(delta: float) -> void:
	if not MultiplayerManager.is_world_authority():
		return

	if tick_interval <= 0.0:
		return

	_elapsed += delta

	while _elapsed >= tick_interval:
		_elapsed -= tick_interval
		_run_tick()


func _run_tick() -> void:
	_tick_index += 1

	var event := WorldTickEvent.new(
		tick_interval,
		_tick_index
	)
	
	print("tick")

	for entity in world.get_entities():
		entity.dispatch_event(event)
