extends Interaction
class_name AttackInteraction

func _init() -> void:
	interaction_id = &"base:attack"
	interaction_name = "Attack"

func should_show(_interactor: Entity, _target: Entity) -> bool:
	return _target.has_component(&"base:movement")

func can_perform(_interactor: Entity, _target: Entity) -> bool:
	if not _interactor.has_component(&"base:interactor"):
		return false
	if not _target.has_component(&"base:health"):
		return false
	if _interactor.global_position.distance_to(_target.global_position) > _interactor.get_component(&"base:interactor").reach:
		return false
	return true

func perform(_interactor: Entity, _target: Entity) -> void:
	var attack_damage: float = 1.0
	var interactor_stats: StatBlockComponent = _interactor.get_component(&"base:stat_block")
	if interactor_stats != null:
		attack_damage = interactor_stats.get_stat(Stat.STRENGTH)
	
	var target_health: HealthComponent = _target.get_component(&"base:health")
	target_health.damage(int(attack_damage))
	
	print("%s attacks %s for %d damage!" % [_interactor.entity_name,_target.entity_name,attack_damage])
