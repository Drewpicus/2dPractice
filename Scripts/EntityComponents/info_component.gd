# TODO: Consider using a getter to pass description through a parser
# for italic, colored, or other-font text. Or for just validation like .capitalize()

extends EntityComponent
class_name InfoComponent

@export_multiline() var description: String

func get_interaction_suggestions() -> Array[StringName]:
	return [&"base:inspect"]
