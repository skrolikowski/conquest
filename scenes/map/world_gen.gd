@tool
extends Node2D
class_name WorldGen

signal map_loaded

func _add_inspector_buttons() -> Array:
	var buttons : Array = []
	buttons.push_back({
		"name": "Generate Rivers",
		"pressed": generate_rivers
	})
	return buttons

# ---

enum TerrainSet
{
	NONE = -1,
	DEFAULT,
}

enum LandTerrain
{
	GRASS,
	NONE,
	RIVER,
}

enum BiomeTerrain
{
	SWAMP,
	FOREST,
	MOUNTAINS,
	NONE,
	UNFOREST,
}

enum MapLayer
{
	WATER,
	LAND,
	SHORE,
	BIOME,
}

enum NavLayer
{
	LAND,
	WATER,
}

enum NoiseGenLayer
{
	WATER,
	LAND,
	SWAMP,
	FOREST,
	MOUNTAINS,
}

const TILE_CURSOR     : Vector2i = Vector2i(5, 7)   # TEMP
const TILE_FOG_OF_WAR : Vector2i = Vector2i(13, 14) # TEMP

@export var rivers_enabled : bool = true

@onready var noise_gen    := $NoiseGenerator as NoiseGenerator
@onready var map_renderer := $TilemapGaeaRenderer as TilemapGaeaRenderer
@onready var tilemap_layers : Array[TileMapLayer]

# --
var terrain_modifier  : Dictionary = {}
# var artifact_modifier : Dictionary = {}

# -- Tile Data
var tile_heights 	  : Dictionary = {}
var highest_height    : float
var avg_land_height   : float

# -- Rivers
var river_sources : Array[Vector2i] = []
var river_tiles   : Array[Vector2i] = []
var rivers 	      : Array[Array] = []

var is_new_game : bool = false


# --
func _ready() -> void:
	tilemap_layers = map_renderer.tile_map_layers
	
	noise_gen.connect("generation_finished", _on_world_generated)


func fix_water_navigation() -> void:
	for tile: Vector2i in get_land_tiles():
		tilemap_layers[MapLayer.WATER].set_cell(tile, 2, Vector2i(9, 12))


func set_tile_data() -> void:
	var land_tiles   : Array[Vector2i] = get_land_tiles()
	var max_height   : float = 0.0
	var total_height : float = 0.0

	for tile: Vector2i in land_tiles:
		tile_heights[tile] = get_tile_height(tile)
		total_height += tile_heights[tile]

		if tile_heights[tile] > max_height:
			max_height = tile_heights[tile]

	avg_land_height = total_height / land_tiles.size()
	highest_height  = max_height


#region GAME PERSISTENCE
func new_game() -> void:
	print("[WorldGen] New Map")
	is_new_game = true
	noise_gen.generate()


func on_save_data() -> Dictionary:
	"""
	Returns save data for WorldGen
	"""
	return {
		"seed" : noise_gen.seed,
		"terrain_modifier": terrain_modifier,
		
		# -- Rivers
		"river_sources" : river_sources,
		"river_tiles"   : river_tiles,
		"rivers"        : rivers,
	}


func on_load_data(_data: Dictionary) -> void:
	print("[WorldGen] Load Game")
	noise_gen.seed = _data["seed"]
	noise_gen.generate()

	# -- Load Modifiers..
	terrain_modifier = _data["terrain_modifier"]
	
	# -- Load Rivers..
	river_sources = _data["river_sources"]
	river_tiles = _data["river_tiles"]
	rivers = _data["rivers"]

#endregion


#region WORLD GENERATION
func _on_world_generated() -> void:
	if is_new_game:
		call_deferred("populate_new_world")
		is_new_game = false
	else:
		call_deferred("populate_old_world")


func populate_new_world() -> void:
	set_tile_data()
	fix_water_navigation()
	
	# -- Rivers..
	if rivers_enabled:
		generate_rivers()
	
	# -- Modifiers..
	generate_terrain_modifiers()
	#generate_artifacts()
	
	# -- Fog of war..
	# if Def.FOG_OF_WAR_ENABLED:
	# 	generate_fog_of_war()

	# --
	print("[WorldGen] Map Loaded!")
	map_loaded.emit()


func populate_old_world() -> void:
	set_tile_data()
	fix_water_navigation()
	
	# -- Rivers..
	if rivers_enabled:
		add_rivers_to_map()

	# -- Fog of War..
	# TODO:
	
	# --
	print("[WorldGen] Map Loaded!")
	map_loaded.emit()

#endregion


#region HELPERS
func get_water_layer() -> TileMapLayer:
	return tilemap_layers[MapLayer.WATER]

func get_water_tiles() -> Array[Vector2i]:
	return get_water_layer().get_used_cells()

func get_land_layer() -> TileMapLayer:
	return tilemap_layers[MapLayer.LAND]

func get_land_tiles() -> Array[Vector2i]:
	return get_land_layer().get_used_cells()


func get_shore_tiles() -> Array[Vector2i]:
	return tilemap_layers[MapLayer.SHORE].get_used_cells()


func get_biome_layer() -> TileMapLayer:
	return tilemap_layers[MapLayer.BIOME]

func get_biome_tiles() -> Array[Vector2i]:
	return tilemap_layers[MapLayer.BIOME].get_used_cells()


# func get_cursor_tiles() -> Array[Vector2i]:
# 	return tilemap_layers[MapLayer.CURSOR].get_used_cells()


func is_river_tile(_tile: Vector2i) -> bool:
	return _tile in river_tiles


func is_sea_tile(_tile: Vector2i) -> bool:
	return tile_heights[_tile] < 0.0


func is_water_tile(_tile: Vector2i) -> bool:
	return is_river_tile(_tile) or is_sea_tile(_tile)


func is_shore_tile(_tile: Vector2i) -> bool:
	return _tile in get_shore_tiles()


func is_land_tile(_tile: Vector2i) -> bool:
	return _tile in get_land_tiles()


func get_tile_height(_tile: Vector2i) -> float:
	var noise : float = noise_gen.settings.noise.get_noise_2d(_tile.x, _tile.y)
	if noise_gen.settings.falloff_enabled and noise_gen.settings.falloff_map and not noise_gen.settings.infinite:
		noise = ((noise + 1) * noise_gen.settings.falloff_map.get_value(_tile)) - 1.0
	return noise


func get_tiles_in_radius(_pos:Vector2, _radius:float) -> Array[Vector2i]:
	"""
	Returns a list of tiles within a given radius from a given local position
	"""
	var center_tile : Vector2i = tilemap_layers[MapLayer.LAND].local_to_map(_pos)
	var center_pos  : Vector2 = tilemap_layers[MapLayer.LAND].map_to_local(center_tile)
	# --
	var area_size  : Vector2 = Vector2(_radius, _radius)
	var first_tile : Vector2i = tilemap_layers[MapLayer.LAND].local_to_map(center_pos - area_size)
	var last_tile  : Vector2i = tilemap_layers[MapLayer.LAND].local_to_map(center_pos + area_size)
	var tiles      : Array[Vector2i] = []
	
	for x: int in range(first_tile.x, last_tile.x + 1):
		for y: int in range(first_tile.y, last_tile.y + 1):
			var tile     : Vector2i = Vector2i(x, y)
			var tile_pos : Vector2 = tilemap_layers[MapLayer.LAND].map_to_local(tile)
			
			if _pos.distance_to(tile_pos) <= _radius:
				tiles.append(tile)

	return tiles


func get_random_shore_tile() -> Vector2i:
	var shore_tiles : Array[Vector2i] = get_shore_tiles()
	return shore_tiles[randi() % shore_tiles.size()]


func get_terrain_modifier_value(_tile:Vector2i, _resource_type:Term.ResourceType) -> int:
	if terrain_modifier.has(_tile):
		var source : Transaction = terrain_modifier[_tile]
		return source.get_resource_amount(_resource_type)
	return 0

#endregion




#region RIVERS
func generate_river_sources() -> void:
	river_sources.clear()
	
	var min_height   : float = avg_land_height + 0.13
	var max_height   : float = avg_land_height + 0.18
	var river_chance : float = 0.25
	print("River Height Range: %.2f - %.2f" % [min_height, max_height])
	
	for tile: Vector2i in get_biome_tiles():
		var height : float = get_tile_height(tile)
		if height >= min_height and height <= max_height and randf() < river_chance:
			river_sources.append(Vector2i(tile.x, tile.y))


func generate_rivers() -> void:
	river_tiles.clear()
	rivers.clear()

	# --
	generate_river_sources()
	print("Generating %d river(s)..." % river_sources.size())
	
	# --
	for source : Vector2i in river_sources:
		rivers.append(generate_river(source))


	add_rivers_to_map()


func generate_river(_tile: Vector2i, _river : Array[Vector2i] = []) -> Array[Vector2i]:
	if is_shore_tile(_tile):
		return _river

	var lowest_neighbor : Vector2i = _get_lowest_neighbor(_tile)
	if lowest_neighbor in river_tiles:
		return _river

	# --
	_river.append(_tile)
	river_tiles.append(_tile)

	# --
	return generate_river(lowest_neighbor, _river)


func add_rivers_to_map() -> void:
	tilemap_layers[MapLayer.LAND].set_cells_terrain_connect(
		river_tiles, TerrainSet.DEFAULT, LandTerrain.RIVER, true)

	tilemap_layers[MapLayer.BIOME].set_cells_terrain_connect(
		river_tiles, TerrainSet.DEFAULT, BiomeTerrain.NONE, true)


func _get_lowest_neighbor(_tile:Vector2i) -> Vector2i:
	var neighbors       : Array[Vector2i] = tilemap_layers[MapLayer.LAND].get_surrounding_cells(_tile)
	var lowest_neighbor : Vector2i
	var lowest_height   : float = 1.0
	
	for neighbor : Vector2i in neighbors:
		var neighbor_height : float = get_tile_height(neighbor)
		if neighbor_height < lowest_height:
			lowest_neighbor = neighbor
			lowest_height   = neighbor_height

	return lowest_neighbor

#endregion


#region CURSOR
func set_cursor_tile(_tile: Vector2i) -> void:
	#tilemap_layers[MapLayer.CURSOR].set_cell(_tile, SourceID.WATER, TILE_CURSOR)
	pass


func clear_cursor_tiles() -> void:
	#for tile: Vector2i in get_cursor_tiles():
		#tilemap_layers[MapLayer.CURSOR].set_cell(tile, SourceID.NONE)
	pass
	
#endregion


#region FOG OF WAR
func generate_fog_of_war() -> void:
	#for tile: Vector2i in tile_map.get_used_cells(MapLayer.LAND):
		#tile_map.set_cell(MapLayer.FOGOFWAR, tile, SourceID.WATER, TILE_FOG_OF_WAR)
	pass


func reveal_fog_of_war(_pos: Vector2, _radius: float = 1) -> void:
	#var tile : Vector2i = tile_map.local_to_map(_pos)
	#if tile_map.get_cell_source_id(MapLayer.FOGOFWAR, tile) != -1:
		#var tiles : Array[Vector2i] = get_tiles_in_radius(_pos, _radius)
		#for _tile: Vector2i in tiles:
			#tile_map.set_cell(MapLayer.FOGOFWAR, _tile, SourceID.NONE)
	pass

#endregion


#region TERRAFORMING
func terraform_biome_tiles(_tiles: Array[Vector2i], _from_terrain: BiomeTerrain, _to_terrain: BiomeTerrain) -> void:
	var clear_tiles : Array[Vector2i] = []

	for tile: Vector2i in _tiles:
		var tile_data : TileData = get_biome_layer().get_cell_tile_data(tile)
		if tile_data != null:
			if tile_data.terrain == _from_terrain:
				clear_tiles.append(tile)

	# --
	get_biome_layer().set_cells_terrain_connect(
		clear_tiles, TerrainSet.DEFAULT, _to_terrain, true)

#endregion


#region RESOURCES
func generate_terrain_modifiers() -> void:

	# -- Industry modifiers based on land height..
	generate_industry_modifier(Term.IndustryType.MINE)
	generate_industry_modifier(Term.IndustryType.MILL)
	generate_industry_modifier(Term.IndustryType.FARM)


func generate_industry_modifier(_industry_type:Term.IndustryType) -> void:
	var data : Dictionary = get_source_tiles_by_industry_type(_industry_type)
	
	for source: Vector2i in data:
		var resource_type : Term.ResourceType = data[source].resource_type
		var bonus : int = data[source].bonus

		# -- add modifier to source tile..
		add_terrain_modifier(source, resource_type, bonus)
		if not terrain_modifier.has(source):
			terrain_modifier[source] = Transaction.new()

		# -- ..and to surrounding tiles
		var tiles : Array[Vector2i] = tilemap_layers[MapLayer.LAND].get_surrounding_cells(source)
		for tile : Vector2i in tiles:
			if bonus > 0:
				add_terrain_modifier(tile, resource_type, floor(bonus * 0.5))


func add_terrain_modifier(_tile:Vector2i, _resource_type:Term.ResourceType, _bonus:float) -> void:
	if not terrain_modifier.has(_tile):
		terrain_modifier[_tile] = Transaction.new()

	# -- add bonus
	var transaction : Transaction = terrain_modifier[_tile]
	transaction.add_resource_amount_by_type(_resource_type, _bonus)


func get_terrain_modifier(_tile:Vector2i) -> Transaction:
	if terrain_modifier.has(_tile):
		return terrain_modifier[_tile]
	return Transaction.new()


func get_terrain_modifier_by_industry_type(_tile:Vector2i) -> Dictionary:
	var source : Transaction = get_terrain_modifier(_tile)
	var result : Dictionary = {}
	
	for i:String in Term.ResourceType:
		var resource_type  : Term.ResourceType = Term.ResourceType[i]
		var resource_value : int = source.get_resource_amount(resource_type)

		if resource_type == Term.ResourceType.METAL:
			result[Term.IndustryType.MINE] = resource_value
		elif resource_type == Term.ResourceType.WOOD:
			result[Term.IndustryType.MILL] = resource_value
		elif resource_type == Term.ResourceType.CROPS:
			result[Term.IndustryType.FARM] = resource_value
	
	return result


func get_terrain_modifier_value_by_industry_type(_tile:Vector2i, _industry_type:Term.IndustryType) -> int:
	if terrain_modifier.has(_tile):
		var source : Transaction = terrain_modifier[_tile]
		for i:String in Term.ResourceType:
			var resource_type  : Term.ResourceType = Term.ResourceType[i]
			var resource_value : int = source.get_resource_amount(resource_type)
			
			if _industry_type == Term.IndustryType.MINE and resource_type == Term.ResourceType.METAL:
				return resource_value
			if _industry_type == Term.IndustryType.MILL and resource_type == Term.ResourceType.WOOD:
				return resource_value
			if _industry_type == Term.IndustryType.FARM and resource_type == Term.ResourceType.CROPS:
				return resource_value
	
	return 0


func get_source_tiles_by_industry_type(_industry_type: Term.IndustryType) -> Dictionary:
	"""
	Returns a list of tiles that are suitable for a given industry type
	"""
	var tiles          : Dictionary = {}
	var rng            : RandomNumberGenerator = RandomNumberGenerator.new()
	var swamp_biome    : NoiseGeneratorData = noise_gen.settings.tiles[NoiseGenLayer.SWAMP]
	var forest_biome   : NoiseGeneratorData = noise_gen.settings.tiles[NoiseGenLayer.FOREST]
	var mountain_biome : NoiseGeneratorData = noise_gen.settings.tiles[NoiseGenLayer.MOUNTAINS]
	
	for tile: Vector2i in get_land_tiles():
		var height : float = tile_heights[tile]

		if _industry_type == Term.IndustryType.MINE:
			
			# Threshold: SWAMP-
			if height < swamp_biome.max:
				tiles[tile] = { "resource_type": Term.ResourceType.METAL, "bonus": 0 }

			# Threshold: MOUNTAINS-
			elif height < mountain_biome.min:
				if randf() > 0.75:
					tiles[tile] = { "resource_type": Term.ResourceType.METAL, "bonus": rng.randi_range(0, 5) }
				else:
					tiles[tile] = { "resource_type": Term.ResourceType.METAL, "bonus": 0 }

			# Threshold: MOUNTAINS
			elif height >= mountain_biome.min and height <= mountain_biome.max:
				if randf() > 0.75:
					tiles[tile] = { "resource_type": Term.ResourceType.METAL, "bonus": rng.randi_range(35, 65) }
				else:
					tiles[tile] = { "resource_type": Term.ResourceType.METAL, "bonus": rng.randi_range(10, 35) }

				#TODO: boost if next to river tile

		elif _industry_type == Term.IndustryType.MILL:

			# Threshold: FOREST-
			if height > 0 and height < forest_biome.min:
				tiles[tile] = { "resource_type": Term.ResourceType.WOOD, "bonus": rng.randi_range(5, 25) }

			# Threshold: FOREST
			elif height >= forest_biome.min and height <= forest_biome.max:
				if randf() > 0.75:
					tiles[tile] = { "resource_type": Term.ResourceType.WOOD, "bonus": rng.randi_range(35, 50) }
				else:
					tiles[tile] = { "resource_type": Term.ResourceType.WOOD, "bonus": rng.randi_range(25, 35) }

			# Threshold: FOREST+
			elif height > forest_biome.min:
				tiles[tile] = { "resource_type": Term.ResourceType.CROPS, "bonus": rng.randi_range(0, 25) }

		elif _industry_type == Term.IndustryType.FARM:

			# Threshold: SWAMP
			if height >= swamp_biome.min and height <= swamp_biome.max:
				if randf() > 0.75:
					tiles[tile] = { "resource_type": Term.ResourceType.CROPS, "bonus": rng.randi_range(35, 50) }
				else:
					tiles[tile] = { "resource_type": Term.ResourceType.CROPS, "bonus": rng.randi_range(25, 35) }
			
			# Threshold: Swamp / Forest
			elif height > swamp_biome.max and height < forest_biome.min:
				tiles[tile] = { "resource_type": Term.ResourceType.CROPS, "bonus": rng.randi_range(5, 25) }

			# Threshold: FOREST
			elif height >= forest_biome.min and height <= forest_biome.max:
				tiles[tile] = { "resource_type": Term.ResourceType.CROPS, "bonus": rng.randi_range(0, 15) }

			# Threshold: FOREST+
			elif height > forest_biome.min:
				tiles[tile] = { "resource_type": Term.ResourceType.CROPS, "bonus": -100 }

	return tiles

#endregion
