extends RefCounted
class_name WorldGenerator


func generate(size: Vector2i, seed: int) -> WorldData:
	var data := WorldData.new(size, seed)

	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)

			if x < 5:
				data.set_terrain(
					cell,
					&"base:water"
				)
			elif y > 20 and y < 25:
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
