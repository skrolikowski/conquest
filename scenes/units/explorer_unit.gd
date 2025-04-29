extends Unit
class_name ExplorerUnit

const EXPLORE_TILE_RADIUS : int = 4

var explore_start  : Vector2i
var explore_finish : Vector2i
var is_exploring   : bool : set = _set_is_exploring


func _ready() -> void:
	super._ready()

	stat.title     = "Explorer"
	stat.unit_type = Term.UnitType.EXPLORER


func _on_target_reached() -> void:
	if is_exploring:
		print("[EXPLORE] Target Reached!", get_tile())
		set_exploration_target()


func _on_waypoint_reached(_details: Dictionary) -> void:
	super._on_waypoint_reached(_details)

	var current_tile : Vector2i = get_tile()
	if current_tile != explore_start and current_tile != explore_finish:
		print("[EXPLORE] Waypoint Reached!", get_tile())
		set_exploration_target()


func _set_is_exploring(_exploring: bool) -> void:
	is_exploring = _exploring
	
	if is_exploring:
		stat.unit_state = Term.UnitState.EXPLORE
		set_exploration_target()
	else:
		stat.unit_state = Term.UnitState.IDLE
		is_moving = false

	#TODO: mark as exploring (e.g. desire to uncover "fog of war")
	#TODO: w/ persistent behavior, unit will explore on begin turn


func get_fog_tiles_in_range(_range:float) -> Array[Vector2i]:
	var world_map : WorldGen = Def.get_world_map()
	var fog_tiles : Array[Vector2i] = world_map.get_tiles_in_radius(global_position, _range)

	# -- filter out discovered tiles..
	var land_fog_tiles  : Array[Vector2i] = []
	for tile : Vector2i in fog_tiles:
		var is_fow   : bool = world_map.tile_custom_data[tile].is_fog_of_war
		var is_water : bool = world_map.tile_custom_data[tile].is_water
		if is_fow and not is_water:
			land_fog_tiles.append(tile)

	return land_fog_tiles


func set_exploration_target() -> void:
	var land_layer    : TileMapLayer = Def.get_world_map().get_land_layer()
	var explore_range : float = Def.TILE_SIZE.x * EXPLORE_TILE_RADIUS
	var fog_tiles     : Array[Vector2i] = get_fog_tiles_in_range(explore_range)

	# Prioritize mountain and river tiles
	fog_tiles.sort_custom(_compare_tiles_by_distance)

	if fog_tiles.size() > 0:
		print("[EXPLORE] New Target", fog_tiles[0], "out of", str(fog_tiles.size()))
		"""
			Dev-note:
			This is necessary to trick navagent2d target update
		"""
		var new_target : Vector2 = land_layer.map_to_local(fog_tiles[0])
		call_deferred("set_new_exploration_target", new_target)
		is_moving = true
	else:
		print("[EXPLORE] Stopped exploring!")
		#nav_agent.target_position = global_position
		is_moving = false


func set_new_exploration_target(_new_target: Vector2)->void:
	var land_layer : TileMapLayer = Def.get_world_map().get_land_layer()
	explore_start  = land_layer.local_to_map(global_position)
	explore_finish = land_layer.local_to_map(_new_target)
	
	nav_agent.target_position = _new_target
	is_moving = true


func _compare_tiles_by_priority(_a: Vector2i, _b: Vector2i) -> int:
	var world_map  : WorldGen = Def.get_world_map()
	var priority_a : int = _get_tile_priority(world_map.get_tile_custom_data(_a))
	var priority_b : int = _get_tile_priority(world_map.get_tile_custom_data(_b))
	return priority_b - priority_a


func _compare_tiles_by_distance(_a: Vector2i, _b: Vector2i) -> bool:
	return global_position.distance_squared_to(_a) < global_position.distance_squared_to(_b)


func _get_tile_priority(tile_data: TileCustomData) -> int:
	if tile_data.biome == WorldGen.TileCategory.RIVER:
		return 3
	elif tile_data.biome == WorldGen.TileCategory.MOUNTAIN:
		return 2
	else:
		return 1


func on_selected() -> void:
	super.on_selected()
	is_exploring = false
