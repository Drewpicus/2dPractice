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

	for y in world_data.size.y:
		for x in world_data.size.x:
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
