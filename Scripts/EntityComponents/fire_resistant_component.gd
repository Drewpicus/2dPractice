extends EntityComponent
class_name FireResistantComponent


func _init() -> void:
	component_id = &"base:fire_resistant"


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
		!= root_entity
	):
		return

	if (
		status_resolution.effect.effect_id
		!= &"base:burning"
	):
		return

	contribute_modifier(
		resolution,
		StatusDurationMultiplier.new(
			0.5,
			100
		)
	)
