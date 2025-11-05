extends Node2D
class_name DefinitionsRef

# REFACTOR PHASE 1: Import new utility classes
# const TypeRegistry = preload("res://scripts/type_registry.gd")
# const GameRules = preload("res://scripts/game_rules.gd")
# const C = preload("res://scripts/constants.gd")  # Pure constants file

# REFACTOR PHASE 4: Building/unit data dictionaries removed - now handled by GameData autoload
# Use GameData.get_building_cost(type, level) instead of buildings[type]["cost"][level-1]

# REFACTOR PHASE 3: Scene dictionaries removed - now handled by Preload autoload
# Use Preload.get_building_scene(type) instead of BuildingScenes[type]

# REFACTOR PHASE 2: Constants now reference shared constants.gd file
# NOTE: Future code should use C.TILE_SIZE directly (via preload("res://scripts/constants.gd"))
const TILE_SIZE : Vector2i = Preload.C.TILE_SIZE

# -- Combat constants
const DEFENDER_RESERVE_ROW : Vector2i = Preload.C.DEFENDER_RESERVE_ROW
const DEFENDER_FLAG_SQUARE : Vector2i = Preload.C.DEFENDER_FLAG_SQUARE
const ATTACKER_RESERVE_ROW : Vector2i = Preload.C.ATTACKER_RESERVE_ROW
const ATTACKER_FLAG_SQUARE : Vector2i = Preload.C.ATTACKER_FLAG_SQUARE

# -- Feature flags
const FOG_OF_WAR_ENABLED : bool = Preload.C.FOG_OF_WAR_ENABLED
const CONFIRM_END_TURN_ENABLED : bool = Preload.C.CONFIRM_END_TURN_ENABLED
const WEALTH_MODE_ENABLED : bool = Preload.C.WEALTH_MODE_ENABLED

# -- Rendering
const STATUS_SEP : String = Preload.C.STATUS_SEP


func _ready() -> void:
	# REFACTOR PHASE 4: JSON loading removed - now handled by GameData autoload
	# REFACTOR PHASE 3: Scene dictionary initialization removed - now handled by Preload autoload
	pass


#region SERVICE LOCATOR (REFACTOR PHASE 5)
## DEPRECATED: These methods use the Service Locator anti-pattern.
## They are maintained for backward compatibility but should be migrated away from.
##
## Recommended migration path:
##   1. Use dependency injection (pass references via @export or constructor)
##   2. Use signals for communication between loosely coupled systems
##   3. Access WorldService directly if service locator is truly needed
##
## These methods now delegate to WorldService which caches the lookups for performance.

func get_world_canvas() -> WorldCanvas:
	return WorldService.get_world_canvas()


func get_world() -> WorldManager:
	return WorldService.get_world()


func get_world_selector() -> WorldSelector:
	return WorldService.get_world_selector()


func get_world_map() -> WorldGen:
	return WorldService.get_world_map()


func get_player_manager() -> PlayerManager:
	return WorldService.get_player_manager()


func get_world_tile_map() -> TileMapLayer:
	return WorldService.get_world_tile_map()

#endregion


func get_building_scene_by_type(_building_type: Term.BuildingType) -> PackedScene:
	# REFACTOR PHASE 3: Delegating to Preload (using static call)
	return PreloadsRef.get_building_scene(_building_type)


func get_ui_building_scene_by_type(_building_type: Term.BuildingType) -> PackedScene:
	# REFACTOR PHASE 3: Delegating to Preload (using static call)
	return PreloadsRef.get_building_ui_scene(_building_type)


func get_unit_scene_by_type(_unit_type: Term.UnitType) -> PackedScene:
	# REFACTOR PHASE 3: Delegating to Preload (using static call)
	return PreloadsRef.get_unit_scene(_unit_type)


func get_ui_unit_scene_by_type(_unit_type: Term.UnitType) -> PackedScene:
	# REFACTOR PHASE 3: Delegating to Preload (using static call)
	return PreloadsRef.get_unit_ui_scene(_unit_type)


func _convert_building_type_to_name(_building_type:Term.BuildingType) -> String:
	# REFACTOR PHASE 1: Delegating to TypeRegistry
	return Preload.TR.building_type_to_name(_building_type)


func _convert_to_building_type(_building_code: String) -> Term.BuildingType:
	# REFACTOR PHASE 1: Delegating to TypeRegistry
	return Preload.TR.building_type_from_code(_building_code)
	
func _convert_unit_type_to_name(_unit_type: Term.UnitType) -> String:
	# REFACTOR PHASE 1: Delegating to TypeRegistry
	return Preload.TR.unit_type_to_name(_unit_type)


func _convert_to_unit_type(_code: String) -> Term.UnitType:
	# REFACTOR PHASE 1: Delegating to TypeRegistry
	return Preload.TR.unit_type_from_code(_code)


func _convert_to_resource_type(_resource_code: String) -> Term.ResourceType:
	# REFACTOR PHASE 1: Delegating to TypeRegistry
	return Preload.TR.resource_type_from_code(_resource_code)


func _convert_resource_type_to_name(_resource_type:Term.ResourceType) -> String:
	# REFACTOR PHASE 1: Delegating to TypeRegistry
	return Preload.TR.resource_type_to_name(_resource_type)

func _convert_to_transaction(_resources: Dictionary) -> Transaction:
	var transaction:Transaction = Transaction.new()
	transaction.add_resources(_resources)
	return transaction


#region BUILDINGS
func get_building_cost(_building_type: Term.BuildingType, _building_level: int = 1) -> Transaction:
	# REFACTOR PHASE 4: Delegating to GameData
	return GameData.get_building_cost(_building_type, _building_level)


func get_building_make(_building_type: Term.BuildingType, _building_level: int) -> Transaction:
	# REFACTOR PHASE 4: Delegating to GameData
	return GameData.get_building_make(_building_type, _building_level)


func get_building_need(_building_type: Term.BuildingType, _building_level: int) -> Transaction:
	# REFACTOR PHASE 4: Delegating to GameData
	return GameData.get_building_need(_building_type, _building_level)


func get_building_labor_demand(_building_type: Term.BuildingType, _building_level: int) -> int:
	# REFACTOR PHASE 4: Delegating to GameData
	return GameData.get_building_labor_demand(_building_type, _building_level)


func get_building_stat(_building_type: Term.BuildingType, _building_level: int) -> Dictionary:
	# REFACTOR PHASE 4: Delegating to GameData
	return GameData.get_building_stat(_building_type, _building_level)
#endregion


#region UNITS
func get_unit_cost(_unit_type: Term.UnitType, _unit_level: int) -> Transaction:
	# REFACTOR PHASE 4: Delegating to GameData
	return GameData.get_unit_cost(_unit_type, _unit_level)

func get_unit_stat(_unit_type: Term.UnitType, _unit_level: int) -> Dictionary:
	# REFACTOR PHASE 4: Delegating to GameData
	return GameData.get_unit_stat(_unit_type, _unit_level)
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
	return Preload.GR.sort_building_types_by_priority(_a, _b)


static func sort_buildings_by_building_type(_a: Building, _b: Building) -> bool:
	# REFACTOR PHASE 1: Delegating to GameRules
	return Preload.GR.sort_buildings_by_priority(_a, _b)


static func sort_combat_units_by_type(a: CombatUnit, b: CombatUnit) -> bool:
	"""
	Sort units by type: See Term.UnitType
	"""
	# REFACTOR PHASE 1: Delegating to GameRules
	return Preload.GR.sort_combat_units_by_type(a, b)


static func sort_combat_units_by_health(a: CombatUnit, b: CombatUnit) -> bool:
	"""
	Sort units by type: stat.health
	"""
	# REFACTOR PHASE 1: Delegating to GameRules
	return Preload.GR.sort_combat_units_by_health(a, b)


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

	
