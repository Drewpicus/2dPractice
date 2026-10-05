extends ResolutionModifier
class_name BlockStatusApplicationModifier


func _init(_priority: int = 0) -> void:
	priority = _priority


func apply(resolution: GameResolution) -> void:
	if not resolution is StatusApplicationResolution:
		return

	var status_resolution := (
		resolution as StatusApplicationResolution
	)

	status_resolution.allowed = false
