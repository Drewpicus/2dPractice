extends EntityComponent
class_name StatusComponent

var effects: Array[StatusEffect] = []

signal gained_effect(status: StatusEffect)
signal losing_effect(status: StatusEffect)

func add_effect(effect: StatusEffect) -> void:
	if not effect:
		return

	effects.append(effect)
	effect.owner = root_entity
	effect.on_added()
	gained_effect.emit(effect)


func remove_effect(effect: StatusEffect) -> void:
	if effect not in effects:
		return

	effect.on_removing()
	losing_effect.emit(effect)
	effects.erase(effect)
	effect.owner = null
