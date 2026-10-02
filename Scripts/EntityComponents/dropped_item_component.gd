extends EntityComponent
class_name DroppedItemComponent


var item_instance_id: String = ""
var _item: Item


func on_added() -> void:
	_try_resolve_item()


func _ready() -> void:
	_try_resolve_item()


func _process(_delta: float) -> void:
	if _item:
		set_process(false)
		return

	if _try_resolve_item():
		set_process(false)


func get_item() -> Item:
	if not _item:
		_try_resolve_item()

	return _item


func get_interaction_suggestions() -> Array[StringName]:
	return [&"base:pick_up_item"]


func serialize_state() -> Dictionary:
	return {
		"item_instance_id": item_instance_id
	}


func deserialize_state(state: Dictionary) -> void:
	item_instance_id = String(
		state.get(
			"item_instance_id",
			""
		)
	)

	_item = null

	if not _try_resolve_item():
		set_process(true)


func _try_resolve_item() -> bool:
	if item_instance_id.is_empty():
		return false

	var item := RuntimeObjectRegistry.get_item(
		item_instance_id
	)

	if not item:
		return false

	_item = item

	if not root_entity:
		return true

	root_entity.entity_name = item.item_name

	var sprite := root_entity.get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if sprite:
		sprite.texture = item.sprite

		if sprite.texture:
			sprite.position.y = (
				-float(sprite.texture.get_height())
				/ 2.0
			)

	var interactable := get_component(
		&"base:interactable"
	) as InteractableComponent

	if (
		interactable
		and interactable.is_node_ready()
	):
		interactable.refresh_collision_from_sprite()

	return true
