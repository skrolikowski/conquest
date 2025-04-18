@tool
extends Node2D
class_name WorldGen

signal map_loaded

func _add_inspector_buttons() -> Array:
	var buttons : Array = []
	buttons.push_back({
		"name": "Generate Rivers",
		"pressed": _generate_rivers
	})
	return buttons

# ---

enum TileCategory
{
	OCEAN,
	RIVER,
	GRASS,
	FOREST,
	SWAMP,
	MOUNTAIN,
}

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
	UNMOUNTAIN,
}

enum FogTerrain
{
	NONE,
	FOG,
}

enum MapLayer
{
	WATER,
	LAND,
	SHORE,
	BIOME,
	FOGOFWAR,
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
	FOGOFWAR,
}

# const TILE_CURSOR     : Vector2i = Vector2i(5, 7)   # TEMP
# const TILE_FOG_OF_WAR : Vector2i = Vector2i(13, 14) # TEMP

@export var rivers_enabled : bool = true

@onready var noise_gen    := $NoiseGenerator as NoiseGenerator
@onready var map_renderer := $TilemapGaeaRenderer as TilemapGaeaRenderer

# -- Map Data
var tilemap_layers  : Array[TileMapLayer]
var tile_heights 	: Dictionary = {}
var highest_height  : float
var avg_land_height : float
var tile_rows       : int
var tile_cols       : int

# -- Tile Data
var tile_custom_data : Dictionary = {}

# -- Mountains
var mountain_ranges : Array[MountainRange] = []

# -- Rivers
var rivers : Array[River] = []


func _ready() -> void:
	tilemap_layers = map_renderer.tile_map_layers


#region GAME PERSISTENCE
func new_game() -> void:
	print("[WorldGen] New Map")
	noise_gen.connect("generation_finished", _on_new_world_generated, CONNECT_ONE_SHOT)
	noise_gen.generate()


func on_save_data() -> Dictionary:
	"""
	Returns save data for WorldGen
	"""

	# -- Package tile custom data..
	var _tile_custom_data : Dictionary = {}
	for tile: Vector2i in tile_custom_data:
		var tile_custom_datum : TileCustomData = tile_custom_data[tile]
		_tile_custom_data[tile] = tile_custom_datum.on_save_data()

	# -- Package rivers..
	var _rivers : Array[Dictionary] = []
	for river: River in rivers:
		_rivers.append(river.on_save_data())

	# --
	return {
		"water_layer" : get_water_layer().tile_map_data,
		"land_layer" : get_land_layer().tile_map_data,
		"shore_layer" : get_shore_layer().tile_map_data,
		"biome_layer" : get_biome_layer().tile_map_data,
		# --
		"tile_custom_data" : _tile_custom_data,
		"rivers" : _rivers,
	}


func on_load_data(_data: Dictionary) -> void:
	print("[WorldGen] Load Game")

	# -- Load tilemaplayer data..
	get_water_layer().tile_map_data = _data["water_layer"]
	get_land_layer().tile_map_data = _data["land_layer"]
	get_shore_layer().tile_map_data = _data["shore_layer"]
	get_biome_layer().tile_map_data = _data["biome_layer"]

	# -- Load tile custom data..
	for tile: Vector2i in _data["tile_custom_data"]:
		tile_custom_data[tile] = TileCustomData.new()
		tile_custom_data[tile].on_load_data(_data["tile_custom_data"][tile])

	# -- Load rivers..
	for river_data: Dictionary in _data["rivers"]:
		var river : River = River.new()
		river.on_load_data(river_data)
		rivers.append(river)
		
	# --
	set_map_data()

	# --
	map_loaded.emit()

#endregion


#region WORLD GENERATION
func _on_new_world_generated() -> void:
	#HACK: delay to allow tilemap layers to be generated
	call_deferred("on_new_world_generated")

func on_new_world_generated() -> void:
	set_map_data()
	refresh_water_navigation()
	init_tile_custom_data()
	
	# -- Mountains..
	_generate_mountains()
	_add_mountains_to_map()

	# -- Rivers..
	if rivers_enabled:
		_generate_rivers()
		_generate_ocean_access_tiles()
		_add_rivers_to_map()
	
	# -- Modifiers..
	# generate_terrain_modifiers()
	set_terrain_modifiers()
	
	# -- Fog of war..
	generate_fog_of_war()

	# --
	map_loaded.emit()


func set_map_data() -> void:
	tile_cols = get_water_layer().get_used_rect().size.x
	tile_rows = get_water_layer().get_used_rect().size.y

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


func refresh_water_navigation() -> void:
	"""
	Disables navigation for water tiles covered by land tiles
	"""
	for tile: Vector2i in get_land_tiles():
		get_water_layer().set_cell(tile, 2, Vector2i(9, 12))


func init_tile_custom_data() -> void:
	"""
	[NEW GAME]
	"""
	tile_custom_data.clear()

	"""
	1) Sets water tile custom data (e.g. is_water = true)
	2) Sets water tiles covered by land (e.g. is_water = false)
	"""
	for tile : Vector2i in get_water_tiles():
		tile_custom_data[tile] = TileCustomData.new()
		tile_custom_data[tile].is_water = true
		tile_custom_data[tile].biome = TileCategory.OCEAN

	# -- Land tiles..
	for tile: Vector2i in get_land_tiles():
		tile_custom_data[tile].is_water = false

		# -- Set tile biome..
		var swamp_biome  : NoiseGeneratorData = noise_gen.settings.tiles[NoiseGenLayer.SWAMP]
		var forest_biome : NoiseGeneratorData = noise_gen.settings.tiles[NoiseGenLayer.FOREST]
		var height : float = tile_heights[tile]
		
		if height >= forest_biome.min and height <= forest_biome.max:
			tile_custom_data[tile].biome = TileCategory.FOREST
		elif height >= swamp_biome.min and height <= swamp_biome.max:
			tile_custom_data[tile].biome = TileCategory.SWAMP
		else:
			tile_custom_data[tile].biome = TileCategory.GRASS

	# -- Shore tiles..
	for tile: Vector2i in get_shore_tiles():
		tile_custom_data[tile].is_shore = true

	# --
	_flood_fill_ocean_tiles(Vector2i.ZERO)


func _flood_fill_ocean_tiles(_tile: Vector2i) -> void:
	var queue : Array = [_tile]
	var visited : Dictionary = {}

	while queue.size() > 0:
		var tile : Vector2i = queue.pop_front()
		visited[tile] = true

		if not tile_custom_data[tile].is_water or tile_custom_data[tile].is_ocean:
			continue
			
		tile_custom_data[tile].is_ocean = true

		for neighbor : Vector2i in get_water_layer().get_surrounding_cells(tile):
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= tile_cols or neighbor.y >= tile_rows:
				continue
			if not visited.has(neighbor):
				queue.append(neighbor)

#endregion


#region LAYERS/TILES
func get_water_layer() -> TileMapLayer:
	return tilemap_layers[MapLayer.WATER]

func get_water_tiles() -> Array[Vector2i]:
	return get_water_layer().get_used_cells()

func get_land_layer() -> TileMapLayer:
	return tilemap_layers[MapLayer.LAND]

func get_land_tiles() -> Array[Vector2i]:
	return get_land_layer().get_used_cells()

func get_shore_layer() -> TileMapLayer:
	return tilemap_layers[MapLayer.SHORE]

func get_shore_tiles() -> Array[Vector2i]:
	return get_shore_layer().get_used_cells()

func get_biome_layer() -> TileMapLayer:
	return tilemap_layers[MapLayer.BIOME]

func get_biome_tiles() -> Array[Vector2i]:
	return get_biome_layer().get_used_cells()

func get_fog_layer() -> TileMapLayer:
	return tilemap_layers[MapLayer.FOGOFWAR]

func get_fog_tiles() -> Array[Vector2i]:
	return get_fog_layer().get_used_cells()

#endregion


#region TILE DATA
func get_tile_custom_data(_tile: Vector2i) -> TileCustomData:
	if tile_custom_data.has(_tile):
		return tile_custom_data[_tile]
	return null

func is_river_tile(_tile: Vector2i) -> bool:
	if tile_custom_data.has(_tile):
		return tile_custom_data[_tile].is_river
	return false

func is_water_tile(_tile: Vector2i) -> bool:
	if tile_custom_data.has(_tile):
		return tile_custom_data[_tile].is_water
	return false

func is_land_tile(_tile: Vector2i) -> bool:
	if tile_custom_data.has(_tile):
		return not tile_custom_data[_tile].is_water
	return false

func is_ocean_tile(_tile: Vector2i) -> bool:
	if tile_custom_data.has(_tile):
		return tile_custom_data[_tile].is_ocean
	return false

func is_shore_tile(_tile: Vector2i) -> bool:
	if tile_custom_data.has(_tile):
		return tile_custom_data[_tile].is_shore
	return false

func has_ocean_access_tile(_tile: Vector2i) -> bool:
	if tile_custom_data.has(_tile):
		return tile_custom_data[_tile].has_ocean_access
	return false


func get_tile_height(_tile: Vector2i) -> float:
	var noise : float = noise_gen.settings.noise.get_noise_2d(_tile.x, _tile.y)
	if noise_gen.settings.falloff_enabled and noise_gen.settings.falloff_map and not noise_gen.settings.infinite:
		noise = ((noise + 1) * noise_gen.settings.falloff_map.get_value(_tile)) - 1.0
	return noise


func _get_lowest_neighbor(_tile:Vector2i) -> Vector2i:
	var lowest_neighbor : Vector2i
	var lowest_height   : float = 1.0
	
	for neighbor : Vector2i in get_land_layer().get_surrounding_cells(_tile):
		var neighbor_height : float = get_tile_height(neighbor)
		if neighbor_height < lowest_height:
			lowest_neighbor = neighbor
			lowest_height   = neighbor_height

	return lowest_neighbor


func get_tiles_in_rect(_pos:Vector2, _size:Vector2, _mapLayer:MapLayer = MapLayer.WATER) -> Array[Vector2i]:
	var center_tile : Vector2i = tilemap_layers[_mapLayer].local_to_map(_pos)
	var center_pos  : Vector2 = tilemap_layers[_mapLayer].map_to_local(center_tile)
	# --
	var first_tile : Vector2i = tilemap_layers[_mapLayer].local_to_map(center_pos - _size)
	var last_tile  : Vector2i = tilemap_layers[_mapLayer].local_to_map(center_pos + _size)
	var tiles      : Array[Vector2i] = []
	
	for x: int in range(first_tile.x, last_tile.x + 1):
		for y: int in range(first_tile.y, last_tile.y + 1):
			tiles.append(Vector2i(x, y))

	return tiles


func get_tiles_in_radius(_pos:Vector2, _radius:float, _mapLayer:MapLayer = MapLayer.WATER) -> Array[Vector2i]:
	"""
	Returns a list of tiles within a given radius from a given local position
	"""
	var center_tile : Vector2i = tilemap_layers[_mapLayer].local_to_map(_pos)
	var center_pos  : Vector2 = tilemap_layers[_mapLayer].map_to_local(center_tile)
	# --
	var area_size  : Vector2 = Vector2(_radius, _radius)
	var first_tile : Vector2i = tilemap_layers[_mapLayer].local_to_map(center_pos - area_size)
	var last_tile  : Vector2i = tilemap_layers[_mapLayer].local_to_map(center_pos + area_size)
	var tiles      : Array[Vector2i] = []
	
	for x: int in range(first_tile.x, last_tile.x + 1):
		for y: int in range(first_tile.y, last_tile.y + 1):
			var tile     : Vector2i = Vector2i(x, y)
			var tile_pos : Vector2 = tilemap_layers[_mapLayer].map_to_local(tile)
			
			if _pos.distance_to(tile_pos) <= _radius:
				tiles.append(tile)
				
	return tiles


func get_random_starting_tile() -> Vector2i:
	var shore_tiles : Array[Vector2i] = get_shore_tiles()
	#TODO: filter out non ocean-access tiles..
	return shore_tiles[randi() % shore_tiles.size()]


func get_random_height_range_tile(_min_height:float, _max_height:float) -> Vector2i:
	var select_tiles : Array[Vector2i] = []
	for tile:Vector2i in get_land_tiles():
		var height : float = get_tile_height(tile)
		if height >= _min_height and height <= _max_height:
			select_tiles.append(tile)
	return select_tiles[randi() % select_tiles.size()]


func get_terrain_modifier_value_by_industry_type(_tile:Vector2i, _industry_type:Term.IndustryType) -> int:
	if tile_custom_data.has(_tile):
		return tile_custom_data[_tile].terrain_modifier[_industry_type]
	return 0

#endregion


#region MOUNTAINS / RANGES
func _generate_mountains() -> void:
	mountain_ranges.clear()

	# --
	var source_tiles : Array[Vector2i] = _generate_mountain_sources()
	print("Generating %d mountain(s)..." % source_tiles.size())
	
	# --
	for source: Vector2i in source_tiles:
		mountain_ranges.append(_generate_mountain_range(source))


func _add_mountains_to_map() -> void:
	for mountain : MountainRange in mountain_ranges:
		get_biome_layer().set_cells_terrain_connect(mountain.tiles, TerrainSet.DEFAULT, BiomeTerrain.MOUNTAINS, true)


func _generate_mountain_sources() -> Array[Vector2i]:
	var source_tiles : Array[Vector2i] = []

	var min_height : float = highest_height - highest_height * 0.15
	var max_height : float = highest_height
	var gen_chance : float = 0.25
	print("Mountain Height Range: %.2f - %.2f" % [min_height, max_height])
	
	for tile: Vector2i in get_biome_tiles():
		var height : float = tile_heights[tile]
		if height >= min_height and height <= max_height and randf() < gen_chance:
			source_tiles.append(Vector2i(tile.x, tile.y))
	
	return source_tiles


func _generate_mountain_range(_tile: Vector2i, _range : Array[Vector2i] = []) -> MountainRange:
	var tile_data : TileCustomData = tile_custom_data[_tile]
	
	if tile_data.is_water or tile_data.biome == TileCategory.MOUNTAIN:
		print("Mountain ended by.. water or mountain. Size: " + str(_range.size()))
		return MountainRange.create(self, _range)
	if tile_heights[_tile] <= highest_height - highest_height * 0.65:
		print("Mountain ended by.. height " + str(highest_height - highest_height * 0.45) + ". Size: " + str(_range.size()))
		return MountainRange.create(self, _range)
	var lowest_neighbor : Vector2i = _get_lowest_neighbor(_tile)
	if lowest_neighbor == null:
		print("Mountain ended by.. no lowest neighbor. Size: " + str(_range.size()))
		return MountainRange.create(self, _range)

	# --
	_range.append(_tile)

	# -- update tile_custom_data[_tile]..
	tile_custom_data[_tile].biome = TileCategory.MOUNTAIN

	# --
	return _generate_mountain_range(lowest_neighbor, _range)

#endregion


#region RIVERS
func _generate_rivers() -> void:
	rivers.clear()

	# --
	var river_sources : Array[Vector2i] = _generate_river_sources()
	print("Generating %d river(s)..." % river_sources.size())
	
	# --
	for source: Vector2i in river_sources:
		rivers.append(_generate_river(source))


func _add_rivers_to_map() -> void:
	for river : River in rivers:
		get_land_layer().set_cells_terrain_path(river.tiles, TerrainSet.DEFAULT, LandTerrain.RIVER, true)
		get_biome_layer().set_cells_terrain_path(river.tiles, TerrainSet.DEFAULT, BiomeTerrain.NONE, true)


func _generate_river(_tile: Vector2i, _river : Array[Vector2i] = []) -> River:
	if is_water_tile(_tile):
		return River.create(self, _river)

	var lowest_neighbor : Vector2i = _get_lowest_neighbor(_tile)
	if lowest_neighbor == null:
		return River.create(self, _river)

	# --
	_river.append(_tile)

	# -- update tile_custom_data[_tile]..
	tile_custom_data[_tile].is_water = true
	tile_custom_data[_tile].biome = TileCategory.RIVER

	# --
	return _generate_river(lowest_neighbor, _river)


func _generate_river_sources() -> Array[Vector2i]:
	var river_sources : Array[Vector2i] = []
	var min_height    : float = highest_height - highest_height * 0.35
	var max_height    : float = highest_height - highest_height * 0.32
	var river_chance  : float = 0.25
	print("River Height Range: %.2f - %.2f" % [min_height, max_height])
	
	for tile: Vector2i in get_biome_tiles():
		var height : float = get_tile_height(tile)
		if height >= min_height and height <= max_height and randf() < river_chance:
			river_sources.append(Vector2i(tile.x, tile.y))
	
	return river_sources


func _generate_ocean_access_tiles() -> void:
	for tile : Vector2i in get_shore_tiles():
		if is_ocean_tile(tile):
			for neighbor : Vector2i in get_water_layer().get_surrounding_cells(tile):
				if is_river_tile(neighbor):
					_flood_fill_ocean_access_tiles(neighbor)


func _flood_fill_ocean_access_tiles(_tile: Vector2i) -> void:
	var queue : Array = [ _tile ]
	var visited : Dictionary = { }

	while queue.size() > 0:
		var tile : Vector2i = queue.pop_front()
		visited[tile] = true
		
		tile_custom_data[tile].has_ocean_access = true

		for neighbor : Vector2i in get_water_layer().get_surrounding_cells(tile):
			if not visited.has(neighbor) and is_water_tile(neighbor) and not is_ocean_tile(neighbor):
				queue.append(neighbor)

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
	if Def.FOG_OF_WAR_ENABLED:
		#TODO: eventually when we have multiple players we will want to store this per player..
		
		# get_fog_layer().set_cells_terrain_connect(
		# 	get_water_tiles(), TerrainSet.DEFAULT, FogTerrain.FOG, true)
		for tile : Vector2i in get_water_tiles():
			get_fog_layer().set_cell(tile, 0, Vector2i(9, 2))


func reveal_fog_of_war(_pos: Vector2, _radius: float = 48.0) -> void:
	if Def.FOG_OF_WAR_ENABLED:
		var tiles_in_range : Array[Vector2i] = get_tiles_in_radius(_pos, _radius)
		get_fog_layer().set_cells_terrain_connect(
			tiles_in_range, TerrainSet.DEFAULT, FogTerrain.NONE, true)

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


#region TERRAIN MODIFIERS
func set_terrain_modifiers() -> void:
	for tile: Vector2i in get_land_tiles():
		if not tile_custom_data[tile].is_river:
			var tile_pos : Vector2 = get_water_layer().map_to_local(tile)

			# -- For farm productivity..
			if tile_custom_data[tile].biome == TileCategory.MOUNTAIN:
				pass
			else:
				for tile_in_range : Vector2i in get_tiles_in_rect(tile_pos, Def.TILE_SIZE * 1.5):
					if tile_custom_data.has(tile_in_range):
						var industry_modifiers : Dictionary = tile_custom_data[tile_in_range].industry_modifiers
						tile_custom_data[tile].add_terrain_modifier(Term.IndustryType.FARM, industry_modifiers[Term.IndustryType.FARM])
				
			# -- For mill productivity..
			tile_pos = get_water_layer().map_to_local(tile)
			for tile_in_range : Vector2i in get_tiles_in_rect(tile_pos, Def.TILE_SIZE * 2):
				if tile_custom_data.has(tile_in_range):
					var industry_modifiers : Dictionary = tile_custom_data[tile_in_range].industry_modifiers
					tile_custom_data[tile].add_terrain_modifier(Term.IndustryType.MILL, industry_modifiers[Term.IndustryType.MILL])

			# -- For mine productivity..
			tile_pos = get_water_layer().map_to_local(tile)
			for tile_in_range : Vector2i in get_tiles_in_rect(tile_pos, Def.TILE_SIZE * 2.5):
				if tile_custom_data.has(tile_in_range):
					var industry_modifiers : Dictionary = tile_custom_data[tile_in_range].industry_modifiers
					tile_custom_data[tile].add_terrain_modifier(Term.IndustryType.MINE, industry_modifiers[Term.IndustryType.MINE])


func get_terrain_modifier_by_industry_type(_tile: Vector2i) -> Dictionary:
	if tile_custom_data.has(_tile):
		return tile_custom_data[_tile].terrain_modifiers
	return {}

"""
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
		var tiles : Array[Vector2i] = get_land_layer().get_surrounding_cells(source)
		for tile : Vector2i in tiles:
			if bonus > 0:
				add_terrain_modifier(tile, resource_type, floor(bonus * 0.5))

	# -- Rivers.. enrich surrounding land tiles
	for river : River in rivers:
		for river_tile : Vector2i in river.tiles:
			for tile : Vector2i in get_land_layer().get_surrounding_cells(river_tile):
				if not tile_custom_data[tile].is_water and not tile_custom_data[tile].is_river_enriched:
					var rng : RandomNumberGenerator = RandomNumberGenerator.new()
					add_terrain_modifier(tile, Term.ResourceType.CROPS, rng.randi_range(0, 5))
					add_terrain_modifier(tile, Term.ResourceType.WOOD, rng.randi_range(0, 5))
					add_terrain_modifier(tile, Term.ResourceType.METAL, rng.randi_range(0, 5))
					tile_custom_data[tile].is_river_enriched = true


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

func get_terrain_modifier_by_industry_type(_tile: Vector2i) -> Dictionary:}
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

func get_source_tiles_by_industry_type(_industry_type: Term.IndustryType) -> Dictionary:
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
"""
#endregion
