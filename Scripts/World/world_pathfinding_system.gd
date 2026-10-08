extends Node
class_name WorldPathfindingSystem

@onready var world: GameWorld = get_parent() as GameWorld

var _grid := AStarGrid2D.new()
var _grid_size := 32.0


func rebuild() -> void:
	if not world.world_data:
		return

	var data := world.world_data

	var minimum := data.get_min_cell()

	_grid.region = Rect2i(minimum, data.size)

	_grid.cell_size = Vector2(_grid_size, _grid_size)

	_grid.diagonal_mode = (AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES)

	_grid.update()
