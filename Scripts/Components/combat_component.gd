extends EntityComponent
class_name CombatComponent

var current_combat: Combat

func add_to_combat(combat: Combat, respect_disengagement: bool = false) -> void:
	if combat == null:
		return
	if current_combat != null:
		return
	combat.add_combatant(root_entity, respect_disengagement)


func remove_from_combat() -> void:
	if current_combat == null:
		return
	current_combat.remove_combatant(root_entity)
