extends RefCounted
class_name WorldData

var seed: int
var size: Vector2i

var _terrain: Array[StringName] = []

func _init(world_size: Vector2i, world_seed: int) -> void:
	size = world_size
	seed = world_seed
	_terrain.resize(size.x * size.y)

func in_bounds(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.y >= 0
		and cell.x < size.x
		and cell.y < size.y
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
	return cell.y * size.x + cell.x
