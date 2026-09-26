extends EntityComponent
class_name InteractableComponent

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	root_entity.apply_entity_collision_to(collision_shape)

##Returns an array of created Interaction objects based on the
##suggested Interactions from the target Entity's components
func get_interactions(_interactor: Entity) -> Array[Interaction]:
	var suggestion_ids: Dictionary = {}
	var interactions: Array[Interaction] = []
	
	for component in root_entity.get_components():
		for interaction_id in component.get_interaction_suggestions():
			suggestion_ids[interaction_id] = true
	
	for interaction_id in suggestion_ids:
		var interaction := InteractionRegistry.create_interaction(interaction_id)
		
		if not interaction:
			continue
		
		interactions.append(interaction)
	
	return interactions
