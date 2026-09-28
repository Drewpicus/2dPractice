extends RefCounted
class_name WorldGenerator


func generate(size: Vector2i, seed: int) -> WorldData:
	var data := WorldData.new(size, seed)

	var minimum := data.get_min_cell()
	var maximum := data.get_max_cell()

	for y in range(minimum.y, maximum.y + 1):
		for x in range(minimum.x, maximum.x + 1):
			var cell := Vector2i(x, y)
			if x < -10:
				data.set_terrain(
					cell,
					&"base:water"
				)
			elif y > -6 and y < -2:
				data.set_terrain(
					cell,
					&"base:dirt"
				)
			else:
				data.set_terrain(
					cell,
					&"base:grass"
				)

	return data
