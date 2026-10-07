extends ResolutionModifier
class_name DamageMultiplierModifier


var multiplier: float


func _init(
	_multiplier: float,
	_priority: int = ResolutionModifier.PRIORITY_STAGE.MULTIPLICATION
) -> void:
	multiplier = _multiplier
	priority = _priority


func apply(resolution: GameResolution) -> void:
	if not resolution is DamageResolution:
		return

	var damage_resolution := resolution as DamageResolution

	damage_resolution.damage *= multiplier
