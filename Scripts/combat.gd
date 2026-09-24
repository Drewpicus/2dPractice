extends RefCounted
class_name Combat

var combat_id: int
##List of entities participating in the combat
var combatants: Array[Entity] = []
##List of entities disengaged from the combat, effectively a blacklist for being added back
var disengaged: Array[Entity] = []


func add_combatant(entity: Entity, respect_disengagement: bool = false) -> void:
	if entity == null:
		return

	if entity in combatants:
		return
	
	var combat_component := entity.get_component(&"base:combat") as CombatComponent
	if combat_component == null:
		return
	
	if combat_component.current_combat != null:
		return

	if respect_disengagement and entity in disengaged:
		return
	
	combat_component.current_combat = self
	disengaged.erase(entity)
	combatants.append(entity)


func remove_combatant(entity: Entity) -> void:
	if entity == null:
		return

	if entity not in combatants:
		return

	var combat_component := entity.get_component(&"base:combat") as CombatComponent
	if combat_component != null:
		combat_component.current_combat = null

	combatants.erase(entity)

	if entity not in disengaged:
		disengaged.append(entity)
