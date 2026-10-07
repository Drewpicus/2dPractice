extends ResolutionModifier
class_name DamageFlatModifier


var amount: float


func _init(
	_amount: float,
	_priority: int = ResolutionModifier.PRIORITY_STAGE.ADDITION_SUBTRACTION
) -> void:
	amount = _amount
	priority = _priority


func apply(resolution: GameResolution) -> void:
	if not resolution is DamageResolution:
		return

	var damage_resolution := resolution as DamageResolution

	damage_resolution.damage += amount
