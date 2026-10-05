extends ResolutionModifier
class_name StatusDurationMultiplier

var multiplier: float

func _init(_multiplier: float,_priority: int = 0) -> void:
	multiplier = _multiplier
	priority = _priority


func apply(resolution: GameResolution) -> void:
	if not resolution is StatusApplicationResolution:
		return

	var status_resolution := (resolution as StatusApplicationResolution)
	
	#Negative means infinite duration
	if status_resolution.duration < 0.0:
		return

	status_resolution.duration *= multiplier
