extends RefCounted
class_name DeathSystem


static func apply_death(
	source: Object,
	target: Entity,
	source_item: Item = null
) -> DeathResolution:
	if not target:
		return null

	var resolution := DeathResolution.new(
		source,
		target,
		source_item
	)

	if source is Entity:
		(source as Entity).contribute_to_resolution(
			resolution
		)

	if source is Item:
		(source as Item).contribute_to_resolution(
			resolution
		)

	if source_item:
		source_item.contribute_to_resolution(
			resolution
		)

	if target != source:
		target.contribute_to_resolution(
			resolution
		)

	resolution.apply_modifiers()

	if not resolution.allowed:
		return resolution

	var event := DeathAppliedEvent.new(
		source,
		target,
		resolution,
		source_item
	)

	target.dispatch_event(event)

	if source is Entity and source != target:
		(source as Entity).dispatch_event(event)

	if source is Item:
		(source as Item).dispatch_event(event)

	var world := GameWorld.find_world(
		target
	)

	if world:
		world.remove_entity(target)
	else:
		target.queue_free()

	return resolution
