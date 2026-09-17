# TODO: At some point, there will be multiple types of interactions
# per entity. There might be one obvious interaction e.g. opening a
# chest, but there will likely be a menu of possible interactions
# with a given entity. Solve for this later.

extends EntityComponent
class_name InteractableComponent

##Returns an array of created Interaction objects based on the
##suggested Interactions from the [param _interactor] Entity's components

func get_interactions(_interactor: Entity) -> Array[Interaction]:
	var suggestion_ids: Dictionary = {}
	var interactions: Array[Interaction] = []
	
	for component in root_entity.components_folder.get_children():
		if not component is EntityComponent:
			continue
		
		for interaction_id in component.get_interaction_suggestions():
			suggestion_ids[interaction_id] = true
	
	for interaction_id in suggestion_ids:
		var interaction := InteractionRegistry.create_interaction(interaction_id)
		
		if not interaction:
			continue
		
		interactions.append(interaction)
	
	return interactions
