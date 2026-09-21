extends Node2D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
		var goblin := get_node_or_null("GameWorld/Entities/Goblin") as Entity
		if not goblin:
			print("Couldn't find Goblin")
			return
		
		var inventory := goblin.get_component(&"base:inventory") as InventoryComponent
		if not inventory:
			print("Goblin has no inventory")
			return
		
		var stick_definition := preload("res://Items/stick.tres") as ItemDefinition
		var stick := ItemFactory.build(stick_definition)
		
		var goblin_coin_definition := preload("res://Items/goblin_coin.tres") as ItemDefinition
		var goblin_coin := ItemFactory.build(goblin_coin_definition)
		var goblin_coin2 := ItemFactory.build(goblin_coin_definition)
		
		inventory.add_item(stick)
		inventory.add_item(goblin_coin)
		inventory.add_item(goblin_coin2)
		
		print("Added Stick and Goblin Coin x2 to Goblin")
