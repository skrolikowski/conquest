## Service for terrain modifications when buildings are placed/removed
##
## Handles:
## - Clearing forests when buildings are placed
## - Clearing mountains when buildings are placed
## - Restoring forests when buildings are removed
## - Restoring mountains when buildings are removed
##
## This separates terrain concerns from building management logic.
class_name TerrainModificationService
extends RefCounted


## Clear terrain (forests/mountains) for building placement
## Called when a building is placed on tiles
static func clear_terrain_for_building(tiles: Array[Vector2i]) -> void:
	var world_map: WorldGen = Def.get_world_map()
	if world_map == null:
		push_warning("TerrainModificationService: WorldMap not available")
		return

	# Remove forests and mountains from occupied tiles
	world_map.terraform_biome_tiles(tiles, WorldGen.BiomeTerrain.FOREST, WorldGen.BiomeTerrain.UNFOREST)
	world_map.terraform_biome_tiles(tiles, WorldGen.BiomeTerrain.MOUNTAINS, WorldGen.BiomeTerrain.UNMOUNTAIN)


## Restore terrain (forests/mountains) when building is removed
## Called when a building is demolished
static func restore_terrain_from_building(tiles: Array[Vector2i]) -> void:
	var world_map: WorldGen = Def.get_world_map()
	if world_map == null:
		push_warning("TerrainModificationService: WorldMap not available")
		return

	# Restore forests and mountains to previously occupied tiles
	# Note: This restores to UNFOREST/UNMOUNTAIN state, not full restoration
	# The actual biome restoration happens in the world map logic
	world_map.terraform_biome_tiles(tiles, WorldGen.BiomeTerrain.UNFOREST, WorldGen.BiomeTerrain.FOREST)
	world_map.terraform_biome_tiles(tiles, WorldGen.BiomeTerrain.UNMOUNTAIN, WorldGen.BiomeTerrain.MOUNTAINS)


## Refresh terrain for all occupied tiles in a colony
## Called when loading a saved game or initializing colony
static func refresh_terrain_for_colony(occupied_tiles: Array[Vector2i]) -> void:
	var world_map: WorldGen = Def.get_world_map()
	if world_map == null:
		push_warning("TerrainModificationService: WorldMap not available")
		return

	# Clear all occupied tiles (forests and mountains)
	world_map.terraform_biome_tiles(occupied_tiles, WorldGen.BiomeTerrain.FOREST, WorldGen.BiomeTerrain.UNFOREST)
	world_map.terraform_biome_tiles(occupied_tiles, WorldGen.BiomeTerrain.MOUNTAINS, WorldGen.BiomeTerrain.UNMOUNTAIN)
