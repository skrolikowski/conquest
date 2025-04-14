extends RefCounted
class_name MountainRange

var tiles : Array[Vector2i] = []


static func create(_map: WorldGen, _tiles: Array[Vector2i]) -> MountainRange:
	var obj : MountainRange = MountainRange.new()

	var range_tiles : Array[Vector2i] = []
	for tile: Vector2i in _tiles:
		range_tiles.append(tile)
		
		var m_tiles : Array[Vector2i] = _map.get_land_layer().get_surrounding_cells(tile)
		for m_tile : Vector2i in m_tiles:
			if not range_tiles.has(m_tile):
				range_tiles.append(m_tile)

	obj.tiles = range_tiles

	return obj


#region GAME PERSISTENCE
func on_save_data() -> Dictionary:
	return {
		"tiles" : tiles,
	}


func on_load_data(_data: Dictionary) -> void:
	tiles = _data["tiles"]

#endregion
