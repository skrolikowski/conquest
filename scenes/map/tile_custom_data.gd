extends RefCounted
class_name TileCustomData


# -- Water
var is_water : bool = false
var is_ocean : bool = false
var is_shore : bool = false

# -- River
var is_river : bool = false
var has_ocean_access  : bool = false
var is_river_enriched : bool = false


#region GAME PERSISTENCE
func on_save_data() -> Dictionary:
	return {
		"is_water" : is_water,
		"is_ocean" : is_ocean,
		"is_shore" : is_shore,
		"is_river" : is_river,
		"has_ocean_access" : has_ocean_access,
		"is_river_enriched" : is_river_enriched,
	}


func on_load_data(_data: Dictionary) -> void:
	is_water          = _data["is_water"]
	is_ocean          = _data["is_ocean"]
	is_shore          = _data["is_shore"]
	is_river          = _data["is_river"]
	has_ocean_access  = _data["has_ocean_access"]
	is_river_enriched = _data["is_river_enriched"]

#endregion
