extends Node2D

@onready var game_world: GameWorld = $GameWorld

func _ready() -> void:
	DefinitionLoader.load_all_definitions()
	
	game_world.generate_world(Vector2i(50, 50),12345)
	
	if MultiplayerManager.session_active:
		MultiplayerManager.game_ready.connect(_on_game_ready)
	else:
		_initialize_game_world()

func _on_game_ready() -> void:
	_initialize_game_world()

func _initialize_game_world() -> void:
	if not MultiplayerManager.is_world_authority():
		return
	
	_spawn_players()
	test_blink()
	game_world.spawn_entity(&"base:stopsign",Vector2(-200, -100))
	game_world.spawn_entity(&"base:goblin",Vector2(198, 95))
	game_world.spawn_entity(&"base:goblin",Vector2(-30, 125))
	game_world.spawn_entity(&"base:rock",Vector2(-250, 152))
	game_world.spawn_entity(&"base:tree",Vector2(216, -130))
	game_world.spawn_entity(&"base:chest",Vector2(32, 256))
	
	_spawn_test_items()
	for entity in game_world.get_entities():
		if entity.entity_id == &"base:goblin":
			test_burning(entity)
			break

func _spawn_players() -> void:
	var peer_ids: Array[int] = [1]

	for peer_id in multiplayer.get_peers():
		peer_ids.append(int(peer_id))

	peer_ids.sort()

	for i in range(peer_ids.size()):
		var peer_id := peer_ids[i]

		game_world.spawn_entity(
			&"base:player",
			Vector2(i * 32.0, 0.0),
			{
				"base:player_controller": {
					"controller_peer_id": peer_id
				}
			}
		)

func _unhandled_input(event: InputEvent) -> void:
	if not MultiplayerManager.is_world_authority():
		return

	if event.is_action_pressed("save_world"):
		SaveManager.save_world(game_world)

	if event.is_action_pressed("load_world"):
		SaveManager.load_world(game_world)

func _spawn_test_items() -> void:
	var all_entities = game_world.get_entities()
	
	all_entities.shuffle()
	
	for goblin in all_entities:
		if not goblin.entity_id == &"base:goblin":
			continue

		if not goblin:
			print("Couldn't find Goblin")
			return

		var inventory := goblin.get_component(
			&"base:inventory"
		) as InventoryComponent

		if not inventory:
			print("Goblin has no inventory")
			return

		var lightsaber := game_world.create_item(
			&"base:lightsaber"
		)
		var stick := game_world.create_item(
			&"base:stick"
		)
		var goblin_coin := game_world.create_item(
			&"base:goblin_coin"
		)
		var goblin_coin2 := game_world.create_item(
			&"base:goblin_coin"
		)

		inventory.add_item(stick)
		inventory.add_item(lightsaber)
		inventory.add_item(goblin_coin)
		inventory.add_item(goblin_coin2)

		print("Added Stick and Goblin Coin x2 to Goblin")
		break

	for chest in all_entities:
		if not chest.entity_id == &"base:chest":
			continue
		
		if not chest:
			print("There's no chest bub")
		
		var inventory = chest.get_component(&"base:inventory") as InventoryComponent
		
		if not inventory:
			print("This chest ain't got no insides bub")
			continue
		
		var sword = game_world.create_item(&"base:sword")
		inventory.add_item(sword)

func test_burning(entity: Entity) -> void:
	var status := entity.get_component(
		&"base:status"
	) as StatusComponent

	if not status:
		print("No StatusComponent")
		return

	var wet := StatusEffectRegistry.create_effect(&"base:wet")

	if not wet:
		return

	var wet_applied := status.apply_effect(wet,null,10.0)

	print("Wet applied: ", wet_applied)

	var burning := StatusEffectRegistry.create_effect(&"base:burning")

	if not burning:
		return

	var applied := status.apply_effect(burning,null,10.0)

	print("Burning applied: ", applied)

	if applied:
		print("Final duration: ", burning.duration)

func test_blink() -> void:
	var player := game_world.get_entity_controlled_by_peer(1)

	if not player:
		print("No player for Blink test")
		return

	var abilities := player.get_component(
		&"base:ability"
	) as AbilityComponent

	if not abilities:
		print("Player has no AbilityComponent")
		return

	var blink := abilities.get_ability(
		&"base:blink"
	)

	if not blink:
		print("Couldn't create Blink")
		return

	var use := AbilityUse.new()

	use.user = player
	use.set_target_position(
		player.global_position
		+ Vector2(0.0, -128.0)
	)

	print(
		"Blink can use: ",
		blink.can_use(use)
	)

	print(
		"Blink performed: ",
		blink.perform(use)
	)
