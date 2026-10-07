extends RefCounted
class_name TeleportSystem


static func apply_teleport(
	source: Object,
	target: Entity,
	destination: Vector2,
	source_item: Item = null
) -> TeleportResolution:
	if not target:
		return null

	var resolution := TeleportResolution.new(
		source,
		target,
		destination,
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

	if resolution.cancelled:
		return resolution

	var world := GameWorld.find_world(target)

	if not world:
		return null

	if not world.movement_system.teleport_entity(
		target,
		resolution.destination
	):
		return null

	var event := TeleportAppliedEvent.new(
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

	return resolution
