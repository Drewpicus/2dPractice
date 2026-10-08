extends Node
class_name WorldPathfindingSystem

const NAV_CELL_SIZE: float = 4.0
const EDGE_EPSILON: float = 0.001

@onready var world: GameWorld = get_parent() as GameWorld

var _grid := AStarGrid2D.new()

var _blocked_cells: Dictionary[Vector2i, bool] = {}

# Used to test whether an Entity's actual collision
# footprint intersects a navigation cell.
var _nav_cell_shape := RectangleShape2D.new()


func _ready() -> void:
	_nav_cell_shape.size = Vector2(
		NAV_CELL_SIZE,
		NAV_CELL_SIZE
	)


func rebuild() -> void:
	if not world.world_data:
		return

	_blocked_cells.clear()

	var data := world.world_data

	var minimum_region := _terrain_cell_nav_region(
		data.get_min_cell()
	)

	var maximum_region := _terrain_cell_nav_region(
		data.get_max_cell()
	)

	var nav_minimum := minimum_region.position

	var nav_end := (
		maximum_region.position
		+ maximum_region.size
	)

	_grid.region = Rect2i(
		nav_minimum,
		nav_end - nav_minimum
	)

	_grid.cell_size = Vector2(
		NAV_CELL_SIZE,
		NAV_CELL_SIZE
	)

	_grid.diagonal_mode = (
		AStarGrid2D
		.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	)

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

	# WorldData still determines the actual
	# boundaries of the world.
	var start_world_cell := world.world_to_cell(
		entity.global_position
	)

	var destination_world_cell := world.world_to_cell(
		destination
	)

	if not world.world_data.in_bounds(
		start_world_cell
	):
		return path

	if not world.world_data.in_bounds(
		destination_world_cell
	):
		return path

	var start_cell := world_to_nav_cell(
		entity.global_position
	)

	var destination_cell := world_to_nav_cell(
		destination
	)

	if not _grid.is_in_boundsv(start_cell):
		return path

	if not _grid.is_in_boundsv(destination_cell):
		return path

	_refresh_blockers(entity)

	var cell_path := _grid.get_id_path(
		start_cell,
		destination_cell
	)

	if cell_path.is_empty():
		return path
	
	var final_destination := destination

	if _position_overlaps_solid_entity(
		entity,
		destination
	):
		final_destination = nav_cell_to_world(
			destination_cell
		)
	
	# Skip the starting navigation cell.
	for i in range(
		1,
		cell_path.size()
	):
		var cell := cell_path[i]

		if i < cell_path.size() - 1:
			path.append(
				nav_cell_to_world(cell)
			)
		else:
			# Still finish at the exact requested
			# position rather than the center of
			# its 4×4 navigation cell.
			path.append(final_destination)

	if path.is_empty():
		path.append(final_destination)

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


func world_to_nav_cell(
	world_position: Vector2
) -> Vector2i:
	var local_position := world.terrain.to_local(
		world_position
	)

	return _local_to_nav_cell(
		local_position
	)


func nav_cell_to_world(
	cell: Vector2i
) -> Vector2:
	return world.terrain.to_global(
		_nav_cell_local_center(cell)
	)


func _local_to_nav_cell(
	local_position: Vector2
) -> Vector2i:
	return Vector2i(
		int(floor(
			local_position.x
			/ NAV_CELL_SIZE
		)),
		int(floor(
			local_position.y
			/ NAV_CELL_SIZE
		))
	)


func _nav_cell_local_center(
	cell: Vector2i
) -> Vector2:
	return Vector2(
		(float(cell.x) + 0.5)
			* NAV_CELL_SIZE,
		(float(cell.y) + 0.5)
			* NAV_CELL_SIZE
	)


func _refresh_blockers(
	moving_entity: Entity
) -> void:
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
			var terrain_cell := Vector2i(
				x,
				y
			)

			var terrain_id := data.get_terrain(
				terrain_cell
			)

			if not _terrain_blocks_entity(
				moving_entity,
				terrain_id
			):
				continue

			var nav_region := (
				_terrain_cell_nav_region(
					terrain_cell
				)
			)

			_block_region(nav_region)

func _add_entity_blockers(
	moving_entity: Entity
) -> void:
	var moving_collision := _get_entity_collision(
		moving_entity
	)

	if not moving_collision:
		return

	for blocker in world.get_entities():
		if not blocker:
			continue

		if blocker == moving_entity:
			continue

		if not blocker.solid:
			continue

		var blocker_collision := _get_entity_collision(
			blocker
		)

		if not blocker_collision:
			continue

		var candidate_region := (
			_get_collision_candidate_region(
				moving_entity,
				moving_collision,
				blocker_collision
			)
		)

		var region_end := (
			candidate_region.position
			+ candidate_region.size
		)

		for y in range(
			candidate_region.position.y,
			region_end.y
		):
			for x in range(
				candidate_region.position.x,
				region_end.x
			):
				var cell := Vector2i(x, y)

				if not _grid.is_in_boundsv(cell):
					continue

				if _mover_collides_at_position(
					moving_entity,
					moving_collision,
					blocker_collision,
					nav_cell_to_world(cell)
				):
					_block_cell(cell)

func _get_entity_collision(
	entity: Entity
) -> CollisionShape2D:
	if not entity:
		return null

	var collision := entity.get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if not collision:
		return null

	if collision.disabled:
		return null

	if not collision.shape:
		return null

	return collision


func _mover_collides_at_position(
	moving_entity: Entity,
	moving_collision: CollisionShape2D,
	blocker_collision: CollisionShape2D,
	position: Vector2
) -> bool:
	# Preserve the CollisionShape2D's transform
	# relative to its Entity.
	var collision_local_transform := (
		moving_entity.global_transform.affine_inverse()
		* moving_collision.global_transform
	)

	# Pretend the Entity is standing at the
	# candidate navigation position.
	var candidate_entity_transform := (
		moving_entity.global_transform
	)

	candidate_entity_transform.origin = position

	var candidate_collision_transform := (
		candidate_entity_transform
		* collision_local_transform
	)

	return moving_collision.shape.collide(
		candidate_collision_transform,
		blocker_collision.shape,
		blocker_collision.global_transform
	)

func _get_collision_candidate_region(
	moving_entity: Entity,
	moving_collision: CollisionShape2D,
	blocker_collision: CollisionShape2D
) -> Rect2i:
	var blocker_rect := (
		_collision_rect_in_terrain(
			blocker_collision
		)
	)

	var mover_rect := (
		_collision_rect_in_terrain(
			moving_collision
		)
	)

	var mover_origin := world.terrain.to_local(
		moving_entity.global_position
	)

	var mover_minimum_offset := (
		mover_rect.position
		- mover_origin
	)

	var mover_maximum_offset := (
		mover_rect.end
		- mover_origin
	)

	var candidate_minimum := (
		blocker_rect.position
		- mover_maximum_offset
	)

	var candidate_maximum := (
		blocker_rect.end
		- mover_minimum_offset
	)

	var minimum_cell := _local_to_nav_cell(
		candidate_minimum
	)

	var maximum_cell := _local_to_nav_cell(
		candidate_maximum
	)

	return Rect2i(
		minimum_cell,
		maximum_cell
			- minimum_cell
			+ Vector2i.ONE
	)

func _collision_rect_in_terrain(
	collision: CollisionShape2D
) -> Rect2:
	var rect := collision.shape.get_rect()

	var corners := [
		rect.position,
		Vector2(
			rect.end.x,
			rect.position.y
		),
		rect.end,
		Vector2(
			rect.position.x,
			rect.end.y
		)
	]

	var first_point := world.terrain.to_local(
		collision.global_transform
		* corners[0]
	)

	var minimum := first_point
	var maximum := first_point

	for i in range(1, corners.size()):
		var point := world.terrain.to_local(
			collision.global_transform
			* corners[i]
		)

		minimum.x = minf(
			minimum.x,
			point.x
		)

		minimum.y = minf(
			minimum.y,
			point.y
		)

		maximum.x = maxf(
			maximum.x,
			point.x
		)

		maximum.y = maxf(
			maximum.y,
			point.y
		)

	return Rect2(
		minimum,
		maximum - minimum
	)

func _collision_intersects_nav_cell(
	collision: CollisionShape2D,
	cell: Vector2i
) -> bool:
	var local_center := (
		_nav_cell_local_center(cell)
	)

	var cell_local_transform := Transform2D(
		0.0,
		local_center
	)

	var cell_global_transform := (
		world.terrain.global_transform
		* cell_local_transform
	)

	return collision.shape.collide(
		collision.global_transform,
		_nav_cell_shape,
		cell_global_transform
	)


func _collision_nav_region(
	collision: CollisionShape2D
) -> Rect2i:
	var rect := collision.shape.get_rect()

	var corners := [
		rect.position,
		Vector2(
			rect.end.x,
			rect.position.y
		),
		rect.end,
		Vector2(
			rect.position.x,
			rect.end.y
		)
	]

	var first_world = (
		collision.global_transform
		* corners[0]
	)

	var first_local := world.terrain.to_local(
		first_world
	)

	var minimum := first_local
	var maximum := first_local

	for i in range(1, corners.size()):
		var world_point = (
			collision.global_transform
			* corners[i]
		)

		var local_point := world.terrain.to_local(
			world_point
		)

		minimum.x = minf(
			minimum.x,
			local_point.x
		)

		minimum.y = minf(
			minimum.y,
			local_point.y
		)

		maximum.x = maxf(
			maximum.x,
			local_point.x
		)

		maximum.y = maxf(
			maximum.y,
			local_point.y
		)

	var minimum_cell := _local_to_nav_cell(
		minimum
	)

	var maximum_cell := _local_to_nav_cell(
		maximum
	)

	return Rect2i(
		minimum_cell,
		maximum_cell
			- minimum_cell
			+ Vector2i.ONE
	)


func _terrain_cell_nav_region(
	terrain_cell: Vector2i
) -> Rect2i:
	var tile_size_data := (
		world.terrain.tile_set.tile_size
	)

	var tile_size := Vector2(
		float(tile_size_data.x),
		float(tile_size_data.y)
	)

	var center := world.terrain.map_to_local(
		terrain_cell
	)

	var minimum_position := (
		center
		- tile_size / 2.0
	)

	var maximum_position := (
		center
		+ tile_size / 2.0
		- Vector2(
			EDGE_EPSILON,
			EDGE_EPSILON
		)
	)

	var minimum_cell := _local_to_nav_cell(
		minimum_position
	)

	var maximum_cell := _local_to_nav_cell(
		maximum_position
	)

	return Rect2i(
		minimum_cell,
		maximum_cell
			- minimum_cell
			+ Vector2i.ONE
	)


func _block_region(
	region: Rect2i
) -> void:
	var region_end := (
		region.position
		+ region.size
	)

	for y in range(
		region.position.y,
		region_end.y
	):
		for x in range(
			region.position.x,
			region_end.x
		):
			_block_cell(
				Vector2i(x, y)
			)


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

func _position_overlaps_solid_entity(
	moving_entity: Entity,
	position: Vector2
) -> bool:
	var moving_collision := _get_entity_collision(
		moving_entity
	)

	if not moving_collision:
		return false

	for blocker in world.get_entities():
		if not blocker:
			continue

		if blocker == moving_entity:
			continue

		if not blocker.solid:
			continue

		var blocker_collision := _get_entity_collision(
			blocker
		)

		if not blocker_collision:
			continue

		if _mover_collides_at_position(
			moving_entity,
			moving_collision,
			blocker_collision,
			position
		):
			return true

	return false
