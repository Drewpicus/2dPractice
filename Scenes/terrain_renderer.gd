extends TileMapLayer
class_name TerrainRenderer

const TERRAIN_TILES := {
	&"base:grass": {
		"source_id": 0,
		"atlas": Vector2i(0, 0)
	},
	&"base:dirt": {
		"source_id": 1,
		"atlas": Vector2i(0, 0)
	},
	&"base:water": {
		"source_id": 2,
		"atlas": Vector2i(0, 0)
	}
}

func render(world_data: WorldData) -> void:
	clear()

	var minimum := world_data.get_min_cell()
	var maximum := world_data.get_max_cell()

	for y in range(minimum.y, maximum.y + 1):
		for x in range(minimum.x, maximum.x + 1):
			var cell := Vector2i(x, y)
			var terrain_id := world_data.get_terrain(cell)

			_render_cell(cell, terrain_id)

func _render_cell(
	cell: Vector2i,
	terrain_id: StringName
) -> void:

	var tile = TERRAIN_TILES.get(terrain_id)

	if not tile:
		return

	set_cell(
		cell,
		tile["source_id"],
		tile["atlas"]
	)
