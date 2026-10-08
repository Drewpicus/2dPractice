extends RefCounted
class_name WorldGenerator


func generate(
	size: Vector2i,
	seed: int
) -> WorldData:
	var data := WorldData.new(
		size,
		seed
	)

	var terrain_noise := FastNoiseLite.new()

	terrain_noise.seed = seed
	terrain_noise.frequency = 0.06

	var minimum := data.get_min_cell()
	var maximum := data.get_max_cell()

	for y in range(
		minimum.y,
		maximum.y + 1
	):
		for x in range(
			minimum.x,
			maximum.x + 1
		):
			var cell := Vector2i(
				x,
				y
			)

			var noise_value := terrain_noise.get_noise_2d(
				x,
				y
			)

			var terrain_id := _terrain_from_noise(
				noise_value
			)

			data.set_terrain(
				cell,
				terrain_id
			)

	return data


func _terrain_from_noise(
	noise_value: float
) -> StringName:
	if noise_value < -0.25:
		return &"base:water"

	if noise_value < -0.05:
		return &"base:dirt"

	return &"base:grass"
