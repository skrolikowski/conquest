extends Unit
class_name CarrierUnit


#region CARRIER ACTIONS
func detach_all_units() -> void:
	for unit_stat : UnitStats in stat.attached_units:
		detach_unit(unit_stat)
		
	stat.attached_units.clear()


func get_detach_tile() -> Vector2i:
	var tilemap_layer : TileMapLayer = Def.get_world_map().get_land_layer()
	var map_position   : Vector2i = tilemap_layer.local_to_map(global_position)
	var neighbors      : Array[Vector2i] = tilemap_layer.get_surrounding_cells(map_position)
	var detach_tiles   : Array[Vector2i] = []

	for neighbor : Vector2i in neighbors:
		if Def.get_world_map().is_land_tile(neighbor):
			detach_tiles.append(neighbor)

	if detach_tiles.size() > 0:
		return detach_tiles[randi() % detach_tiles.size()]
	else:
		return Vector2i.ZERO


func can_detach_unit() -> bool:
	# return get_detach_tile() != Vector2i.ZERO
	return Def.get_world_map().is_shore_tile(get_tile())


func detach_unit(_unit_stat: UnitStats) -> void:
	_detach_unit(_unit_stat)
	stat.attached_units.erase(_unit_stat)


func _detach_unit(_unit_stat: UnitStats) -> void:
	var tile_map   : TileMapLayer = Def.get_world_map().tilemap_layers[WorldGen.MapLayer.LAND]
	var unit_scene : PackedScene = Def.get_unit_scene_by_type(_unit_stat.unit_type)
	var unit       : Unit = unit_scene.instantiate() as Unit
	
	unit.stat        = _unit_stat
	unit.stat.player = stat.player
	unit.position    = tile_map.map_to_local(get_detach_tile())

	# -- Add reference to Player..
	stat.player.add_unit(unit)

	# -- Remove Unit/Leader reference..
	#WARNING: this should work.. untested
	if _unit_stat.leader:
		_unit_stat.leader.attached_units.erase(_unit_stat)
		_unit_stat.leader = null

#endregion
