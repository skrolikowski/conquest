## Visual preview service for colony placement
##
## Handles the visual feedback when placing a colony, including:
## - Drawing build radius overlays
## - Managing preview tile highlights
## - Tracking the colony being placed
##
## This service is responsible for the visual/UI concerns of placement,
## separate from the core colony management logic.
class_name ColonyPlacementPreview
extends Node2D


## The colony building being placed (null when no placement active)
var colony: CenterBuilding = null

## The target tile position for placement
var target_tile: Vector2i = Vector2i.ZERO

## Dictionary of tiles to preview: Vector2i -> { rect: Rect2, color: Color }
var preview_tiles: Dictionary = {}


## Set the colony to preview at the specified tile
## Calculates and displays the build radius overlay
func set_preview(building: CenterBuilding, tile: Vector2i) -> void:
	colony = building
	target_tile = tile
	_refresh_preview()


## Clear the preview (called when placement is cancelled/completed)
func clear_preview() -> void:
	colony = null
	target_tile = Vector2i.ZERO
	preview_tiles = {}
	queue_redraw()


## Check if there's an active preview
func has_preview() -> bool:
	return colony != null


## Get the colony being previewed (null if none)
func get_colony() -> CenterBuilding:
	return colony


## Draw the preview tiles
func _draw() -> void:
	if colony == null:
		return

	# Draw all preview tiles
	for tile: Vector2i in preview_tiles:
		var tile_data: Dictionary = preview_tiles[tile]
		draw_rect(tile_data.rect, tile_data.color, true)


## Refresh the preview tiles based on colony's build radius
## This calculates which tiles should be highlighted
## Called lazily from _draw() to avoid unnecessary calculations
func _refresh_preview() -> void:
	preview_tiles = {}

	if target_tile == Vector2i.ZERO or colony == null:
		return

	# Early exit if world map not available (e.g., in unit tests)
	if not get_tree().has_group("world"):
		return
		
	var world_map: WorldGen = Def.get_world_map()
	if world_map == null:
		return

	var tile_size: Vector2i = Preload.C.TILE_SIZE

	# Get build radius for each level (used for highlighting zones)
	var build_radius_1: float = GameData.get_building_stat(Term.BuildingType.CENTER, 1).build_radius * tile_size.x
	var build_radius_2: float = GameData.get_building_stat(Term.BuildingType.CENTER, 2).build_radius * tile_size.x
	var build_radius_3: float = GameData.get_building_stat(Term.BuildingType.CENTER, 3).build_radius * tile_size.x
	var build_radius_4: float = GameData.get_building_stat(Term.BuildingType.CENTER, 4).build_radius * tile_size.x

	# Define concentric circles of tiles with different colors
	var bounds: Array[Dictionary] = [
		{ "tiles": world_map.get_tiles_in_radius(colony.global_position, build_radius_1), "color": Color(Color.WHITE, 0.25) },
		{ "tiles": world_map.get_tiles_in_radius(colony.global_position, build_radius_2), "color": Color(Color.BLUE, 0.10) },
		{ "tiles": world_map.get_tiles_in_radius(colony.global_position, build_radius_3), "color": Color(Color.WHITE, 0.25) },
		{ "tiles": world_map.get_tiles_in_radius(colony.global_position, build_radius_4), "color": Color(Color.BLUE, 0.10) }
	]

	# Build preview_tiles dictionary (avoid duplicates, first color wins)
	for bound: Dictionary in bounds:
		for tile: Vector2i in bound.tiles:
			if not tile in preview_tiles:
				var tile_pos: Vector2 = world_map.get_map_to_local_position(tile)
				var tile_tl: Vector2 = tile_pos - tile_size * 0.5
				var tile_rect: Rect2 = Rect2(tile_tl, tile_size)

				preview_tiles[tile] = { "rect": tile_rect, "color": bound.color }
