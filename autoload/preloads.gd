extends Node
class_name PreloadsRef

## Centralized scene and resource preloading.
## All PackedScenes are preloaded at startup to prevent runtime loading delays.
##
## REFACTOR PHASE 3: Added typed accessor methods for buildings and units.
## Use get_building_scene(type) instead of directly accessing properties.

const player_scene       : PackedScene = preload("res://scenes/player/player.tscn")
const ui_diplomacy_scene : PackedScene = preload("res://ui/ui_diplomacy.tscn")
const ui_trade_scene     : PackedScene = preload("res://ui/trade/ui_trade.tscn")
const ui_new_trade_scene : PackedScene = preload("res://ui/trade/ui_new_trade.tscn")

# NPC
const npc_scene        : PackedScene = preload("res://scenes/npc/npc.tscn")
const village_scene    : PackedScene = preload("res://scenes/npc/village.tscn")
const ui_village_scene : PackedScene = preload("res://ui/npc/ui_village.tscn")
const dwarven_village_scene : PackedScene = preload("res://scenes/npc/race/dwarven_village.tscn")
const elven_village_scene   : PackedScene = preload("res://scenes/npc/race/elven_village.tscn")

# BUILDINGS
const center_building_scene      : PackedScene = preload("res://scenes/buildings/center_building.tscn")
const church_building_scene      : PackedScene = preload("res://scenes/buildings/church_building.tscn")
const commerce_building_scene    : PackedScene = preload("res://scenes/buildings/commerce_building.tscn")
const dock_building_scene        : PackedScene = preload("res://scenes/buildings/dock_building.tscn")
const farm_building_scene        : PackedScene = preload("res://scenes/buildings/farm_building.tscn")
const fort_building_scene        : PackedScene = preload("res://scenes/buildings/fort_building.tscn")
const metal_mine_building_scene  : PackedScene = preload("res://scenes/buildings/metal_mine_building.tscn")
const gold_mine_building_scene   : PackedScene = preload("res://scenes/buildings/gold_mine_building.tscn")
const house_building_scene       : PackedScene = preload("res://scenes/buildings/house_building.tscn")
const mill_building_scene        : PackedScene = preload("res://scenes/buildings/mill_building.tscn")
const war_college_building_scene : PackedScene = preload("res://scenes/buildings/war_college_building.tscn")
const tavern_building_scene      : PackedScene = preload("res://scenes/buildings/tavern_building.tscn")

const ui_found_colony_scene       : PackedScene = preload("res://ui/player/ui_found_colony.tscn")
const ui_center_building_scene    : PackedScene = preload("res://ui/buildings/ui_center_building.tscn")
const ui_build_building_scene     : PackedScene = preload("res://ui/player/ui_build_building.tscn")
const ui_building_list_scene      : PackedScene = preload("res://ui/player/ui_building_list.tscn")
const ui_building_unit_list_scene : PackedScene = preload("res://ui/player/ui_building_unit_list.tscn")
const ui_carrier_unit_list_scene  : PackedScene = preload("res://ui/player/ui_carrier_unit_list.tscn")
const ui_pop_detail_scene         : PackedScene = preload("res://ui/player/ui_population_detail.tscn")
const ui_commodity_detail_scene   : PackedScene = preload("res://ui/player/ui_commodity_details.tscn")

const ui_church_scene      : PackedScene = preload("res://ui/buildings/ui_church_building.tscn")
const ui_commerce_scene    : PackedScene = preload("res://ui/buildings/ui_commerce_building.tscn")
const ui_dock_scene        : PackedScene = preload("res://ui/buildings/ui_dock_building.tscn")
const ui_farm_scene        : PackedScene = preload("res://ui/buildings/ui_farm_building.tscn")
const ui_fort_scene        : PackedScene = preload("res://ui/buildings/ui_fort_building.tscn")
const ui_mine_scene        : PackedScene = preload("res://ui/buildings/ui_mine_building.tscn")
const ui_house_scene       : PackedScene = preload("res://ui/buildings/ui_house_building.tscn")
const ui_mill_scene        : PackedScene = preload("res://ui/buildings/ui_mill_building.tscn")
const ui_war_college_scene : PackedScene = preload("res://ui/buildings/ui_war_college_building.tscn")
const ui_tavern_scene      : PackedScene = preload("res://ui/buildings/ui_tavern_building.tscn")


# UNITS
const unit          : PackedScene = preload("res://scenes/units/unit.tscn")
const leader_unit   : PackedScene = preload("res://scenes/units/leader_unit.tscn")
const ship_unit     : PackedScene = preload("res://scenes/units/ship_unit.tscn")
const settler_unit  : PackedScene = preload("res://scenes/units/settler_unit.tscn")
const explorer_unit : PackedScene = preload("res://scenes/units/explorer_unit.tscn")

const ui_settler_scene   : PackedScene = preload("res://ui/units/ui_settler_unit.tscn")
const ui_explorer_scene  : PackedScene = preload("res://ui/units/ui_explorer_unit.tscn")
const ui_create_leader_scene : PackedScene = preload("res://ui/units/ui_create_leader_unit.tscn")
const ui_leader_scene    : PackedScene = preload("res://ui/units/ui_leader_unit.tscn")
const ui_ship_scene      : PackedScene = preload("res://ui/units/ui_ship_unit.tscn")
const ui_infantry_scene  : PackedScene = preload("res://ui/units/ui_infantry_unit.tscn")
const ui_calvary_scene   : PackedScene = preload("res://ui/units/ui_calvary_unit.tscn")
const ui_artillary_scene : PackedScene = preload("res://ui/units/ui_artillary_unit.tscn")


# COMBAT
const combat      : PackedScene = preload("res://combat/combat.tscn")
const combat_unit : PackedScene = preload("res://combat/combat_unit.tscn")

# COMBAT RESOURCES
const combat_artillary_unit : Resource = preload("res://combat/resources/artillary_animations.tres")
const combat_calvary_unit   : Resource = preload("res://combat/resources/calvary_animations.tres")
const combat_infantry_unit  : Resource = preload("res://combat/resources/infantry_animations.tres")
const combat_orc_artillary_unit : Resource = preload("res://combat/resources/orc_artillary_animations.tres")
const combat_orc_calvary_unit   : Resource = preload("res://combat/resources/orc_calvary_animations.tres")
const combat_orc_infantry_unit  : Resource = preload("res://combat/resources/orc_infantry_animations.tres")


#region TYPED ACCESSORS (REFACTOR PHASE 3)

## Building scene accessor dictionaries (lazy-initialized)
static var _building_scenes: Dictionary = {}
static var _building_ui_scenes: Dictionary = {}
static var _unit_scenes: Dictionary = {}
static var _unit_ui_scenes: Dictionary = {}
static var _initialized: bool = false

static func _initialize_dictionaries() -> void:
	"""Initialize scene lookup dictionaries (called once on first access)."""
	if _initialized:
		return
	_initialized = true

	# Building scenes
	_building_scenes = {
		Term.BuildingType.CENTER: center_building_scene,
		Term.BuildingType.CHURCH: church_building_scene,
		Term.BuildingType.COMMERCE: commerce_building_scene,
		Term.BuildingType.DOCK: dock_building_scene,
		Term.BuildingType.FARM: farm_building_scene,
		Term.BuildingType.FORT: fort_building_scene,
		Term.BuildingType.HOUSING: house_building_scene,
		Term.BuildingType.METAL_MINE: metal_mine_building_scene,
		Term.BuildingType.GOLD_MINE: gold_mine_building_scene,
		Term.BuildingType.MILL: mill_building_scene,
		Term.BuildingType.WAR_COLLEGE: war_college_building_scene,
		Term.BuildingType.TAVERN: tavern_building_scene,
	}

	# Building UI scenes
	_building_ui_scenes = {
		Term.BuildingType.CENTER: ui_center_building_scene,
		Term.BuildingType.CHURCH: ui_church_scene,
		Term.BuildingType.COMMERCE: ui_commerce_scene,
		Term.BuildingType.DOCK: ui_dock_scene,
		Term.BuildingType.FARM: ui_farm_scene,
		Term.BuildingType.FORT: ui_fort_scene,
		Term.BuildingType.HOUSING: ui_house_scene,
		Term.BuildingType.METAL_MINE: ui_mine_scene,
		Term.BuildingType.GOLD_MINE: ui_mine_scene,
		Term.BuildingType.MILL: ui_mill_scene,
		Term.BuildingType.WAR_COLLEGE: ui_war_college_scene,
		Term.BuildingType.TAVERN: ui_tavern_scene,
	}

	# Unit scenes
	_unit_scenes = {
		Term.UnitType.LEADER: leader_unit,
		Term.UnitType.SETTLER: settler_unit,
		Term.UnitType.EXPLORER: explorer_unit,
		Term.UnitType.SHIP: ship_unit,
		Term.UnitType.INFANTRY: unit,
		Term.UnitType.CALVARY: unit,
		Term.UnitType.ARTILLARY: unit,
	}

	# Unit UI scenes
	_unit_ui_scenes = {
		Term.UnitType.LEADER: ui_leader_scene,
		Term.UnitType.SETTLER: ui_settler_scene,
		Term.UnitType.EXPLORER: ui_explorer_scene,
		Term.UnitType.SHIP: ui_ship_scene,
		Term.UnitType.INFANTRY: ui_infantry_scene,
		Term.UnitType.CALVARY: ui_calvary_scene,
		Term.UnitType.ARTILLARY: ui_artillary_scene,
	}


static func get_building_scene(type: Term.BuildingType) -> PackedScene:
	"""Get building scene by type. Asserts if type not found."""
	_initialize_dictionaries()
	assert(_building_scenes.has(type), "No building scene for type: " + str(type))
	return _building_scenes[type]


static func get_building_ui_scene(type: Term.BuildingType) -> PackedScene:
	"""Get building UI scene by type. Asserts if type not found."""
	_initialize_dictionaries()
	assert(_building_ui_scenes.has(type), "No building UI scene for type: " + str(type))
	return _building_ui_scenes[type]


static func get_unit_scene(type: Term.UnitType) -> PackedScene:
	"""Get unit scene by type. Asserts if type not found."""
	_initialize_dictionaries()
	assert(_unit_scenes.has(type), "No unit scene for type: " + str(type))
	return _unit_scenes[type]


static func get_unit_ui_scene(type: Term.UnitType) -> PackedScene:
	"""Get unit UI scene by type. Asserts if type not found."""
	_initialize_dictionaries()
	assert(_unit_ui_scenes.has(type), "No unit UI scene for type: " + str(type))
	return _unit_ui_scenes[type]

#endregion
