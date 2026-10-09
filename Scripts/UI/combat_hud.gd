extends PanelContainer
class_name CombatHUD


@onready var game_world: GameWorld = $"../../GameWorld"

@onready var round_label: Label = $VBoxContainer/Round
@onready var active_label: Label = $VBoxContainer/Active
@onready var order_label: Label = $VBoxContainer/TurnOrder
@onready var movement_label: Label = $VBoxContainer/Movement
@onready var action_label: Label = $VBoxContainer/Action
@onready var reaction_label: Label = $VBoxContainer/Reaction
@onready var end_turn_button: Button = $VBoxContainer/EndTurn


func _ready() -> void:
	end_turn_button.pressed.connect(
		_on_end_turn_pressed
	)

	hide()


func _process(_delta: float) -> void:
	var entity := (
		game_world.get_locally_controlled_entity()
	)

	if not entity:
		hide()
		return

	var combat_component := entity.get_component(
		&"base:combat"
	) as CombatComponent

	if (
		not combat_component
		or not combat_component.current_combat
		or not combat_component.current_combat.started
	):
		hide()
		return

	var combat := combat_component.current_combat

	show()

	round_label.text = (
		"Round %d"
		% combat.round_number
	)

	active_label.text = (
		"Active: %s"
		% _entity_names(
			combat.active_combatants
		)
	)

	order_label.text = (
		"Order: %s"
		% _entity_names(
			combat.turn_order
		)
	)

	movement_label.text = (
		"Movement: %.1f / %.1f"
		% [
			combat_component.movement_remaining,
			combat_component.movement_per_turn
		]
	)

	action_label.text = (
		"Action: %s"
		% (
			"Ready"
			if combat_component.action_available
			else "Spent"
		)
	)

	reaction_label.text = (
		"Reaction: %s"
		% (
			"Ready"
			if combat_component.reaction_available
			else "Spent"
		)
	)

	end_turn_button.disabled = (
		not combat.is_active(entity)
	)


func _on_end_turn_pressed() -> void:
	var entity := (
		game_world.get_locally_controlled_entity()
	)

	if not entity:
		return

	game_world.submit_end_turn(
		entity
	)


func _entity_names(
	entities: Array[Entity]
) -> String:
	var names: Array[String] = []

	for entity in entities:
		if not is_instance_valid(entity):
			continue

		names.append(
			entity.entity_name
		)

	if names.is_empty():
		return "—"

	return ", ".join(names)
