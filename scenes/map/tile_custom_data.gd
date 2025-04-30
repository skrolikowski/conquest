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
var movement_modifiers : Dictionary = {
	Term.UnitMovement.EXPLORER : 0,
	Term.UnitMovement.SHIP     : 0,
	Term.UnitMovement.OTHER    : 0
}

# -- Fog of War
var is_fog_of_war : bool = true

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

		movement_modifiers[Term.UnitMovement.EXPLORER] = 0
		movement_modifiers[Term.UnitMovement.SHIP]     = 30
		movement_modifiers[Term.UnitMovement.OTHER]    = 0
	elif biome == WorldGen.TileCategory.RIVER:
		industry_modifiers[Term.IndustryType.FARM] = 20
		industry_modifiers[Term.IndustryType.MINE] = 8
		industry_modifiers[Term.IndustryType.MILL] = 8

		movement_modifiers[Term.UnitMovement.EXPLORER] = 20
		movement_modifiers[Term.UnitMovement.SHIP]     = 0
		movement_modifiers[Term.UnitMovement.OTHER]    = 10
	elif biome == WorldGen.TileCategory.GRASS:
		industry_modifiers[Term.IndustryType.FARM] = 4
		industry_modifiers[Term.IndustryType.MINE] = 0
		industry_modifiers[Term.IndustryType.MILL] = -1

		movement_modifiers[Term.UnitMovement.EXPLORER] = 30
		movement_modifiers[Term.UnitMovement.SHIP]     = 0
		movement_modifiers[Term.UnitMovement.OTHER]    = 20
	elif biome == WorldGen.TileCategory.SWAMP:
		industry_modifiers[Term.IndustryType.FARM] = 4
		industry_modifiers[Term.IndustryType.MINE] = 0
		industry_modifiers[Term.IndustryType.MILL] = 2

		movement_modifiers[Term.UnitMovement.EXPLORER] = 25
		movement_modifiers[Term.UnitMovement.SHIP]     = 0
		movement_modifiers[Term.UnitMovement.OTHER]    = 15
	elif biome == WorldGen.TileCategory.FOREST:
		industry_modifiers[Term.IndustryType.FARM] = -2
		industry_modifiers[Term.IndustryType.MINE] = 0
		industry_modifiers[Term.IndustryType.MILL] = 4

		movement_modifiers[Term.UnitMovement.EXPLORER] = 22
		movement_modifiers[Term.UnitMovement.SHIP]     = 0
		movement_modifiers[Term.UnitMovement.OTHER]    = 17
	elif biome == WorldGen.TileCategory.MOUNTAIN:
		industry_modifiers[Term.IndustryType.FARM] = 0
		industry_modifiers[Term.IndustryType.MINE] = 8
		industry_modifiers[Term.IndustryType.MILL] = 2

		movement_modifiers[Term.UnitMovement.EXPLORER] = 18
		movement_modifiers[Term.UnitMovement.SHIP]     = 0
		movement_modifiers[Term.UnitMovement.OTHER]    = 12


func add_terrain_modifier(_industry_type: Term.ResourceType, _value: int) -> void:
	terrain_modifiers[_industry_type] += _value


func get_terrain_modifier(_industry_type: Term.ResourceType) -> int:
	return terrain_modifiers[_industry_type]


func get_movement_modifier_by_unit_type(_unit_type:Term.UnitType) -> int:
	if _unit_type == Term.UnitType.SHIP:
		return movement_modifiers[Term.UnitMovement.SHIP]
	elif _unit_type == Term.UnitType.EXPLORER:
		return movement_modifiers[Term.UnitMovement.EXPLORER]
	else:
		return movement_modifiers[Term.UnitMovement.OTHER]


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
