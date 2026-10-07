##Contains a reference to the type of remains left behind by this Entity when
##they die, be it a corpse or a puddle of goo. Remains inherit inventory.

extends EntityComponent
class_name RemainsComponent

@export var remains_id: StringName

func spawn_remains() -> Entity:
	if not GameID.is_valid(remains_id):
		push_error(
			"Invalid remains ID: %s"
			% remains_id
		)
		return null

	var world := GameWorld.find_world(
		root_entity
	)

	if not world:
		push_error(
			"Could not find GameWorld for remains spawn."
		)
		return null

	var inventory := get_component(
		&"base:inventory"
	) as InventoryComponent

	var initial_states := {}

	if inventory:
		initial_states[
			"base:inventory"
		] = inventory.serialize_state()

	var remains_entity := world.spawn_entity(
		remains_id,
		root_entity.global_position,
		{},
		initial_states
	)

	if not remains_entity:
		return null

	if inventory:
		inventory.take_all_items()

	return remains_entity

func on_event(event: GameEvent) -> void:
	if not event is DeathAppliedEvent:
		return

	var death_event := event as DeathAppliedEvent

	if death_event.target != root_entity:
		return

	spawn_remains()
