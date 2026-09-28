extends RefCounted
class_name WorldGenerator


func generate(size: Vector2i, seed: int) -> WorldData:
	var data := WorldData.new(size, seed)

	# Temporary dumb generation.
	for y in size.y:
		for x in size.x:
			data.set_terrain(
				Vector2i(x, y),
				&"base:grass"
			)

	return data
