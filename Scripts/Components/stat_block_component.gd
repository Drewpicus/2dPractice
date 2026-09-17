extends Node
class_name StatBlockComponent

@export var base_strength : float
@export var base_dexterity : float
@export var base_wisdom : float

var stat_max := 30.0

signal stat_changed(stat:String,new_value:float)

func update_base_stat(stat:int,change:float) -> float:
	match stat:
		Stat.STRENGTH:
			base_strength = clampf(base_strength+change,0,stat_max)
			stat_changed.emit(Stat.STRENGTH,base_strength)
			return base_strength
		Stat.DEXTERITY:
			base_dexterity = clampf(base_dexterity+change,0,stat_max)
			stat_changed.emit(Stat.DEXTERITY,base_dexterity)
			return base_dexterity
		Stat.WISDOM:
			base_wisdom = clampf(base_wisdom+change,0,stat_max)
			stat_changed.emit(Stat.WISDOM,base_wisdom)
			return base_wisdom
		_:
			return 0.0

##Returns the requested stat as a float
func get_stat(stat:int) -> float:
	match stat:
		Stat.STRENGTH:
			return base_strength
		Stat.DEXTERITY:
			return base_dexterity
		Stat.WISDOM:
			return base_wisdom
		_:
			return 0.0
