extends Node2D
class_name ColonyManager


@onready var colony_list : Node = $ColonyList

@export var player : Player

var settler_position : Vector2
var settler_stats	 : UnitStats

var placing_colony   : CenterBuilding
var placing_tile     : Vector2i
var placing_tiles    : Dictionary

var colonies : Array[CenterBuilding] = []


func _draw() -> void:
	if placing_colony != null:
		for tile: Vector2i in placing_tiles:
			var tile_data : Dictionary = placing_tiles[tile]
			draw_rect(tile_data.rect, tile_data.color, true)


#region COLONY MANAGEMENT
func get_colonies() -> Array[CenterBuilding]:
	return colonies


func add_colony(_building: CenterBuilding) -> void:
	colonies.append(_building)
	colony_list.add_child(_building)


func remove_colony(_colony: CenterBuilding) -> void:
	var colony_index : int = colonies.find(_colony)
	if colony_index == -1:
		print("[ERROR] Attempted to remove colony not in colonies array: ", _colony)
		return

	# -- Removes any buildings owned by this colony..
	for building: Building in _colony.bm.get_buildings().duplicate():
		_colony.bm.remove_building(building)

	# -- Clear references to prevent dangling pointers..
	if placing_colony == _colony:
		placing_colony = null
		placing_tiles = {}
		settler_stats = null
		settler_position = Vector2.ZERO

	colonies.remove_at(colony_index)
	colony_list.remove_child(_colony)
	_colony.queue_free()


func create_colony() -> void:
	placing_colony.player   = player
	placing_colony.modulate = Color(1, 1, 1, 1.0)
	
	# -- Set initial resources..
	var unit_stat  : Dictionary = GameData.get_unit_stat(Term.UnitType.SETTLER, settler_stats.level)
	placing_colony.set_init_resources(unit_stat.resources)
	placing_colony.refresh_bank()
	
	_refresh_placing_tiles(Vector2i.ZERO)
	
	WorldService.get_world_canvas().close_all_ui()
	# WorldService.get_world().map_set_focus_node(null)


func undo_create_colony(_building: CenterBuilding) -> void:
	if _building.building_state == Term.BuildingState.NEW:

		# -- Create settler..
		var settler  : UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, settler_stats.level)
		settler.on_load_data(settler_stats.on_save_data())
		var settler_pos : Vector2 = _building.global_position - Vector2(Preload.C.TILE_SIZE.x * 0.25, Preload.C.TILE_SIZE.y * 0.25)
		var settler_unit : Unit = player.create_unit(settler, settler_pos)
		if settler_unit == null:
			print("[ERROR] Failed to create settler unit during undo_create_colony")
			return

		# -- Remove occupied tiles..
		_building.bm.remove_occupied_tiles(_building.get_tiles())

		# -- Remove colony..
		remove_colony(_building)

		WorldService.get_world_canvas().close_all_ui()

#endregion


#region COLONY PLACEMENT
func can_settle(_tile : Vector2i) -> bool:
	#TODO: assumes colony size is 2x2
	var tile_end : Vector2i = _tile + Vector2i(1, 1)

	for x: int in range(_tile.x, tile_end.x + 1):
		for y: int in range(_tile.y, tile_end.y + 1):
			var tile : Vector2i = Vector2i(x, y)

			var is_land_tile : bool = Def.get_world_map().is_land_tile(tile)
			if not is_land_tile:
				return false

	return true


func found_colony(_tile: Vector2i, _position: Vector2, _stats: UnitStats) -> void:
	var building_scene : PackedScene = PreloadsRef.get_building_scene(Term.BuildingType.CENTER)
	var building       : CenterBuilding = building_scene.instantiate() as CenterBuilding
	placing_colony = building

	var world_pos : Vector2 = Def.get_world_tile_map().map_to_local(_tile)
	placing_colony.global_position = world_pos + Vector2(Preload.C.TILE_SIZE.x * 0.5, Preload.C.TILE_SIZE.y * 0.5)
	placing_colony.player   = player
	placing_colony.modulate = Color(1, 1, 1, 0.75)

	add_colony(placing_colony)

	# -- update occupied tiles..
	placing_colony.bm.add_occupied_tiles(placing_colony.get_tiles())
	
	# -- save for undoing..
	settler_position = _position
	settler_stats    = _stats

	_refresh_placing_tiles(_tile)

	WorldService.get_world_canvas().open_found_colony_menu(self)
	# Def.get_world_selector().clear_selection()
	Def.get_world().focus_service.set_focus_node(placing_colony)


func cancel_found_colony() -> void:
	placing_colony.bm.remove_occupied_tiles(placing_colony.get_tiles())

	remove_colony(placing_colony)

	# -- create settler..
	var settler  : UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, settler_stats.level)
	settler.on_load_data(settler_stats.on_save_data())
	var settler_unit : Unit = player.create_unit(settler, settler_position)
	if settler_unit == null:
		print("[ERROR] Failed to create settler unit during cancel_found_colony")
		# Continue cleanup even if settler creation fails

	_refresh_placing_tiles(Vector2i.ZERO)

	WorldService.get_world_canvas().close_all_ui()
	# Def.get_world().map_set_focus_node(null)


func _refresh_placing_tiles(_tile: Vector2i) -> void:
	var world_map : WorldGen = Def.get_world_map()
	var tile_size : Vector2i = Preload.C.TILE_SIZE
	
	placing_tile   = _tile
	placing_tiles  = {}

	if placing_tile != Vector2i.ZERO:
		var build_radius_1 : float = GameData.get_building_stat(Term.BuildingType.CENTER, 1).build_radius * tile_size.x
		var build_radius_2 : float = GameData.get_building_stat(Term.BuildingType.CENTER, 2).build_radius * tile_size.x
		var build_radius_3 : float = GameData.get_building_stat(Term.BuildingType.CENTER, 3).build_radius * tile_size.x
		var build_radius_4 : float = GameData.get_building_stat(Term.BuildingType.CENTER, 4).build_radius * tile_size.x
	
		var bounds : Array[Dictionary] = [
			{ "tiles" : Def.get_world_map().get_tiles_in_radius(placing_colony.global_position, build_radius_1), "color" : Color(Color.WHITE, 0.25) },
			{ "tiles" : Def.get_world_map().get_tiles_in_radius(placing_colony.global_position, build_radius_2), "color" : Color(Color.BLUE, 0.10) },
			{ "tiles" : Def.get_world_map().get_tiles_in_radius(placing_colony.global_position, build_radius_3), "color" : Color(Color.WHITE, 0.25) },
			{ "tiles" : Def.get_world_map().get_tiles_in_radius(placing_colony.global_position, build_radius_4), "color" : Color(Color.BLUE, 0.10) }
		]
		
		for bound: Dictionary in bounds:
			for tile: Vector2i in bound.tiles:
				if not tile in placing_tiles:
					var tile_pos  : Vector2 = world_map.get_map_to_local_position(tile)
					var tile_tl   : Vector2 = tile_pos - tile_size * 0.5
					var tile_rect : Rect2 = Rect2(tile_tl, tile_size)
					
					placing_tiles[tile] = { "rect": tile_rect, "color": bound.color }
	
	# --
	queue_redraw()

#endregion


#region GAME PERSISTENCE
func on_save_data() -> Dictionary:

	# -- Package colonies..
	var colony_data : Array[Dictionary] = []
	for colony: CenterBuilding in get_colonies():
		colony_data.append(colony.on_save_data())

	# -- Package settler data (only if active colony placement)..
	var settler_data : Dictionary = {}
	if settler_stats != null:
		settler_data = settler_stats.on_save_data()

	return {
		"colonies"         : colony_data,
		"settler_position" : settler_position,
		"settler_stats"    : settler_data,
	}


func on_load_data(_data: Dictionary) -> void:

	# -- Load settler data (if applicable)..
	settler_position = _data["settler_position"]
	if not _data["settler_stats"].is_empty():
		settler_stats = UnitStats.New_Unit(_data["settler_stats"].unit_type, _data["settler_stats"].level)
		settler_stats.on_load_data(_data["settler_stats"])
	else:
		settler_stats = null

	# -- Load colonies..
	for colony_data: Dictionary in _data["colonies"]:
		var building_scene : PackedScene = PreloadsRef.get_building_scene(Term.BuildingType.CENTER)
		var colony         : CenterBuilding = building_scene.instantiate() as CenterBuilding
		add_colony(colony)
		
		colony.on_load_data(colony_data)
		colony.player = player

		#TODO: update biome tilemap layer (remove trees)
		#var start_tile : Vector2i = colony.get_tile()
		#var end_tile   : Vector2i = colony.get_tile_end()
		#Def.get_world_map().clear_biome_tilemap_layer_area(start_tile, end_tile)

	# --
	for colony: CenterBuilding in get_colonies():
		colony.bm.refresh_occupied_tiles()

#endregion
