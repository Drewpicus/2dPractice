extends Node
class_name WorldCommandSystem


const COMMAND_INTERACTION := &"base:interaction"
const COMMAND_TAKE_ITEM := &"base:take_item"
const COMMAND_EQUIP_ITEM := &"base:equip_item"
const COMMAND_UNEQUIP_ITEM := &"base:unequip_item"


func _submit_command(
	command_id: StringName,
	actor: Entity,
	arguments: Dictionary = {}
) -> void:
	if not actor:
		return

	var controller := actor.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if not controller.is_locally_controlled():
		return

	if MultiplayerManager.is_world_authority():
		_apply_command(
			multiplayer.get_unique_id(),
			command_id,
			arguments
		)
		return

	_receive_command.rpc_id(
		1,
		String(command_id),
		arguments
	)


@rpc("any_peer", "call_remote", "reliable", 3)
func _receive_command(
	command_id_string: String,
	arguments: Dictionary
) -> void:
	if not MultiplayerManager.is_world_authority():
		return

	_apply_command(
		multiplayer.get_remote_sender_id(),
		StringName(command_id_string),
		arguments
	)


func _apply_command(
	sender_peer_id: int,
	command_id: StringName,
	arguments: Dictionary
) -> void:
	match command_id:
		COMMAND_INTERACTION:
			_apply_interaction(
				sender_peer_id,
				StringName(
					arguments.get(
						"interaction_id",
						""
					)
				),
				String(
					arguments.get(
						"interactor_id",
						""
					)
				),
				String(
					arguments.get(
						"target_id",
						""
					)
				)
			)

		COMMAND_TAKE_ITEM:
			_apply_take_item(
				sender_peer_id,
				String(
					arguments.get(
						"viewer_id",
						""
					)
				),
				String(
					arguments.get(
						"source_id",
						""
					)
				),
				String(
					arguments.get(
						"item_id",
						""
					)
				)
			)

		COMMAND_EQUIP_ITEM:
			_apply_equip_item(
				sender_peer_id,
				String(
					arguments.get(
						"entity_id",
						""
					)
				),
				String(
					arguments.get(
						"item_id",
						""
					)
				),
				StringName(
					arguments.get(
						"slot",
						""
					)
				)
			)

		COMMAND_UNEQUIP_ITEM:
			_apply_unequip_item(
				sender_peer_id,
				String(
					arguments.get(
						"entity_id",
						""
					)
				),
				StringName(
					arguments.get(
						"slot",
						""
					)
				)
			)

		_:
			push_warning(
				"Unknown command ID: %s"
				% command_id
			)


func submit_interaction(
	interaction: Interaction,
	interactor: Entity,
	target: Entity
) -> void:
	if not interaction or not interactor or not target:
		return

	if not interaction.can_perform(
		interactor,
		target
	):
		return

	if not interaction.requires_authority():
		interaction.perform(
			interactor,
			target
		)
		return

	_submit_command(
		COMMAND_INTERACTION,
		interactor,
		{
			"interaction_id": String(
				interaction.interaction_id
			),
			"interactor_id": interactor.instance_id,
			"target_id": target.instance_id
		}
	)


func _apply_interaction(
	sender_peer_id: int,
	interaction_id: StringName,
	interactor_instance_id: String,
	target_instance_id: String
) -> void:
	var interactor := RuntimeObjectRegistry.get_entity(
		interactor_instance_id
	)

	var target := RuntimeObjectRegistry.get_entity(
		target_instance_id
	)

	if not interactor or not target:
		return

	var controller := interactor.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	var interactable := target.get_component(
		&"base:interactable"
	) as InteractableComponent

	if not interactable:
		return

	var selected_interaction: Interaction

	for interaction in interactable.get_interactions(
		interactor
	):
		if interaction.interaction_id == interaction_id:
			selected_interaction = interaction
			break

	if not selected_interaction:
		return

	if not selected_interaction.requires_authority():
		return

	if not selected_interaction.can_perform(
		interactor,
		target
	):
		return

	selected_interaction.perform(
		interactor,
		target
	)


func submit_take_item(
	viewer: Entity,
	source: Entity,
	item: Item
) -> void:
	if not viewer or not source or not item:
		return

	_submit_command(
		COMMAND_TAKE_ITEM,
		viewer,
		{
			"viewer_id": viewer.instance_id,
			"source_id": source.instance_id,
			"item_id": item.instance_id
		}
	)


func _apply_take_item(
	sender_peer_id: int,
	viewer_instance_id: String,
	source_instance_id: String,
	item_instance_id: String
) -> void:
	var viewer := RuntimeObjectRegistry.get_entity(
		viewer_instance_id
	)

	var source := RuntimeObjectRegistry.get_entity(
		source_instance_id
	)

	var item := RuntimeObjectRegistry.get_item(
		item_instance_id
	)

	if not viewer or not source or not item:
		return

	var controller := viewer.get_component(
		&"base:player_controller"
	) as PlayerControllerComponent

	if not controller:
		return

	if controller.controller_peer_id != sender_peer_id:
		return

	_perform_take_item(
		viewer,
		source,
		item
	)


func _perform_take_item(
	viewer: Entity,
	source: Entity,
	item: Item
) -> bool:
	if viewer == source:
		return false

	var viewer_inventory := viewer.get_component(
		&"base:inventory"
	) as InventoryComponent

	var source_inventory := source.get_component(
		&"base:inventory"
	) as InventoryComponent

	if not viewer_inventory or not source_inventory:
		return false

	if item not in source_inventory.items:
		return false

	var interactor := viewer.get_component(
		&"base:interactor"
	) as InteractorComponent

	if not interactor:
		return false

	if (
		viewer.global_position.distance_to(
			source.global_position
		) > interactor.reach
	):
		return false

	var taken_item := source_inventory.remove_item(
		item
	)

	if not taken_item:
		return false

	viewer_inventory.add_item(taken_item)

	return true


func submit_equip_item(
	entity: Entity,
	item: Item,
	slot: StringName
) -> void:
	if not entity or not item:
		return

	_submit_command(
		COMMAND_EQUIP_ITEM,
		entity,
		{
			"entity_id": entity.instance_id,
			"item_id": item.instance_id,
			"slot": String(slot)
		}
	)


func _apply_equip_item(
	sender_peer_id: int,
	entity_instance_id: String,
	item_instance_id: String,
	slot: StringName
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

	_perform_equip_item(
		entity,
		item,
		slot
	)


func _perform_equip_item(
	entity: Entity,
	item: Item,
	slot: StringName
) -> bool:
	var equipment := entity.get_component(
		&"base:equipment"
	) as EquipmentComponent

	if not equipment:
		return false

	return equipment.equip(
		slot,
		item
	)


func submit_unequip_item(
	entity: Entity,
	slot: StringName
) -> void:
	if not entity:
		return

	_submit_command(
		COMMAND_UNEQUIP_ITEM,
		entity,
		{
			"entity_id": entity.instance_id,
			"slot": String(slot)
		}
	)


func _apply_unequip_item(
	sender_peer_id: int,
	entity_instance_id: String,
	slot: StringName
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

	_perform_unequip_item(
		entity,
		slot
	)


func _perform_unequip_item(
	entity: Entity,
	slot: StringName
) -> bool:
	var equipment := entity.get_component(
		&"base:equipment"
	) as EquipmentComponent

	if not equipment:
		return false

	return equipment.unequip(slot) != null
