extends RefCounted
class_name River

var map   : WorldGen
var tiles : Array[Vector2i] = []


static func create(_map: WorldGen, _tiles: Array[Vector2i]) -> River:
	var river : River = River.new()
	river.map = _map
	river.tiles = _tiles
	
	# --
	for tile: Vector2i in _tiles:
		_map.tile_custom_data[tile].is_river = true

	return river
