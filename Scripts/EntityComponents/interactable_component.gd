##Makes an Entity interactable, meaning you can right click on it and
##perform an interaction. Interactions are sourced from other Entity
##components with [method EntityComponent.get_interaction_suggestions]

extends EntityComponent
class_name InteractableComponent

@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

func _ready() -> void:
	refresh_collision_from_sprite()

##Sets the collision shape of the interactable region to a rectangle
##bounding the dimensions of the sprite of the root entity. This just
##changes the "clickable" region, not the entity's actual collider.
func refresh_collision_from_sprite() -> void:
	var sprite := root_entity.get_node_or_null("Sprite2D") as Sprite2D

	if not sprite or not sprite.texture:
		return

	var shape := RectangleShape2D.new()
	shape.size = sprite.texture.get_size()

	collision_shape.shape = shape
	collision_shape.position = sprite.position

##Returns an Array of interactions suggested by [param _interactor]'s components' 
##[method get_interaction_suggestions] functions. Automatically filters out interactions
##blocked by any [method get_blocked_interactions] functions inside [param _interactor]'s components.
func get_interactions(_interactor: Entity) -> Array[Interaction]:
	var suggestion_ids: Dictionary = {}
	var blocked_ids: Dictionary = {}
	var interactions: Array[Interaction] = []

	for component in root_entity.get_components():
		for interaction_id in component.get_interaction_suggestions():
			suggestion_ids[interaction_id] = true
		for interaction_id in component.get_blocked_interactions():
			blocked_ids[interaction_id] = true

	for interaction_id in suggestion_ids:
		if interaction_id in blocked_ids:
			continue
			
		var interaction := InteractionRegistry.create_interaction(interaction_id)

		if not interaction:
			continue

		interactions.append(interaction)

	return interactions
