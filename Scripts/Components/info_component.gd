# TODO: Consider using a getter to pass description and name through a parser
# for italic, colored, or other-font text. Or for just validation like .capitalize()

extends EntityComponent
class_name InfoComponent

@export var entity_name: String
@export_multiline() var description: String

func get_interaction_suggestions() -> Array[StringName]:
	return [&"inspect"]
