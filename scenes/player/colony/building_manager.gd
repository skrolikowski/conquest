## Building collection manager for a colony
##
## Responsibilities:
## - Manages the array of buildings in a colony
## - Tracks tile occupancy for buildings
## - Provides building queries and sorting
## - Handles save/load of building data
##
## This is a pure data manager - placement logic, terrain modification,
## and UI concerns are handled by separate services.
class_name BuildingManager
extends Node2D

@onready var build_list: Node2D = $BuildingList

@export var colony: CenterBuilding

## Array of all buildings in this colony
var buildings: Array[Building] = []

## Array of all occupied tiles (by buildings and colony center)
var occupy_tiles: Array[Vector2i] = []


#region BUILDING COLLECTION MANAGEMENT

## Get all buildings in the colony
func get_buildings() -> Array[Building]:
	return buildings


## Add a building to the colony
func add_building(_building: Building) -> void:
	buildings.append(_building)
	build_list.add_child(_building)


## Remove a building from the colony and free it
func remove_building(_building: Building) -> void:
	# Remove occupied tiles
	remove_occupied_tiles(_building.get_tiles())

	# Remove from array
	buildings.remove_at(buildings.find(_building))

	# Remove from scene tree and free
	build_list.remove_child(_building)
	_building.queue_free()


## Get buildings sorted by building type priority
func get_buildings_sorted_by_building_type() -> Array[Building]:
	var _buildings: Array[Building] = buildings.duplicate()
	_buildings.sort_custom(PreloadsRef.GR.sort_buildings_by_priority)
	return _buildings

#endregion


#region TILE OCCUPANCY MANAGEMENT

## Add tiles to the occupied tiles array and clear terrain
## Also updates TileCustomData occupancy tracking
func add_occupied_tiles(_tiles: Array[Vector2i], _building: Building = null) -> void:
	occupy_tiles.append_array(_tiles)

	# Update TileCustomData occupancy
	var world_gen: WorldGen = Def.get_world_map()
	for tile: Vector2i in _tiles:
		if world_gen.tile_custom_data.has(tile):
			world_gen.tile_custom_data[tile].set_occupied(_building)

	# Clear terrain for building placement
	TerrainModificationService.clear_terrain_for_building(_tiles)


## Remove tiles from the occupied tiles array and restore terrain
## Also clears TileCustomData occupancy tracking
func remove_occupied_tiles(_tiles: Array[Vector2i]) -> void:
	for tile: Vector2i in _tiles:
		occupy_tiles.erase(tile)

	# Clear TileCustomData occupancy
	var world_gen: WorldGen = Def.get_world_map()
	for tile: Vector2i in _tiles:
		if world_gen.tile_custom_data.has(tile):
			world_gen.tile_custom_data[tile].clear_occupied()

	# Restore terrain after building removal
	TerrainModificationService.restore_terrain_from_building(occupy_tiles)


## Refresh occupied tiles from all buildings in the colony
## Called when loading a saved game
## Also rebuilds TileCustomData occupancy tracking
func refresh_occupied_tiles() -> void:
	# Clear all existing TileCustomData occupancy first
	var world_gen: WorldGen = Def.get_world_map()
	for tile: Vector2i in occupy_tiles:
		if world_gen.tile_custom_data.has(tile):
			world_gen.tile_custom_data[tile].clear_occupied()

	# Rebuild from colony and buildings
	occupy_tiles = colony.get_tiles()

	# Set colony center occupancy
	for tile: Vector2i in colony.get_tiles():
		if world_gen.tile_custom_data.has(tile):
			world_gen.tile_custom_data[tile].set_occupied(colony)

	# Set building occupancy
	for building: Building in get_buildings():
		var building_tiles: Array[Vector2i] = building.get_tiles()
		occupy_tiles.append_array(building_tiles)
		for tile: Vector2i in building_tiles:
			if world_gen.tile_custom_data.has(tile):
				world_gen.tile_custom_data[tile].set_occupied(building)

	# Clear terrain for all occupied tiles
	TerrainModificationService.refresh_terrain_for_colony(occupy_tiles)


## Check if a tile is occupied by any building
func is_tile_occupied(_tile: Vector2i) -> bool:
	return occupy_tiles.has(_tile)


## Check if a single tile is buildable for a given building type
## Validates: not occupied (via TileCustomData), valid terrain, mountain rules (mines OK, others not)
func is_tile_buildable(_tile: Vector2i, _building_type: Term.BuildingType = Term.BuildingType.NONE) -> bool:
	var world_gen: WorldGen = Def.get_world_map()
	var tile_data: TileCustomData = world_gen.tile_custom_data.get(_tile)

	if tile_data == null:
		return false

	# Check if already occupied (centralized check via TileCustomData)
	if tile_data.is_occupied():
		return false

	# Terrain validation - must be land
	if not world_gen.is_land_tile(_tile):
		return false

	# Mountain check - only mines allowed on mountains
	#TODO: come back to this for other building types that may be allowed on mountains.. maybe all of them
	if tile_data.biome == WorldGen.TileCategory.MOUNTAIN:
		if _building_type != Term.BuildingType.METAL_MINE and _building_type != Term.BuildingType.GOLD_MINE:
			return false

	return true


## Filter candidate tiles to return only those that are buildable
## Useful for LocationFinder and building placement validation
func get_buildable_tiles(_candidates: Array[Vector2i], _building_type: Term.BuildingType = Term.BuildingType.NONE) -> Array[Vector2i]:
	var buildable: Array[Vector2i] = []

	for tile: Vector2i in _candidates:
		if is_tile_buildable(tile, _building_type):
			buildable.append(tile)

	return buildable


## Check if all tiles in a footprint are buildable for a given building type
func can_build_at(_tiles: Array[Vector2i], _building_type: Term.BuildingType = Term.BuildingType.NONE) -> bool:
	for tile: Vector2i in _tiles:
		if not is_tile_buildable(tile, _building_type):
			return false
	return true

#endregion


#region GAME PERSISTENCE

func on_save_data() -> Dictionary:
	# Package buildings
	var building_data: Array[Dictionary] = []
	for building: Building in get_buildings():
		building_data.append(building.on_save_data())

	return {
		"buildings": building_data,
	}


func on_load_data(_data: Dictionary) -> void:
	# Load buildings
	for building_data: Dictionary in _data["buildings"]:
		var building_scene: PackedScene = PreloadsRef.get_building_scene(building_data.building_type)
		var building: Building = building_scene.instantiate() as Building
		add_building(building)

		building.on_load_data(building_data)
		building.colony = colony
		building.player = colony.player

#endregion
