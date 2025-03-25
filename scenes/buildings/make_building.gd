extends Building
class_name MakeBuilding

# @export_range(0, 1.5, 0.01) var terrain_modifier  : float = 0.0
# @export_range(0, 0.5, 0.01) var artifact_modifier : float = 0.0

var make_industry_type : Term.IndustryType
var make_resource_type : Term.ResourceType


func get_expected_produce_value() -> int:
	var make  : Transaction = get_make()
	var value : int = make.resources[make_resource_type]
	var mod   : float = get_total_production_modifier()
	
	# -- Modifier..
	if mod > 0.0:
		# increase original make by modifier..
		value += ceil(value * mod)
		
	return value


func get_actual_produce_value() -> int:
	var value : int = get_expected_produce_value()
	
	if colony:
		# reduce make if labor shortage
		if colony.has_labor_shortage():
			value = ceil(value * 0.5)

	return value


func get_consumption_need_value_by_resource_type(_resource_type:Term.ResourceType) -> int:
	var need  : Transaction = get_need()
	var value : int = need.resources[_resource_type]
	
	return value


func get_specialization_points() -> float:
	if building_size == Term.BuildingSize.LARGE:
		return level * 4
	elif building_size == Term.BuildingSize.SMALL:
		return level * 1

	return 0.0


func get_specialized_industry_modifier() -> float:
	# #TODO: cache this expensive operation (per turn)
	var bonus:Dictionary = colony.calculate_specialization_bonus()
	if bonus["industry"] == make_industry_type:
		if bonus["value"] > 0:
			return bonus["value"] * 0.01
	return 0.0


func get_terrain_modifier() -> float:
	var source_tile      : Vector2i = get_tile()
	var terrain_modifier : int = Def.get_world_map().get_terrain_modifier_value(source_tile, make_resource_type)
	return terrain_modifier * 0.01


func get_artifact_modifier() -> float:
	#TODO: get artifact modifier
	return 0.0


func get_total_production_modifier() -> float:
	return get_terrain_modifier() + get_artifact_modifier() + get_specialized_industry_modifier()


#region STATUS INFORMATION
# func get_status_information_production(_tile: Vector2i) -> String:
# 	var world_map    : WorldMap = Def.get_world().world_map
# 	var terrain_mods : Dictionary = world_map.get_terrain_modifier_by_industry_type(_tile)
# 	#var artifact_mods : Transaction = world_map.get_artifact_modifier(_tile)
# 	var text : String = ""

# 	if building_size == Term.BuildingSize.LARGE:
# 		#TODO: get average of all tiles
# 		pass
	
# 	# -- Industry production..
# 	text += "Industry: +" + str(terrain_mods[make_industry_type]) + "%"

# 	if make_industry_type == Term.IndustryType.MINE:
# 		text += " (Farm: " + str(terrain_mods[Term.IndustryType.FARM]) + ")"
# 		text += " (Mill: " + str(terrain_mods[Term.IndustryType.MILL]) + ")"
# 	elif make_industry_type == Term.IndustryType.MILL:
# 		text += " (Farm: " + str(terrain_mods[Term.IndustryType.FARM]) + ")"
# 		text += " (Mine: " + str(terrain_mods[Term.IndustryType.MINE]) + ")"
# 	elif make_industry_type == Term.IndustryType.FARM:
# 		text += " (Mill: " + str(terrain_mods[Term.IndustryType.MILL]) + ")"
# 		text += " (Mine: " + str(terrain_mods[Term.IndustryType.MINE]) + ")"

# 	return text

#endregion
