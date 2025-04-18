extends Unit
class_name ExplorerUnit

var is_exploring : bool : set = _set_is_exploring

func _ready() -> void:
	super._ready()
	
	stat.title     = "Explorer"
	stat.unit_type = Term.UnitType.EXPLORER


func _set_is_exploring(_exploring: bool) -> void:
	is_exploring = _exploring
	
	if is_exploring:
		stat.unit_state = Term.UnitState.EXPLORE
	else:
		stat.unit_state = Term.UnitState.IDLE

	#TODO: mark as exploring (e.g. desire to uncover "fog of war")
	#TODO: w/ persistent behavior, unit will explore on begin turn


func set_exploration_target() -> void:
	var world_map : WorldGen = Def.get_world_map()
	var fog_tiles : Array[Vector2i] = world_map.get_tiles_in_radius(global_position, 48*4, WorldGen.MapLayer.FOGOFWAR)

	# Prioritize mountain and river tiles
	fog_tiles.sort_custom(_compare_tiles_by_priority)

	if fog_tiles.size() > 0:
		nav_agent.target_position = world_map.map_to_local(fog_tiles[0])
		is_moving = true
	else:
		nav_agent.target_position = global_position
		is_moving = false

func _compare_tiles_by_priority(_a: Vector2i, _b: Vector2i) -> int:
	var world_map  : WorldGen = Def.get_world_map()
	var priority_a : int = _get_tile_priority(world_map.get_tile_custom_data(_a))
	var priority_b : int = _get_tile_priority(world_map.get_tile_custom_data(_b))
	return priority_b - priority_a

func _get_tile_priority(tile_data: TileCustomData) -> int:
	if tile_data.biome == WorldGen.TileCategory.RIVER:
		return 3
	elif tile_data.biome == WorldGen.TileCategory.MOUNTAIN:
		return 2
	else:
		return 1
