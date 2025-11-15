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
func add_occupied_tiles(_tiles: Array[Vector2i]) -> void:
	occupy_tiles.append_array(_tiles)

	# Clear terrain for building placement
	TerrainModificationService.clear_terrain_for_building(_tiles)


## Remove tiles from the occupied tiles array and restore terrain
func remove_occupied_tiles(_tiles: Array[Vector2i]) -> void:
	for tile: Vector2i in _tiles:
		occupy_tiles.erase(tile)

	# Restore terrain after building removal
	TerrainModificationService.restore_terrain_from_building(occupy_tiles)


## Refresh occupied tiles from all buildings in the colony
## Called when loading a saved game
func refresh_occupied_tiles() -> void:
	occupy_tiles = colony.get_tiles()

	for building: Building in get_buildings():
		occupy_tiles.append_array(building.get_tiles())

	# Clear terrain for all occupied tiles
	TerrainModificationService.refresh_terrain_for_colony(occupy_tiles)


## Check if a tile is occupied by any building
func is_tile_occupied(_tile: Vector2i) -> bool:
	return occupy_tiles.has(_tile)

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
