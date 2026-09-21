# TODO: Make a list of capabilities somewhere, e.g. reading, speaking, swimming, flying, etc.
# Also consider how a properties component might work. Or does there need to be a separate
# material component? Flammable would be a property but has behavior, e.g. "how flammable"?
# Maybe that's the thing, if there are follow-up questions it should be its own node, but for this
# component, it's just a simple yes/no tag that things can check

extends EntityComponent
class_name CapabilityComponent

##possessive: Entity owns the items in their inventory
@export var capabilities: Array = []

##Returns true if the Entity has the given [param capablity]
func has_capability(capability: StringName) -> bool:
	return capability in capabilities

func add_capability(capability_id: StringName) -> void:
	if not GameID.is_valid(capability_id):
		push_error("Invalid capability ID: %s" % capability_id)
		return

	if capability_id in capabilities:
		return

	capabilities.append(capability_id)

func remove_capability(capability: StringName) -> void:
	capabilities.erase(capability)
