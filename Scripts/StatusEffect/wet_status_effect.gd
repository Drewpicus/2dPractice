extends StatusEffect
class_name WetStatusEffect


func _init() -> void:
	effect_id = &"base:wet"


func on_resolution(
	resolution: GameResolution
) -> void:
	if not resolution is StatusApplicationResolution:
		return

	var status_resolution := (
		resolution as StatusApplicationResolution
	)

	if (
		status_resolution.target
		!= owner
	):
		return

	if (
		status_resolution.effect.effect_id
		!= &"base:burning"
	):
		return

	resolution.add_modifier(
		BlockStatusApplicationModifier.new(
			200
		),
		self
	)
