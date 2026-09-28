extends RefCounted
class_name WorldData

var _seed: int
var size: Vector2i

var _terrain: Array[StringName] = []


func _init(world_size: Vector2i, world_seed: int) -> void:
	size = world_size
	_seed = world_seed
	_terrain.resize(size.x * size.y)


func get_min_cell() -> Vector2i:
	return Vector2i(int(float(-size.x) / 2), int(float(-size.y) / 2))


func get_max_cell() -> Vector2i:
	var minimum := get_min_cell()

	return Vector2i(
		minimum.x + size.x - 1,
		minimum.y + size.y - 1
	)


func in_bounds(cell: Vector2i) -> bool:
	var minimum := get_min_cell()
	var maximum := get_max_cell()

	return (
		cell.x >= minimum.x
		and cell.y >= minimum.y
		and cell.x <= maximum.x
		and cell.y <= maximum.y
	)


func get_terrain(cell: Vector2i) -> StringName:
	if not in_bounds(cell):
		return &""

	return _terrain[_index(cell)]


func set_terrain(cell: Vector2i, terrain_id: StringName) -> void:
	if not in_bounds(cell):
		return

	_terrain[_index(cell)] = terrain_id


func _index(cell: Vector2i) -> int:
	var minimum := get_min_cell()
	var array_cell := cell - minimum

	return array_cell.y * size.x + array_cell.x
