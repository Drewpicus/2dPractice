extends Node
class_name WorldPathfindingSystem

@onready var world: GameWorld = get_parent() as GameWorld

var _grid := AStarGrid2D.new()
var _grid_size := 8.0
var _entity_blocked_cells: Dictionary[Vector2i, bool] = {}

func rebuild() -> void:
	if not world.world_data:
		return

	var data := world.world_data

	var minimum := data.get_min_cell()

	_grid.region = Rect2i(minimum, data.size)

	_grid.cell_size = Vector2(_grid_size, _grid_size)

	_grid.diagonal_mode = (AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES)

	_grid.update()

func find_path(
	entity: Entity,
	destination: Vector2
) -> PackedVector2Array:
	var path := PackedVector2Array()

	if not entity:
		return path

	if not world.world_data:
		return path

	var start_cell := world.world_to_cell(
		entity.global_position
	)

	var destination_cell := world.world_to_cell(
		destination
	)

	if not world.world_data.in_bounds(
		start_cell
	):
		return path

	if not world.world_data.in_bounds(
		destination_cell
	):
		return path

	_refresh_entity_blockers(entity)

	var cell_path := _grid.get_id_path(
		start_cell,
		destination_cell
	)

	if cell_path.is_empty():
		return path

	# Skip the starting cell. The Entity is already there.
	for i in range(
		1,
		cell_path.size()
	):
		var cell := cell_path[i]

		# Intermediate waypoints go through cell centers.
		if i < cell_path.size() - 1:
			path.append(
				world.cell_to_world(cell)
			)
		else:
			# Finish at the actual requested position,
			# rather than merely the center of its cell.
			path.append(destination)

	# If the destination is inside our current cell,
	# AStar gives us only the starting cell.
	if path.is_empty():
		path.append(destination)

	return path

func _refresh_entity_blockers(
	excluded_entity: Entity = null
) -> void:
	# Clear the Entity blockers from the previous query.
	for cell in _entity_blocked_cells:
		if _grid.is_in_boundsv(cell):
			_grid.set_point_solid(
				cell,
				false
			)

	_entity_blocked_cells.clear()

	# Mark the current cells of every solid Entity.
	for entity in world.get_entities():
		if not entity:
			continue

		# The mover obviously needs to be allowed
		# to leave its own starting cell.
		if entity == excluded_entity:
			continue

		if not entity.solid:
			continue

		var cell := world.world_to_cell(
			entity.global_position
		)

		if not _grid.is_in_boundsv(cell):
			continue

		_entity_blocked_cells[cell] = true

		_grid.set_point_solid(
			cell,
			true
		)
