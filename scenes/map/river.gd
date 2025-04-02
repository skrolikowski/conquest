extends RefCounted
class_name River

var tiles : Array[Vector2i] = []
var map   : WorldGen
var access_to_sea : bool


static func create(_tiles: Array[Vector2i], _access_to_sea:bool = false) -> River:
    var river : River = River.new()
    river.tiles = _tiles
    river.access_to_sea = _access_to_sea

    return river