extends Node2D
class_name DefinitionsRef

# REFACTOR PHASE 1: Import new utility classes
const TypeRegistry = preload("res://scripts/type_registry.gd")
const GameRules = preload("res://scripts/game_rules.gd")
const C = preload("res://scripts/constants.gd")  # Pure constants file

var buildings : Dictionary = {}
var units     : Dictionary = {}

var BuildingScenes   : Dictionary
var UIBuildingScenes : Dictionary
var UnitScenes       : Dictionary
var UIUnitScenes     : Dictionary

# REFACTOR PHASE 2: Constants now reference shared constants.gd file
# NOTE: Future code should use C.TILE_SIZE directly (via preload("res://scripts/constants.gd"))
const TILE_SIZE : Vector2i = C.TILE_SIZE

# -- Combat constants
const DEFENDER_RESERVE_ROW : Vector2i = C.DEFENDER_RESERVE_ROW
const DEFENDER_FLAG_SQUARE : Vector2i = C.DEFENDER_FLAG_SQUARE
const ATTACKER_RESERVE_ROW : Vector2i = C.ATTACKER_RESERVE_ROW
const ATTACKER_FLAG_SQUARE : Vector2i = C.ATTACKER_FLAG_SQUARE

# -- Feature flags
const FOG_OF_WAR_ENABLED : bool = C.FOG_OF_WAR_ENABLED
const CONFIRM_END_TURN_ENABLED : bool = C.CONFIRM_END_TURN_ENABLED
const WEALTH_MODE_ENABLED : bool = C.WEALTH_MODE_ENABLED

# -- Rendering
const STATUS_SEP : String = C.STATUS_SEP


func _ready() -> void:
	BuildingScenes = {
		Term.BuildingType.CENTER:      Preload.center_building_scene,
		Term.BuildingType.CHURCH:      Preload.church_building_scene,
		Term.BuildingType.COMMERCE:    Preload.commerce_building_scene,
		Term.BuildingType.DOCK:        Preload.dock_building_scene,
		Term.BuildingType.FARM:        Preload.farm_building_scene,
		Term.BuildingType.FORT:        Preload.fort_building_scene,
		Term.BuildingType.HOUSING:     Preload.house_building_scene,
		Term.BuildingType.METAL_MINE:  Preload.metal_mine_building_scene,
		Term.BuildingType.GOLD_MINE:   Preload.gold_mine_building_scene,
		Term.BuildingType.MILL:        Preload.mill_building_scene,
		Term.BuildingType.TAVERN:      Preload.tavern_building_scene,
		Term.BuildingType.WAR_COLLEGE: Preload.war_college_building_scene,
	}

	UIBuildingScenes = {
		Term.BuildingType.CENTER:      Preload.ui_center_building_scene,
		Term.BuildingType.CHURCH:      Preload.ui_church_scene,
		Term.BuildingType.COMMERCE:    Preload.ui_commerce_scene,
		Term.BuildingType.DOCK:        Preload.ui_dock_scene,
		Term.BuildingType.FARM:        Preload.ui_farm_scene,
		Term.BuildingType.FORT:        Preload.ui_fort_scene,
		Term.BuildingType.HOUSING:     Preload.ui_house_scene,
		Term.BuildingType.METAL_MINE:  Preload.ui_mine_scene,
		Term.BuildingType.GOLD_MINE:   Preload.ui_mine_scene,
		Term.BuildingType.MILL:        Preload.ui_mill_scene,
		Term.BuildingType.TAVERN:      Preload.ui_tavern_scene,
		Term.BuildingType.WAR_COLLEGE: Preload.ui_war_college_scene,
	}

	UnitScenes = {
		Term.UnitType.LEADER:    Preload.leader_unit,
		Term.UnitType.SETTLER:   Preload.settler_unit,
		Term.UnitType.EXPLORER:  Preload.explorer_unit,
		Term.UnitType.SHIP:      Preload.ship_unit,
		Term.UnitType.INFANTRY:  Preload.unit,
		Term.UnitType.CALVARY:   Preload.unit,
		Term.UnitType.ARTILLARY: Preload.unit,
	}

	UIUnitScenes = {
		Term.UnitType.LEADER:    Preload.ui_leader_scene,
		Term.UnitType.SETTLER:   Preload.ui_settler_scene,
		Term.UnitType.EXPLORER:  Preload.ui_explorer_scene,
		Term.UnitType.SHIP:      Preload.ui_ship_scene,
		Term.UnitType.INFANTRY:  Preload.ui_infantry_scene,
		Term.UnitType.CALVARY:   Preload.ui_calvary_scene,
		Term.UnitType.ARTILLARY: Preload.ui_artillary_scene
	}
	
	## BUILDINGS
	var json_as_text : String = FileAccess.get_file_as_string("res://assets/metadata/buildings.json")
	var json_as_dict : Dictionary = JSON.parse_string(json_as_text)
	if json_as_dict:
		for key:String in json_as_dict:
			var building_type : Term.BuildingType = _convert_to_building_type(key)
			var building_data : Dictionary = json_as_dict[key]

			buildings[building_type] = {
				"cost": [],
				"make": [],
				"need": [],
				"stat": [],
				"labor_demand": [],
			}

			# Building cost..
			if "cost" in building_data:
				for cost:Dictionary in building_data["cost"]:
					buildings[building_type]["cost"].append(_convert_to_transaction(cost))
		
			# Building make..
			if "make" in building_data:
				for make:Dictionary in building_data["make"]:
					buildings[building_type]["make"].append(_convert_to_transaction(make))

			# Building need..
			if "need" in building_data:
				for need:Dictionary in building_data["need"]:
					buildings[building_type]["need"].append(_convert_to_transaction(need))

			# Building labor demands..
			if "labor_demand" in building_data:
				for labor_demand:int in building_data["labor_demand"]:
					buildings[building_type]["labor_demand"].append(labor_demand)
					
			# Building stat..
			if "stat" in building_data:
				for stat:Dictionary in building_data["stat"]:
					buildings[building_type]["stat"].append(stat)

		# print(JSON.stringify(buildings, "\t"))

	## UNITS
	var json_as_text2 : String = FileAccess.get_file_as_string("res://assets/metadata/units.json")
	var json_as_dict2 : Dictionary = JSON.parse_string(json_as_text2)
	if json_as_dict2:
		for key:String in json_as_dict2:
			var unit_type : Term.UnitType = _convert_to_unit_type(key)
			var unit_data : Dictionary = json_as_dict2[key]

			units[unit_type] = {
				"cost": [],
				"need": [],
				"stat": [],
			}

			# Unit cost..
			if "cost" in unit_data:
				for cost:Dictionary in unit_data["cost"]:
					units[unit_type]["cost"].append(_convert_to_transaction(cost))
		
			# Unit need..
			if "need" in unit_data:
				for need:Dictionary in unit_data["need"]:
					units[unit_type]["need"].append(_convert_to_transaction(need))
		
			# Unit stat..
			if "stat" in unit_data:
				for stat:Dictionary in unit_data["stat"]:
					units[unit_type]["stat"].append(stat)


# func get_canvas_layer() -> CanvasLayer:
# 	return get_tree().get_first_node_in_group("canvas_layer") as CanvasLayer


func get_world_canvas() -> WorldCanvas:
	return get_tree().get_first_node_in_group("world_canvas") as WorldCanvas


func get_world() -> WorldManager:
	return get_tree().get_first_node_in_group("world") as WorldManager


func get_world_selector() -> WorldSelector:
	return get_world().world_selector


func get_world_map() -> WorldGen:
	return get_world().world_gen


func get_player_manager() -> PlayerManager:
	return get_world().player_manager


func get_world_tile_map() -> TileMapLayer:
	return get_world_map().get_land_layer()


func get_building_scene_by_type(_building_type: Term.BuildingType) -> PackedScene:
	return BuildingScenes[_building_type]


func get_ui_building_scene_by_type(_building_type: Term.BuildingType) -> PackedScene:
	return UIBuildingScenes[_building_type]


func get_unit_scene_by_type(_unit_type: Term.UnitType) -> PackedScene:
	return UnitScenes[_unit_type]


func get_ui_unit_scene_by_type(_unit_type: Term.UnitType) -> PackedScene:
	return UIUnitScenes[_unit_type]


func _convert_building_type_to_name(_building_type:Term.BuildingType) -> String:
	# REFACTOR PHASE 1: Delegating to TypeRegistry
	return TypeRegistry.building_type_to_name(_building_type)


func _convert_to_building_type(_building_code: String) -> Term.BuildingType:
	# REFACTOR PHASE 1: Delegating to TypeRegistry
	return TypeRegistry.building_type_from_code(_building_code)
	
func _convert_unit_type_to_name(_unit_type: Term.UnitType) -> String:
	# REFACTOR PHASE 1: Delegating to TypeRegistry
	return TypeRegistry.unit_type_to_name(_unit_type)


func _convert_to_unit_type(_code: String) -> Term.UnitType:
	# REFACTOR PHASE 1: Delegating to TypeRegistry
	return TypeRegistry.unit_type_from_code(_code)


func _convert_to_resource_type(_resource_code: String) -> Term.ResourceType:
	# REFACTOR PHASE 1: Delegating to TypeRegistry
	return TypeRegistry.resource_type_from_code(_resource_code)


func _convert_resource_type_to_name(_resource_type:Term.ResourceType) -> String:
	# REFACTOR PHASE 1: Delegating to TypeRegistry
	return TypeRegistry.resource_type_to_name(_resource_type)

func _convert_to_transaction(_resources: Dictionary) -> Transaction:
	var transaction:Transaction = Transaction.new()
	transaction.add_resources(_resources)
	return transaction


#region BUILDINGS
func get_building_cost(_building_type: Term.BuildingType, _building_level: int = 1) -> Transaction:
	var transaction : Transaction = buildings[_building_type]["cost"][_building_level-1]
	return transaction.clone()


func get_building_make(_building_type: Term.BuildingType, _building_level: int) -> Transaction:
	var transaction : Transaction = buildings[_building_type]["make"][_building_level-1]
	return transaction.clone()


func get_building_need(_building_type: Term.BuildingType, _building_level: int) -> Transaction:
	var transaction : Transaction = Transaction.new()
	var need        : Transaction = Transaction.new()
	
	if "need" in buildings[_building_type]:
		need = buildings[_building_type]["need"][_building_level-1]
	
	for i:String in Term.ResourceType:
		var type : Term.ResourceType = Term.ResourceType[i]
		if type in need.resources:
			transaction.resources[type] = need.resources[type]
		else:
			transaction.resources[type] = 0

	return transaction


func get_building_labor_demand(_building_type: Term.BuildingType, _building_level: int) -> int:
	if "labor_demand" in buildings[_building_type]:
		var value : int = buildings[_building_type]["labor_demand"][_building_level-1]
		return value
	return 0


func get_building_stat(_building_type: Term.BuildingType, _building_level: int) -> Dictionary:
	if "stat" in buildings[_building_type]:
		return buildings[_building_type]["stat"][_building_level-1]
	return {}
#endregion


#region UNITS
func get_unit_cost(_unit_type: Term.UnitType, _unit_level: int) -> Transaction:
	var transaction : Transaction = units[_unit_type]["cost"][_unit_level-1]
	return transaction.clone()

func get_unit_stat(_unit_type: Term.UnitType, _unit_level: int) -> Dictionary:
	if "stat" in units[_unit_type]:
		return units[_unit_type]["stat"][_unit_level-1]
	return {}
#endregion


#region MILITARY RESEARCH
func get_research_max_level() -> int:
	# REFACTOR PHASE 2: Delegating to GameConfig
	return GameConfig.get_research_max_level()


func get_research_max_exp_by_level(level:int) -> int:
	# REFACTOR PHASE 2: Delegating to GameConfig
	return GameConfig.get_research_max_exp_by_level(level)
#endregion


#region POPULATION GROWTH
func get_base_population_growth_rate() -> float:
	"""
	According to this wiki: https://gamefaqs.gamespot.com/pc/196975-conquest-of-the-new-world/faqs/2038
	TODO: 8% of current population + 10 per Church level
	"""
	# REFACTOR PHASE 2: Delegating to GameConfig
	return GameConfig.get_base_population_growth_rate()


func get_crops_consumption_rate() -> float:
	"""
	1 crop feeds 100 population
	"""
	# REFACTOR PHASE 2: Delegating to GameConfig
	return GameConfig.get_crops_consumption_rate()
#endregion


#region PRODUCTION
"""
Specialisation bonuses are based on building-level-grid-squares 
(ie: farms are worth 4 points per building level), in blocks of 20: the 
first block is worth 1% each, the next block is worth a 0.5% each, the 
next block of 20 is worth 0.25% each, such that you asymptotically 
approach 40% total possible bonus.  Once this bonus is calculated for 
the largest commodity sector in your colony, the bonus value of the 
SECOND largest commodity is subtracted from the first. As you can see by 
how the numbers start high and then shrink, even having 10 building 
levels of another commodity reduces your possible maximum to 30%.
	Bonuses are calculated for mills, mines (gold and metal lumped 
together), and farms.  Commerce does not gain production bonuses.
"""
#endregion


#region SORTING
static func sort_building_types_by_priority(_a: Term.BuildingType, _b: Term.BuildingType) -> bool:
	# REFACTOR PHASE 1: Delegating to GameRules
	return GameRules.sort_building_types_by_priority(_a, _b)


static func sort_buildings_by_building_type(_a: Building, _b: Building) -> bool:
	# REFACTOR PHASE 1: Delegating to GameRules
	return GameRules.sort_buildings_by_priority(_a, _b)


static func sort_combat_units_by_type(a: CombatUnit, b: CombatUnit) -> bool:
	"""
	Sort units by type: See Term.UnitType
	"""
	# REFACTOR PHASE 1: Delegating to GameRules
	return GameRules.sort_combat_units_by_type(a, b)


static func sort_combat_units_by_health(a: CombatUnit, b: CombatUnit) -> bool:
	"""
	Sort units by type: stat.health
	"""
	# REFACTOR PHASE 1: Delegating to GameRules
	return GameRules.sort_combat_units_by_health(a, b)


# static func sort_combat_squares_by_priority(a: CombatSquare, b: CombatSquare) -> bool:
# 	"""
# 	Sort squares by priority:
# 		- Flag Square > Non-Flag Square
# 		- Towards opposing force's "Reserve Row"
# 	"""

# 	if a.is_flag_square:
# 		return true
# 	else:


# 		return false

	
