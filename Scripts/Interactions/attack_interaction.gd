extends Interaction
class_name AttackInteraction

func _init() -> void:
	interaction_id = &"attack"
	interaction_name = "Attack"

func can_perform(interactor: Entity, target: Entity) -> bool:
	if not target.has_component(&"health"):
		return false
	if interactor.global_position.distance_to(target.global_position) > interactor.get_component(&"interactor").reach:
		return false
	return true

func perform(interactor: Entity, target: Entity) -> void:
	var attack_damage: float = 1.0
	var interactor_stats: StatBlockComponent = interactor.get_component(&"stat_block")
	if interactor_stats != null:
		attack_damage = interactor_stats.get_stat(Stat.STRENGTH)
	
	var target_health: HealthComponent = target.get_component(&"health")
	target_health.change_health(int(-1 * attack_damage))
	
	print("%s attacks %s for %d damage!" % [interactor.name,target.name,attack_damage])
