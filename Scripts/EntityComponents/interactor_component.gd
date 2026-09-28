extends EntityComponent
class_name InteractorComponent

##In pixels, the distance the Entity can interact with things
@export var reach: float = 64.0

func get_interaction_suggestions() -> Array[StringName]:
	return [&"base:be"]
