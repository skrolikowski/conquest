## Visual preview service for building placement
##
## Handles the visual feedback when placing a building, including:
## - Drawing placement tile overlays
## - Managing preview tile highlights
## - Tracking the building being placed
## - Updating building position based on cursor
##
## This service is responsible for the visual/UI concerns of placement,
## separate from the core building management logic.
extends Node2D
class_name BuildingPlacementPreview


## The building being placed (null when no placement active)
var building: Building = null

## The target tile position for placement
var target_tile: Vector2i = Vector2i.ZERO

## Dictionary of valid build tiles: Vector2i -> TileData
var build_tiles: Dictionary = {}


## Set the building to preview at the specified tile
func set_preview(_building: Building, _tile: Vector2i, _build_tiles: Dictionary) -> void:
	building = _building
	target_tile = _tile
	build_tiles = _build_tiles
	_update_building_position(target_tile)


## Update the building position to follow cursor
func update_position(_tile: Vector2i) -> void:
	if building == null:
		return

	target_tile = _tile
	_update_building_position(_tile)


## Clear the preview (called when placement is cancelled/completed)
func clear_preview() -> void:
	building = null
	target_tile = Vector2i.ZERO
	build_tiles = {}
	queue_redraw()


## Check if there's an active preview
func has_preview() -> bool:
	return building != null


## Get the building being previewed (null if none)
func get_building() -> Building:
	return building


## Draw the preview tiles
func _draw() -> void:
	if building == null:
		return

	# Draw all valid build tiles
	for tile: Vector2 in build_tiles.keys():
		var tile_map_layer: TileMapLayer = Def.get_world_tile_map()
		var tile_size: Vector2 = tile_map_layer.tile_set.tile_size
		var tile_pos: Vector2 = global_position - tile_map_layer.map_to_local(tile)
		var tile_rect: Rect2 = Rect2(tile_pos - tile_size * 0.5, tile_size)

		draw_rect(tile_rect, Color(Color.WHITE, 0.5), true)


## Update building position based on tile
func _update_building_position(_tile: Vector2i) -> void:
	if building == null:
		return

	# Early exit if world map not available (e.g., in unit tests)
	if not get_tree().has_group("world"):
		return

	var tile_map_layer: TileMapLayer = Def.get_world_map().get_land_layer()
	var map_pos: Vector2 = tile_map_layer.map_to_local(_tile)
	building.global_position = map_pos

	# Offset for large buildings (2x2)
	if building.building_size == Term.BuildingSize.LARGE:
		building.global_position = map_pos + building.get_size() * 0.25

	queue_redraw()
