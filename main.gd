extends Node3D

@onready var game_world: GameWorld = $GameWorld

func _ready() -> void:
	DefinitionLoader.load_all_definitions()
	
	game_world.spawn_entity(&"base:player", Vector3(0, 0, 0))
	game_world.spawn_entity(&"base:goblin", Vector3(6, 0, 3))
	game_world.spawn_entity(&"base:rock", Vector3(-7, 0, 5))
	game_world.spawn_entity(&"base:tree", Vector3(7, 0, -4))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_world"):
		SaveManager.save_world(game_world)
	if event.is_action_pressed("load_world"):
		SaveManager.load_world(game_world)
	if event.is_action_pressed("test"):
		var goblin := get_node_or_null("GameWorld/Entities/Goblin") as Entity
		if not goblin:
			print("Couldn't find Goblin")
			return
		
		var inventory := goblin.get_component(&"base:inventory") as InventoryComponent
		if not inventory:
			print("Goblin has no inventory")
			return
		
		var stick_definition := DefinitionRegistry.get_item(&"base:stick")
		var stick := ItemFactory.build(stick_definition)
		
		var goblin_coin_definition := DefinitionRegistry.get_item(&"base:goblin_coin")
		var goblin_coin := ItemFactory.build(goblin_coin_definition)
		var goblin_coin2 := ItemFactory.build(goblin_coin_definition)
		
		inventory.add_item(stick)
		inventory.add_item(goblin_coin)
		inventory.add_item(goblin_coin2)
		
		print("Added Stick and Goblin Coin x2 to Goblin")
