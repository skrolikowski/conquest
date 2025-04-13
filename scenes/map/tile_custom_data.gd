extends RefCounted
class_name TileCustomData

# -- Terrain Modifier..
var biome : WorldGen.TileCategory : set = _set_biome
var industry_modifiers : Dictionary = {}
var terrain_modifiers  : Dictionary = {
	Term.IndustryType.FARM : 0,
	Term.IndustryType.MINE : 0,
	Term.IndustryType.MILL : 0
}

# -- Water
var is_water : bool = false
var is_ocean : bool = false
var is_shore : bool = false

# -- River
var is_river : bool = false
var has_ocean_access  : bool = false
var is_river_enriched : bool = false


func _set_biome(_biome: WorldGen.TileCategory) -> void:
	biome = _biome

	# -- Set industry modifiers..
	if biome == WorldGen.TileCategory.OCEAN:
		industry_modifiers[Term.IndustryType.FARM] = 6
		industry_modifiers[Term.IndustryType.MINE] = 0
		industry_modifiers[Term.IndustryType.MILL] = 0
	elif biome == WorldGen.TileCategory.RIVER:
		industry_modifiers[Term.IndustryType.FARM] = 8
		industry_modifiers[Term.IndustryType.MINE] = 9
		industry_modifiers[Term.IndustryType.MILL] = 9
	elif biome == WorldGen.TileCategory.GRASS:
		industry_modifiers[Term.IndustryType.FARM] = 4
		industry_modifiers[Term.IndustryType.MINE] = 0
		industry_modifiers[Term.IndustryType.MILL] = -1
	elif biome == WorldGen.TileCategory.SWAMP:
		industry_modifiers[Term.IndustryType.FARM] = 4
		industry_modifiers[Term.IndustryType.MINE] = 0
		industry_modifiers[Term.IndustryType.MILL] = 2
	elif biome == WorldGen.TileCategory.FOREST:
		industry_modifiers[Term.IndustryType.FARM] = -2
		industry_modifiers[Term.IndustryType.MINE] = 0
		industry_modifiers[Term.IndustryType.MILL] = 4
	elif biome == WorldGen.TileCategory.MOUNTAIN:
		industry_modifiers[Term.IndustryType.FARM] = 0
		industry_modifiers[Term.IndustryType.MINE] = 3
		industry_modifiers[Term.IndustryType.MILL] = 3


func add_terrain_modifier(_industry_type: Term.ResourceType, _value: int) -> void:
	terrain_modifiers[_industry_type] += _value


func get_terrain_modifier(_industry_type: Term.ResourceType) -> int:
	return terrain_modifiers[_industry_type]


#region GAME PERSISTENCE
func on_save_data() -> Dictionary:
	return {
		"biome"             : biome,
		"is_water"          : is_water,
		"is_ocean"          : is_ocean,
		"is_shore"          : is_shore,
		"is_river"          : is_river,
		"has_ocean_access"  : has_ocean_access,
		"is_river_enriched" : is_river_enriched,
	}


func on_load_data(_data: Dictionary) -> void:
	biome             = _data["biome"]
	is_water          = _data["is_water"]
	is_ocean          = _data["is_ocean"]
	is_shore          = _data["is_shore"]
	is_river          = _data["is_river"]
	has_ocean_access  = _data["has_ocean_access"]
	is_river_enriched = _data["is_river_enriched"]

#endregion
