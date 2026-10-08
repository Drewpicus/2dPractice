extends Label
class_name DebugHUD


@onready var game_world: GameWorld = $"../../GameWorld"


func _process(_delta: float) -> void:
	var entity := game_world.get_locally_controlled_entity()

	if not entity:
		text = "No controlled entity"
		return

	var lines: Array[String] = []

	lines.append(
		"ENTITY: %s" % entity.entity_name
	)

	_add_health(lines, entity)
	_add_statuses(lines, entity)
	_add_equipment(lines, entity)

	text = "\n".join(lines)


func _add_health(
	lines: Array[String],
	entity: Entity
) -> void:
	var health := entity.get_component(
		&"base:health"
	) as HealthComponent

	lines.append("")

	if not health:
		lines.append("HEALTH: —")
		return

	lines.append(
		"HEALTH: %d / %d"
		% [
			health.health,
			health.max_health
		]
	)


func _add_statuses(
	lines: Array[String],
	entity: Entity
) -> void:
	lines.append("")
	lines.append("STATUS")

	var status := entity.get_component(
		&"base:status"
	) as StatusComponent

	if not status or status.effects.is_empty():
		lines.append("  None")
		return

	for effect in status.effects:
		if not effect:
			continue

		var effect_name := _pretty_id(
			effect.effect_id
		)

		if effect.duration < 0.0:
			lines.append(
				"  %s — indefinite"
				% effect_name
			)
		else:
			lines.append(
				"  %s — %s ticks"
				% [
					effect_name,
					str(effect.duration)
				]
			)


func _add_equipment(
	lines: Array[String],
	entity: Entity
) -> void:
	lines.append("")
	lines.append("EQUIPMENT")

	var equipment := entity.get_component(
		&"base:equipment"
	) as EquipmentComponent

	if not equipment:
		lines.append("  None")
		return

	for slot_value in equipment.slots:
		var slot := StringName(slot_value)

		var item := equipment.get_equipment(
			slot
		)

		var item_name := "—"

		if item:
			item_name = item.item_name

			if item_name.is_empty():
				item_name = _pretty_id(
					item.item_id
				)

		lines.append(
			"  %s: %s"
			% [
				String(slot).capitalize(),
				item_name
			]
		)


func _pretty_id(
	id: StringName
) -> String:
	var id_string := String(id)

	var colon_index := id_string.find(":")

	if colon_index >= 0:
		id_string = id_string.substr(
			colon_index + 1
		)

	return id_string.replace(
		"_",
		" "
	).capitalize()
