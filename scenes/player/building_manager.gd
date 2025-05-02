extends Area2D
class_name BuildingManager

@onready var build_list : Node2D = $BuildingList
@onready var ghost_timer : Timer = $GhostTimer as Timer

@export var colony : CenterBuilding

var placing_building : Building
var placing_tile     : Vector2i

var build_tiles  : Dictionary
var occupy_tiles : Array[Vector2i]
var buildings    : Array[Building] = []
	

func _process(_delta: float) -> void:
	if placing_building != null:
		var tile_map_layer : TileMapLayer = Def.get_world_map().tilemap_layers[WorldGen.MapLayer.LAND]
		var map_tile       : Vector2i = tile_map_layer.local_to_map(get_global_mouse_position())

		if placing_tile != map_tile:
			_update_temp_building(map_tile)
	

func _draw() -> void:
	if placing_building != null:
		for tile: Vector2 in build_tiles.keys():
			var tile_map_layer : TileMapLayer = Def.get_world_map().tilemap_layers[WorldGen.MapLayer.LAND]
			var tile_size      : Vector2 = tile_map_layer.tile_set.tile_size
			var tile_pos       : Vector2 = global_position - tile_map_layer.map_to_local(tile)
			var tile_rect      : Rect2 = Rect2(tile_pos - tile_size * 0.5, tile_size)
			
			draw_rect(tile_rect, Color(Color.WHITE, 0.5), true)


#region BUILDING MANAGEMENT
func get_buildings() -> Array[Building]:
	return buildings


func add_building(_building: Building) -> void:
	buildings.append(_building)
	build_list.add_child(_building)


func get_buildings_sorted_by_building_type() -> Array[Building]:
	var _buildings : Array[Building] = buildings.duplicate()
	_buildings.sort_custom(Def.sort_buildings_by_building_type)
	return _buildings


func remove_building(_building: Building) -> void:
	#TODO: some validation
	remove_occupied_tiles(_building.get_tiles())

	buildings.remove_at(buildings.find(_building))

	build_list.remove_child(_building)
	_building.queue_free()

#endregion


#region BUILDING PLACEMENT
func add_temp_building(_building: Building) -> void:
	placing_building = _building
	_refresh_build_tiles()

	Def.get_world().map_set_focus_node(placing_building)
	
	add_building(_building)
	
	queue_redraw()


func _update_temp_building(_tile: Vector2i) -> void:
	if placing_building == null:
		return

	placing_tile = _tile

	# -- set placing_building position..
	var tile_map_layer : TileMapLayer = Def.get_world_map().get_land_layer()
	var map_pos        : Vector2 = tile_map_layer.map_to_local(_tile)
	placing_building.global_position = map_pos
	
	# -- Note: Offset to building placement for large buildings
	#TODO: doesn't fit here..
	if placing_building.building_size == Term.BuildingSize.LARGE:
		placing_building.global_position = map_pos + placing_building.get_size() * 0.25

	# -- verify placement..
	if not _can_place_temp_building():
		placing_building.modulate = Color(1, 0, 0, 0.75)
	else:
		placing_building.modulate = Color(1, 1, 1, 1)

	# --
	# -- status information..
	Def.get_world().map_set_focus_node(placing_building)


func _can_place_temp_building() -> bool:
	if placing_building == null:
		return false

	# -- check if building can be placed in the tiles..
	var placing_end : Vector2i = placing_building.get_tile_end()

	for x: int in range(placing_tile.x, placing_end.x + 1):
		for y: int in range(placing_tile.y, placing_end.y + 1):
			var tile : Vector2i = Vector2i(x, y)
			
			# Check if tile is buildable..
			if not build_tiles.has(tile):
				return false

			# Check if tile is occupied..
			if occupy_tiles.has(tile):
				return false

			# Height checks..
			if placing_building.is_water_building():
				var is_shore_tile : bool = Def.get_world_map().is_shore_tile(tile)
				if is_shore_tile:
					return true
				
				var is_river_tile : bool = Def.get_world_map().is_river_tile(tile)
				if is_river_tile:
					return true
					
				return false
			else:
				# -- check if height too high..
				var is_land_tile : bool = Def.get_world_map().is_land_tile(tile)
				if not is_land_tile:
					return false
	
	return true


func _place_temp_building() -> void:
	if not _can_place_temp_building():
		remove_building(placing_building)
	else:
		add_occupied_tiles(placing_building.get_tiles())

		# _add_to_occupied_tiles(placing_tile, placing_building.get_tile_end())
		colony.purchase_building(placing_building)

		#TODO: apply `terrain_modifier` if MakeBuilding

		# --
		# Set timer to disallow selection of building until placed
		placing_building.is_selectable = false
		var cb : Callable = func(_b:Building) -> void:
			_b.is_selectable = true

		ghost_timer.wait_time = 0.1
		ghost_timer.connect("timeout", cb.bind(placing_building), CONNECT_ONE_SHOT)
		ghost_timer.start()

		Def.get_world_canvas().refresh_current_ui()

	# -- clear
	placing_building = null
	placing_tile     = Vector2i.ZERO

	# --
	Def.get_world().map_set_focus_node(null)
	
	queue_redraw()

#endregion


func _refresh_build_tiles() -> void:
	"""
	NOTE: Should be called once per building level change
	"""
	var world_map   : WorldGen = Def.get_world_map()
	var build_radius   : float = Def.get_building_stat(Term.BuildingType.CENTER, colony.level).build_radius * Def.TILE_SIZE.x
	var tiles_in_range : Array[Vector2i] = Def.get_world_map().get_tiles_in_radius(global_position, build_radius)
	var tile_map_layer : TileMapLayer = Def.get_world_map().tilemap_layers[WorldGen.MapLayer.LAND]

	build_tiles = {}
	
	for tile : Vector2i in tiles_in_range:
		if world_map.tile_custom_data[tile].is_fog_of_war:
			continue

		build_tiles[tile] = tile_map_layer.get_cell_tile_data(tile)
	# print("Building Tiles: ", build_tiles.size())


func add_occupied_tiles(_tiles: Array[Vector2i]) -> void:
	occupy_tiles.append_array(_tiles)

	# -- TERRAFORM: Remove forest..
	Def.get_world_map().terraform_biome_tiles(_tiles, WorldGen.BiomeTerrain.FOREST, WorldGen.BiomeTerrain.UNFOREST)
	Def.get_world_map().terraform_biome_tiles(_tiles, WorldGen.BiomeTerrain.MOUNTAINS, WorldGen.BiomeTerrain.UNMOUNTAIN)


func remove_occupied_tiles(_tiles: Array[Vector2i]) -> void:
	for tile: Vector2i in _tiles:
		occupy_tiles.erase(tile)

	# -- TERRAFORM: Restore forest..
	Def.get_world_map().terraform_biome_tiles(occupy_tiles, WorldGen.BiomeTerrain.UNFOREST, WorldGen.BiomeTerrain.FOREST)
	Def.get_world_map().terraform_biome_tiles(occupy_tiles, WorldGen.BiomeTerrain.UNMOUNTAIN, WorldGen.BiomeTerrain.MOUNTAINS)


func refresh_occupied_tiles() -> void:
	occupy_tiles = colony.get_tiles()

	for building: Building in get_buildings():
		occupy_tiles.append_array(building.get_tiles())

	# -- TERRAFORM: Remove forest..
	Def.get_world_map().terraform_biome_tiles(occupy_tiles, WorldGen.BiomeTerrain.FOREST, WorldGen.BiomeTerrain.UNFOREST)
	Def.get_world_map().terraform_biome_tiles(occupy_tiles, WorldGen.BiomeTerrain.MOUNTAINS, WorldGen.BiomeTerrain.UNMOUNTAIN)


func _unhandled_input(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		var mouse_event : InputEventMouseButton = _event as InputEventMouseButton
		if mouse_event.button_index == 1 and mouse_event.pressed and placing_building != null:
			_place_temp_building()



#region GAME PERSISTENCE
func on_save_data() -> Dictionary:

	# -- Package buildings..
	var building_data : Array[Dictionary] = []
	for building: Building in get_buildings():
		building_data.append(building.on_save_data())
	
	return {
		"buildings" : building_data,
	}


func on_load_data(_data: Dictionary) -> void:

	# -- Load buildings..
	for building_data: Dictionary in _data["buildings"]:
		var building_scene : PackedScene = Def.get_building_scene_by_type(building_data.building_type)
		var building       : Building = building_scene.instantiate() as Building
		add_building(building)
		
		building.on_load_data(building_data)
		building.colony = colony
		building.player = colony.player

		# _add_to_occupied_tiles(building.get_tile(), building.get_tile_end())

#endregion
