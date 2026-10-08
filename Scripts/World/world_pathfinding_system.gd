extends Node
class_name WorldPathfindingSystem

@onready var world: GameWorld = get_parent() as GameWorld

var _grid := AStarGrid2D.new()
var _grid_size := 32.0
var _blocked_cells: Dictionary[Vector2i, bool] = {}

func rebuild() -> void:
	if not world.world_data:
		return

	_blocked_cells.clear()
	
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

	_refresh_blockers(entity)

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

func get_path_distance(
	entity: Entity,
	destination: Vector2
) -> float:
	if not entity:
		return INF

	var path := find_path(
		entity,
		destination
	)

	if path.is_empty():
		return INF

	var distance := 0.0
	var previous_position := entity.global_position

	for waypoint in path:
		distance += previous_position.distance_to(
			waypoint
		)

		previous_position = waypoint

	return distance

func _refresh_blockers(
	moving_entity: Entity
) -> void:
	# Clear everything that was marked solid
	# for the previous path query.
	for cell in _blocked_cells:
		if _grid.is_in_boundsv(cell):
			_grid.set_point_solid(
				cell,
				false
			)

	_blocked_cells.clear()

	_add_terrain_blockers(
		moving_entity
	)

	_add_entity_blockers(
		moving_entity
	)


func _add_terrain_blockers(
	moving_entity: Entity
) -> void:
	var data := world.world_data

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

			var terrain_id := data.get_terrain(
				cell
			)

			if not _terrain_blocks_entity(
				moving_entity,
				terrain_id
			):
				continue

			_block_cell(cell)


func _add_entity_blockers(
	moving_entity: Entity
) -> void:
	for entity in world.get_entities():
		if not entity:
			continue

		if entity == moving_entity:
			continue

		if not entity.solid:
			continue

		var cell := world.world_to_cell(
			entity.global_position
		)

		_block_cell(cell)


func _block_cell(
	cell: Vector2i
) -> void:
	if not _grid.is_in_boundsv(cell):
		return

	_blocked_cells[cell] = true

	_grid.set_point_solid(
		cell,
		true
	)


func _terrain_blocks_entity(
	_entity: Entity,
	terrain_id: StringName
) -> bool:
	return terrain_id == &"base:water"
