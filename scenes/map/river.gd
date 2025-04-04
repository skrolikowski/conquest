extends RefCounted
class_name River

var tiles : Array[Vector2i] = []


static func create(_map: WorldGen, _tiles: Array[Vector2i]) -> River:
	var river : River = River.new()
	river.tiles = _tiles
	
	# --
	for tile: Vector2i in _tiles:
		_map.tile_custom_data[tile].is_river = true

	return river


#region GAME PERSISTENCE
func on_save_data() -> Dictionary:
	return {
		"tiles" : tiles,
	}


func on_load_data(_data: Dictionary) -> void:
	tiles = _data["tiles"]

#endregion
