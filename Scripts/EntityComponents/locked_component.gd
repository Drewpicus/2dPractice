extends EntityComponent
class_name LockedComponent


## Interactions blocked while this component exists.
@export var locked_interactions: Array[StringName] = []

## Texture displayed over the Entity while locked.
@export var locked_sprite_path: String = ""

var locked_sprite: Sprite2D

func _ready() -> void:
	if locked_sprite_path.is_empty():
		return

	var entity_sprite := root_entity.get_node_or_null("Sprite2D") as Sprite2D

	if not entity_sprite:
		return

	var texture_resource := load(locked_sprite_path)

	if not texture_resource is Texture2D:
		push_error("Locked sprite is not a Texture2D: %s" % locked_sprite_path)
		return

	locked_sprite = Sprite2D.new()
	locked_sprite.texture = texture_resource

	entity_sprite.add_child(locked_sprite)

	locked_sprite.position = Vector2.ZERO
	locked_sprite.z_index = entity_sprite.z_index


func on_removing() -> void:
	if is_instance_valid(locked_sprite):
		locked_sprite.queue_free()


func get_interaction_suggestions() -> Array[StringName]:
	return [&"base:unlock"]


func get_blocked_interactions() -> Array[StringName]:
	return locked_interactions
