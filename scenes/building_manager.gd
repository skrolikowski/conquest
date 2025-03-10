extends Area2D
class_name BuildingManager

@onready var ghost_timer : Timer = $GhostTimer as Timer
@onready var build_shape := $BuildShape as CollisionShape2D

@export var colony : CenterBuilding

var placing_building : Building
var placing_tile     : Vector2i

var build_tiles      : Dictionary
var occupy_tiles     : Array[Vector2i]
	

func _ready() -> void:
	"""
	Defer to allow for colony placement
	"""
	call_deferred("init_building_list")


func _process(_delta: float) -> void:
	if placing_building != null:
		var tile_map : TileMap = Def.get_world().world_map.tile_map
		var map_tile : Vector2i = tile_map.local_to_map(get_global_mouse_position())

		if placing_tile != map_tile:
			_update_temp_building(map_tile)
	

func _draw() -> void:
	if placing_building != null:
		for tile: Vector2 in build_tiles.keys():
			var tile_map  : TileMap = Def.get_world().world_map.tile_map
			var tile_size : Vector2 = tile_map.tile_set.tile_size
			var tile_pos  : Vector2 = global_position - tile_map.map_to_local(tile)
			var tile_rect : Rect2 = Rect2(tile_pos - tile_size * 0.5, tile_size)
			
			draw_rect(tile_rect, Color(Color.WHITE, 0.5), true)


#region BUILDING MANAGEMENT
func get_buildings() -> Array[Node]:
	return $BuildingList.get_children() as Array[Node]


func get_buildings_sorted_by_building_type() -> Array[Node]:
	var buildings : Array[Node] = get_buildings()
	buildings.sort_custom(func(a:Building, b:Building) -> bool: return a.building_type < b.building_type)
	return buildings


func remove_building(_building: Building) -> void:
	_remove_from_occupied_tiles(_building.get_tile(), _building.get_tile_end())
	
	$BuildingList.remove_child(_building)

#endregion


#region BUILDING PLACEMENT
func add_temp_building(_building: Building) -> void:
	placing_building = _building

	Def.get_world().map_set_focus_node(placing_building)
	
	$BuildingList.add_child(_building)
	
	queue_redraw()


func _update_temp_building(_tile: Vector2i) -> void:
	if placing_building == null:
		return

	placing_tile = _tile

	# -- update placing building position..
	var tile_map  : TileMap = Def.get_world().world_map.tile_map
	var map_pos  : Vector2 = tile_map.map_to_local(_tile)
	placing_building.global_position = map_pos
	
	# -- Note: Offset to building placement for large buildings
	#TODO: doesn't fit here..
	if placing_building.building_size == Term.BuildingSize.LARGE:
		placing_building.global_position = map_pos + placing_building.get_size() * 0.25

	# -- verify placement..
	if not _can_place_temp_building():
		placing_building.modulate = Color(1, 0, 0, 0.5)
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
				var is_water_tile : bool = Def.get_world().world_map.is_water_tile(tile)
				if not is_water_tile:
					return false
			else:
				# -- check if height too high..
				var is_land_tile : bool = Def.get_world().world_map.is_land_tile(tile)
				if not is_land_tile:
					return false
	
	return true


func _place_temp_building() -> void:
	if not _can_place_temp_building():
		remove_building(placing_building)
	else:
		_add_to_occupied_tiles(placing_tile, placing_building.get_tile_end())
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


func init_building_list() -> void:
	_add_to_occupied_tiles(colony.get_tile(), colony.get_tile_end())
	_refresh_build_tiles()


func _refresh_build_tiles() -> void:
	"""
	NOTE: Should be called once per building level change
	"""
	# var build_radius   : float = (build_shape.shape as CircleShape2D).radius
	var build_radius   : float = Def.get_building_stat(Term.BuildingType.CENTER, colony.level).build_radius
	var tiles_in_range : Array[Vector2i] = Def.get_world().world_map.get_tiles_in_radius(global_position, build_radius)
	var tile_map       : TileMap = Def.get_world().world_map.tile_map

	build_tiles = {}
	
	for tile : Vector2i in tiles_in_range:
		build_tiles[tile] = tile_map.get_cell_tile_data(0, tile)


func _add_to_occupied_tiles(_start: Vector2i, _end: Vector2i) -> void:
	for x: int in range(_start.x, _end.x + 1):
		for y: int in range(_start.y, _end.y + 1):
			occupy_tiles.append(Vector2i(x, y))


func _remove_from_occupied_tiles(_start: Vector2i, _end: Vector2i) -> void:
	for x: int in range(_start.x, _end.x + 1):
		for y: int in range(_start.y, _end.y + 1):
			occupy_tiles.erase(Vector2i(x, y))








func _unhandled_input(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		var mouse_event : InputEventMouseButton = _event as InputEventMouseButton
		if mouse_event.button_index == 1 and mouse_event.pressed and placing_building != null:
			_place_temp_building()
