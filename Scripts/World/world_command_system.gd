extends Node
class_name WorldCommandSystem


const COMMAND_INTERACTION := &"base:interaction"
const COMMAND_TAKE_ITEM := &"base:take_item"
const COMMAND_EQUIP_ITEM := &"base:equip_item"
const COMMAND_UNEQUIP_ITEM := &"base:unequip_item"
const COMMAND_DROP_ITEM := &"base:drop_item"
const COMMAND_CONSUME_ITEM := &"base:consume_item"
const COMMAND_ABILITY := &"base:ability"
const COMMAND_END_TURN := &"base:end_turn"

func _submit_command(command_id: StringName, actor: Entity, arguments: Dictionary = {}) -> void:
	if not actor:
		return

	var controller := actor.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	if not controller.is_locally_controlled():
		return

	if MultiplayerManager.is_world_authority():
		_apply_command(multiplayer.get_unique_id(), command_id, arguments)
		return

	_receive_command.rpc_id(1, String(command_id), arguments)


@rpc("any_peer", "call_remote", "reliable", 3)
func _receive_command(command_id_string: String, arguments: Dictionary) -> void:
	if not MultiplayerManager.is_world_authority():
		return

	_apply_command(multiplayer.get_remote_sender_id(), StringName(command_id_string), arguments)

func _apply_command(sender_peer_id: int, command_id: StringName, arguments: Dictionary) -> void:
	match command_id:
		COMMAND_INTERACTION:
			_apply_interaction(
				sender_peer_id,
				StringName(arguments.get("interaction_id", "")),
				String(arguments.get("interactor_id", "")),
				String(arguments.get("target_id", "")))

		COMMAND_TAKE_ITEM:
			_apply_take_item(
				sender_peer_id,
				String(arguments.get("viewer_id", "")),
				String(arguments.get("source_id", "")),
				String(arguments.get("item_id", "")))

		COMMAND_EQUIP_ITEM:
			_apply_equip_item(
				sender_peer_id,
				String(arguments.get("entity_id", "")),
				String(arguments.get("item_id", "")),
				StringName(arguments.get("slot", "")))

		COMMAND_UNEQUIP_ITEM:
			_apply_unequip_item(
				sender_peer_id,
				String(arguments.get("entity_id", "")),
				StringName(arguments.get("slot", "")))
		
		COMMAND_DROP_ITEM:
			_apply_drop_item(
				sender_peer_id,
				String(arguments.get("entity_id", "")),
				String(arguments.get("item_id", "")))
		
		COMMAND_ABILITY:
			_apply_ability(
				sender_peer_id,
				StringName(arguments.get("ability_id", "")),
				String(arguments.get("user_id", "")),
				String(arguments.get("target_entity_id", "")),
				arguments.get("target_position", Vector2.ZERO),
				bool(arguments.get("has_target_position", false)),
				String(arguments.get("item_id", ""))
			)
		
		COMMAND_CONSUME_ITEM:
			_apply_consume_item(
				sender_peer_id,
				String(arguments.get("consumer_id", "")),
				String(arguments.get("item_id", ""))
			)

		COMMAND_END_TURN:
			_apply_end_turn(
				sender_peer_id,
				String(arguments.get("entity_id", ""))
			)

		_:
			push_warning("Unknown command ID :( : %s" % command_id)


func submit_interaction(interaction: Interaction, interactor: Entity, target: Entity) -> void:
	if not interaction or not interactor or not target:
		return

	if not interaction.can_perform(interactor, target):
		return

	if not interaction.requires_authority():
		interaction.perform(interactor, target)
		return

	_submit_command(COMMAND_INTERACTION, interactor,
		{
			"interaction_id": String(interaction.interaction_id),
			"interactor_id": interactor.instance_id,
			"target_id": target.instance_id
		}
	)


func _apply_interaction(sender_peer_id: int, interaction_id: StringName, interactor_instance_id: String, target_instance_id: String) -> void:
	var interactor := RuntimeObjectRegistry.get_entity(interactor_instance_id)

	var target := RuntimeObjectRegistry.get_entity(target_instance_id)

	if not interactor or not target:
		return

	var controller := interactor.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	var interactable := target.get_component(&"base:interactable") as InteractableComponent

	if not interactable:
		return

	var selected_interaction: Interaction

	for interaction in interactable.get_interactions(interactor):
		if interaction.interaction_id == interaction_id:
			selected_interaction = interaction
			break

	if not selected_interaction:
		return

	if not selected_interaction.requires_authority():
		return

	if selected_interaction.is_hostile():
		if not CombatManager.engage_hostile(
			interactor,
			target
		):
			return

	if not selected_interaction.can_perform(interactor, target):
		return

	selected_interaction.perform(interactor, target)


func submit_take_item(viewer: Entity, source: Entity, item: Item) -> void:
	if not viewer or not source or not item:
		return

	_submit_command(COMMAND_TAKE_ITEM, viewer,
		{
			"viewer_id": viewer.instance_id,
			"source_id": source.instance_id,
			"item_id": item.instance_id
		}
	)


func _apply_take_item(sender_peer_id: int, viewer_instance_id: String, source_instance_id: String, item_instance_id: String) -> void:
	var viewer := RuntimeObjectRegistry.get_entity(viewer_instance_id)

	var source := RuntimeObjectRegistry.get_entity(source_instance_id)

	var item := RuntimeObjectRegistry.get_item(item_instance_id)

	if not viewer or not source or not item:
		return

	var controller := viewer.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	_perform_take_item(viewer, source, item)


func _perform_take_item(viewer: Entity, source: Entity, item: Item) -> bool:
	if viewer == source:
		return false

	var viewer_inventory := viewer.get_component(&"base:inventory") as InventoryComponent

	var source_inventory := source.get_component(&"base:inventory") as InventoryComponent

	if not viewer_inventory or not source_inventory:
		return false

	if item not in source_inventory.items:
		return false

	var interactor := viewer.get_component(&"base:interactor") as InteractorComponent

	if not interactor:
		return false

	if (viewer.global_position.distance_to(source.global_position) > interactor.reach):
		return false

	if not _can_access_inventory(viewer, source):
		return false

	var taken_item := source_inventory.remove_item(item)

	if not taken_item:
		return false

	viewer_inventory.add_item(taken_item)

	return true


## True when the viewer could open this inventory through a real interaction.
## A lock blocks the interaction, so it also blocks the take command.
func _can_access_inventory(viewer: Entity, source: Entity) -> bool:
	var interactable := source.get_component(
		&"base:interactable"
	) as InteractableComponent

	if not interactable:
		return false

	for interaction in interactable.get_interactions(viewer):
		var opens_inventory := (
			interaction.interaction_id == &"base:open_inventory"
			or interaction.interaction_id == &"base:pickpocket"
		)

		if not opens_inventory:
			continue

		if not interaction.should_show(viewer, source):
			continue

		if interaction.can_perform(viewer, source):
			return true

	return false


func submit_equip_item(entity: Entity, item: Item, slot: StringName) -> void:
	if not entity or not item:
		return

	_submit_command(COMMAND_EQUIP_ITEM, entity,
		{
			"entity_id": entity.instance_id,
			"item_id": item.instance_id,
			"slot": String(slot)
		}
	)


func _apply_equip_item(sender_peer_id: int, entity_instance_id: String, item_instance_id: String, slot: StringName) -> void:
	var entity := RuntimeObjectRegistry.get_entity(entity_instance_id)

	var item := RuntimeObjectRegistry.get_item(item_instance_id)

	if not entity or not item:
		return

	var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	_perform_equip_item(entity, item, slot)


func _perform_equip_item(entity: Entity, item: Item, slot: StringName) -> bool:
	var equipment := entity.get_component(&"base:equipment") as EquipmentComponent

	if not equipment:
		return false

	return equipment.equip(slot, item)


func submit_unequip_item(entity: Entity, slot: StringName) -> void:
	if not entity or not slot:
		return

	_submit_command(COMMAND_UNEQUIP_ITEM, entity,
		{
			"entity_id": entity.instance_id,
			"slot": String(slot)
		}
	)


func _apply_unequip_item(sender_peer_id: int, entity_instance_id: String, slot: StringName) -> void:
	var entity := RuntimeObjectRegistry.get_entity(entity_instance_id)

	if not entity:
		return

	var controller := entity.get_component(&"base:player_controller") as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	_perform_unequip_item(entity, slot)


func _perform_unequip_item(entity: Entity, slot: StringName) -> bool:
	var equipment := entity.get_component(&"base:equipment") as EquipmentComponent

	if not equipment:
		return false

	return equipment.unequip(slot) != null

func submit_drop_item(
	entity: Entity,
	item: Item
) -> void:
	if not entity or not item:
		return

	_submit_command(
		COMMAND_DROP_ITEM,
		entity,
		{
			"entity_id": entity.instance_id,
			"item_id": item.instance_id
		}
	)


func _apply_drop_item(
	sender_peer_id: int,
	entity_instance_id: String,
	item_instance_id: String
) -> void:
	var entity := RuntimeObjectRegistry.get_entity(
		entity_instance_id
	)

	var item := RuntimeObjectRegistry.get_item(
		item_instance_id
	)

	if not entity or not item:
		return

	var controller := entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	_perform_drop_item(
		entity,
		item
	)


func _perform_drop_item(
	entity: Entity,
	item: Item
) -> bool:
	var inventory := entity.get_component(
		&"base:inventory"
	) as InventoryComponent

	if not inventory:
		return false

	if item not in inventory.items:
		return false

	var removed_item := inventory.remove_item(
		item
	)

	if not removed_item:
		return false

	var world := GameWorld.find_world(entity)

	if not world:
		inventory.add_item(removed_item)
		return false

	var dropped_item := world.spawn_dropped_item(
		removed_item,
		entity.global_position
	)

	if not dropped_item:
		inventory.add_item(removed_item)
		return false

	return true

func submit_ability(
	ability: Ability,
	use: AbilityUse
) -> void:
	if not ability or not use:
		return

	if not use.user:
		return

	var abilities := use.user.get_component(
		&"base:ability"
	) as AbilityComponent

	if not abilities:
		return

	if not abilities.has_ability(ability.ability_id):
		return

	_submit_command(
		COMMAND_ABILITY,
		use.user,
		{
			"ability_id": String(ability.ability_id),
			"user_id": use.user.instance_id,
			"target_entity_id":
				use.target_entity.instance_id
				if use.target_entity
				else "",
			"target_position": use.target_position,
			"has_target_position":
				use.has_target_position,
			"item_id":
				use.item.instance_id
				if use.item
				else ""
		}
	)

func _apply_ability(
	sender_peer_id: int,
	ability_id: StringName,
	user_instance_id: String,
	target_entity_instance_id: String,
	target_position: Variant,
	has_target_position: bool,
	item_instance_id: String
) -> void:
	var user := RuntimeObjectRegistry.get_entity(
		user_instance_id
	)

	if not user:
		return

	var controller := user.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	var abilities := user.get_component(
		&"base:ability"
	) as AbilityComponent

	if not abilities:
		return

	if not abilities.has_ability(ability_id):
		return

	var ability := abilities.get_ability(
		ability_id
	)

	if not ability:
		return

	var use := AbilityUse.new()
	use.user = user

	if not target_entity_instance_id.is_empty():
		use.target_entity = (
			RuntimeObjectRegistry.get_entity(
				target_entity_instance_id
			)
		)

	if has_target_position:
		if not target_position is Vector2:
			return

		use.set_target_position(
			target_position as Vector2
		)

	if not item_instance_id.is_empty():
		use.item = RuntimeObjectRegistry.get_item(
			item_instance_id
		)

	if not ability.can_use(use):
		return

	if not ability.can_pay_combat_cost(
		user
	):
		return

	if not ability.perform(use):
		return

	ability.spend_combat_cost(
		user
	)

func submit_consume_item(
	consumer: Entity,
	item: Item
) -> void:
	if not consumer or not item:
		return

	_submit_command(
		COMMAND_CONSUME_ITEM,
		consumer,
		{
			"consumer_id": consumer.instance_id,
			"item_id": item.instance_id
		}
	)


func _apply_consume_item(
	sender_peer_id: int,
	consumer_instance_id: String,
	item_instance_id: String
) -> void:
	var consumer := RuntimeObjectRegistry.get_entity(
		consumer_instance_id
	)

	var item := RuntimeObjectRegistry.get_item(
		item_instance_id
	)

	if not consumer or not item:
		return

	var controller := consumer.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	_perform_consume_item(
		consumer,
		item
	)


func _perform_consume_item(
	consumer: Entity,
	item: Item
) -> bool:
	var inventory := consumer.get_component(
		&"base:inventory"
	) as InventoryComponent

	if not inventory:
		return false

	if item not in inventory.items:
		return false

	var consumable := item.get_component(
		&"base:consumable"
	) as ConsumableItemComponent

	if not consumable:
		return false

	if not consumable.can_consume(
		consumer
	):
		return false

	var remainder_item_id := consumable.remainder_item_id

	if not consumable.apply_to(
		consumer
	):
		return false

	# Applying the Consumable may itself have removed the
	# InventoryComponent, so reacquire it afterward.
	inventory = consumer.get_component(
		&"base:inventory"
	) as InventoryComponent

	if inventory and item in inventory.items:
		inventory.remove_item(
			item
		)

	var world := GameWorld.find_world(
		consumer
	)

	if not world:
		return false

	world.remove_item(
		item
	)

	if remainder_item_id.is_empty():
		return true

	var remainder := world.create_item(
		remainder_item_id
	)

	if not remainder:
		return true

	inventory = consumer.get_component(
		&"base:inventory"
	) as InventoryComponent

	if inventory:
		inventory.add_item(
			remainder
		)
	else:
		world.spawn_dropped_item(
			remainder,
			consumer.global_position
		)

	return true

func submit_end_turn(
	entity: Entity
) -> void:
	if not entity:
		return

	_submit_command(
		COMMAND_END_TURN,
		entity,
		{
			"entity_id": entity.instance_id
		}
	)


func _apply_end_turn(
	sender_peer_id: int,
	entity_instance_id: String
) -> void:
	var entity := RuntimeObjectRegistry.get_entity(
		entity_instance_id
	)

	if not entity:
		return

	var controller := entity.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	var combat := entity.get_component(
		&"base:combat"
	) as CombatComponent

	if not combat:
		return

	if not combat.current_combat:
		return

	if not combat.current_combat.started:
		return

	if not combat.current_combat.is_active(
		entity
	):
		return

	combat.current_combat.end_turn(
		entity
	)
