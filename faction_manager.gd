extends RefCounted
class_name FactionManager

const UNALIGNED_FACTION := &"base:unaligned"

const HOSTILE_THRESHOLD := -25
const FRIENDLY_THRESHOLD := 25

enum ATTITUDE {
	HOSTILE,
	NEUTRAL,
	FRIENDLY
}


static func get_entity_faction(
	entity: Entity
) -> StringName:
	if not entity:
		return UNALIGNED_FACTION

	var component := entity.get_component(
		&"base:faction"
	) as FactionComponent

	if not component:
		return UNALIGNED_FACTION

	if component.faction_id.is_empty():
		return UNALIGNED_FACTION

	return component.faction_id

static func get_relation(
	source_faction: StringName,
	target_faction: StringName
) -> int:
	var source := DefinitionRegistry.get_faction(
		source_faction
	)

	if not source:
		return 0

	return int(
		source.default_relations.get(
			target_faction,
			0
		)
	)

static func get_entity_relation(
	source: Entity,
	target: Entity
) -> int:
	return get_relation(
		get_entity_faction(source),
		get_entity_faction(target)
	)

static func classify_relation(
	score: int
) -> ATTITUDE:
	if score <= HOSTILE_THRESHOLD:
		return ATTITUDE.HOSTILE

	if score >= FRIENDLY_THRESHOLD:
		return ATTITUDE.FRIENDLY

	return ATTITUDE.NEUTRAL


static func get_entity_attitude(
	source: Entity,
	target: Entity
) -> ATTITUDE:
	return classify_relation(
		get_entity_relation(
			source,
			target
		)
	)

static func is_hostile(
	source: Entity,
	target: Entity
) -> bool:
	return (
		get_entity_attitude(
			source,
			target
		)
		== ATTITUDE.HOSTILE
	)


static func is_friendly(
	source: Entity,
	target: Entity
) -> bool:
	return (
		get_entity_attitude(
			source,
			target
		)
		== ATTITUDE.FRIENDLY
	)
