extends Node2D
class_name ExploreManager

var hi_tile_radius : int = 4
var lo_tile_radius : int = 2
var start_tile  : Vector2i
var target_tile : Vector2i

var unit : Unit : set = _set_unit
var is_exploring : bool : set = _set_is_exploring


func _set_unit(_unit:Unit) -> void:
	unit = _unit
	unit.nav_agent.connect("target_reached", _on_target_reached)
	unit.nav_agent.connect("waypoint_reached", _on_waypoint_reached)


func _set_is_exploring(_exploring: bool) -> void:
	is_exploring = _exploring
	
	if is_exploring:
		_set_new_exploration_target()
	else:
		unit.is_moving = false

	#TODO: mark as exploring (e.g. desire to uncover "fog of war")
	#TODO: w/ persistent behavior, unit will explore on begin turn


func _on_target_reached() -> void:
	if unit.is_exploring:
		print("[EXPLORE] Target Reached!", unit.get_tile())
		_set_new_exploration_target()


func _on_waypoint_reached(_details: Dictionary) -> void:
	var unit_tile : Vector2i = unit.get_tile()
	if unit_tile != start_tile and unit_tile != target_tile:
		print("[EXPLORE] Waypoint Reached!", unit_tile)
		_set_new_exploration_target()


func _set_new_exploration_target(_range:int = lo_tile_radius) -> void:
	var world_map : WorldGen = Def.get_world_map()
	var fog_tiles : Array[Vector2i] = _get_fog_tiles_in_range(_range)

	if fog_tiles.size() > 0:
		print("[EXPLORE] New Target: ", fog_tiles[0], " out of ", str(fog_tiles.size()))
		"""
			Dev-note:
			This is necessary to trick navagent2d target update
		"""
		var new_target : Vector2 = world_map.get_map_to_local_position(fog_tiles[0])
		call_deferred("_set_new_nav_target", new_target)
	elif _range == lo_tile_radius:
		# -- If no fog tiles are found, try again with a larger radius
		_set_new_exploration_target(hi_tile_radius)
	else:
		print("[EXPLORE] Stopped exploring!")
		unit.is_moving = false


func _set_new_nav_target(_new_target: Vector2)->void:
	var world_map : WorldGen = Def.get_world_map()
	start_tile  = world_map.get_local_to_map_position(global_position)
	target_tile = world_map.get_local_to_map_position(_new_target)
	
	unit.nav_agent.target_position = _new_target
	unit.is_moving = true


func _get_fog_tiles_in_range(_range: int) -> Array[Vector2i]:
	var world_map   : WorldGen = Def.get_world_map()
	var center_tile : Vector2i = unit.get_tile()
	var map_tiles   : Array[Vector2i]
	var fog_tiles   : Array[Vector2i] = []

	# --
	if unit is ShipUnit:
		map_tiles = world_map.get_water_tiles()
	else:
		map_tiles = world_map.get_land_tiles()

	# -- Gather and filter fog tiles..
	for tile: Vector2i in map_tiles:
		var dist_sqr : float = tile.distance_squared_to(center_tile)
		var is_fow   : bool = world_map.tile_custom_data[tile].is_fog_of_war
		var is_water : bool = world_map.tile_custom_data[tile].is_water
		var is_valid : bool

		if unit is ShipUnit:
			is_valid = is_fow and is_water
		else:
			is_valid = is_fow and not is_water

		if is_valid and dist_sqr <= _range * _range:
			fog_tiles.append(tile)

	# -- Prioritize tiles..
	if unit is ShipUnit:
		fog_tiles.sort_custom(_compare_tiles_by_priority)
	else:
		fog_tiles.sort_custom(_compare_tiles_by_priority_and_distance)
	
	return fog_tiles


func _compare_tiles_by_priority(_a: Vector2i, _b: Vector2i) -> bool:
	var world_map   : WorldGen = Def.get_world_map()
	var priority_a : float = _get_tile_priority(world_map.get_tile_custom_data(_a))
	var priority_b : float = _get_tile_priority(world_map.get_tile_custom_data(_b))
	return priority_a > priority_b


func _compare_tiles_by_priority_and_distance(_a: Vector2i, _b: Vector2i) -> bool:
	var world_map   : WorldGen = Def.get_world_map()
	var center_tile : Vector2i = unit.get_tile()

	# Get priorities
	var priority_a : float = _get_tile_priority(world_map.get_tile_custom_data(_a))
	var priority_b : float = _get_tile_priority(world_map.get_tile_custom_data(_b))

	# Get distances (closer tiles are better, so invert the distance for sorting)
	var distance_a : float = _a.distance_to(center_tile)
	var distance_b : float = _b.distance_to(center_tile)

	# Calculate scores
	var score_a : float = priority_a / (distance_a*0.2)
	var score_b : float = priority_b / (distance_b*0.2)

	# Sort by score (higher score comes first)
	return score_a > score_b


func _get_tile_priority(tile_data: TileCustomData) -> float:
	if unit is ShipUnit:
		if tile_data.is_shore:
			return 3.0
		else:
			return 1.0
	else:
		if tile_data.biome == WorldGen.TileCategory.RIVER:
			return 3.0
		elif tile_data.biome == WorldGen.TileCategory.MOUNTAIN:
			return 2.0
		else:
			return 1.0
