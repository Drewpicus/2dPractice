extends Interaction
class_name BeInteraction

func _init() -> void:
	interaction_id = &"base:be"
	interaction_name = "Be"

func should_show(_interactor: Entity, _target: Entity) -> bool:
	return not _target.has_component(&"base:player_controller")

func can_perform(_interactor: Entity, _target: Entity) -> bool:
	if not _interactor.has_component(&"base:interactor"):
		return false
	if not _target.has_component(&"base:interactor"):
		return false
	if _target.has_component(&"base:player_controller"):
		return false
	return true

func perform(_interactor: Entity, _target: Entity) -> void:
	var world = GameWorld.find_world(_interactor) as GameWorld
	
	if not world:
		return
	
	world.transfer_player_controller(_interactor, _target)

func requires_authority() -> bool:
	return true
