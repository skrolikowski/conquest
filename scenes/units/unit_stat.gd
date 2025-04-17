extends Resource
class_name UnitStats

signal health_changed(_health:int, _max_health:int)

@export var title         : String
@export var unit_name     : String
@export var unit_type     : Term.UnitType = Term.UnitType.NONE
@export var unit_state    : Term.UnitState = Term.UnitState.IDLE
@export var unit_category : Term.UnitCategory = Term.UnitCategory.NONE

var player      : Player
var level       : int = 1 : set = _set_level
var max_level   : int = 5
var health      : int : set = _set_health
var move_points   : float = 0
var is_persistent : bool = false

# -- Non-Leader Units only..
var leader : UnitStats

# -- Leader Units only..
var stat_points	: int = 0
var stat_props  : Dictionary = {
	"attacks_in_combat": 0,
	"move_bonus": 0,
	"charisma": 0,
	"reputation": 0
}


func _set_level(_level : int) -> void:
	level  = _level
	_set_health(level)
	

func _set_health(_health : int) -> void:
	if health != _health:
		health = _health
		health_changed.emit(health, level)

func level_up() -> void:
	level = min(level + 1, max_level)


func heal() -> void:
	health = min(health + 1, level)


func is_dead() -> bool:
	return health <= 0


func get_population() -> int:
	return get_stat().population


func get_stat() -> Dictionary:
	return Def.get_unit_stat(unit_type, level)


func get_cost() -> Transaction:
	return Def.get_unit_cost(unit_type, level)


#region COMBAT
var combat_stats : Dictionary = {
	"battles": 0,
	"battles_won": 0,
}
#endregion


#region UNIT ATTACHMENT
@export var attached_units : Array[UnitStats] = []
var max_attached_units : int = 0

func attach_unit(_unit: UnitStats) -> void:
	if not has_capacity():
		return
	
	_unit.leader = self
	attached_units.append(_unit)


func detach_unit(_unit:UnitStats) -> void:
	if attached_units.has(_unit):
		_unit.leader = null
		attached_units.erase(_unit)


func can_attach_units() -> bool:
	return unit_type == Term.UnitType.LEADER or unit_type == Term.UnitType.SHIP


func has_capacity() -> bool:
	return can_attach_units() and attached_units.size() < max_attached_units


func get_units_sorted_by_unit_type() -> Array[UnitStats]:
	var units : Array[UnitStats] = attached_units
	units.sort_custom(func(a:Unit, b:Unit) -> bool: return a.unit_type < b.unit_type)
	return units
#endregion


#region STATIC METHODS
static func New_Unit(_unit_type : Term.UnitType, _level : int = 1) -> UnitStats:
	
	var unit_stats : UnitStats = UnitStats.new()
	unit_stats.title      = Def._convert_unit_type_to_name(_unit_type)
	unit_stats.unit_type  = _unit_type
	unit_stats.unit_state = Term.UnitState.IDLE
	unit_stats.level      = _level
	
	if _unit_type == Term.UnitType.LEADER:
		unit_stats.unit_name  = NameGenerator.generate(4, 5) +  " " + NameGenerator.generate(6, 8)
		unit_stats.max_attached_units = 8
		unit_stats.attached_units = []
		unit_stats.stat_props = {
			"attacks_in_combat": 0,
			"move_bonus": 0,
			"charisma": 0,
			"reputation": 0
		}
		unit_stats.unit_category = Term.UnitCategory.MILITARY
	elif _unit_type == Term.UnitType.SHIP:
		unit_stats.unit_name  = NameGenerator.generate(6, 8)
		unit_stats.max_attached_units = Def.get_unit_stat(_unit_type, _level).cargo_hold
		unit_stats.attached_units = []
		unit_stats.unit_category = Term.UnitCategory.SHIP
	elif _unit_type == Term.UnitType.INFANTRY || _unit_type == Term.UnitType.CALVARY || _unit_type == Term.UnitType.ARTILLARY:
		unit_stats.unit_category = Term.UnitCategory.MILITARY
		
	return unit_stats

#endregion


#region GAME PERSISTENCE
func on_save_data() -> Dictionary:
	return {
		"title": title,
		"unit_name": unit_name,
		"unit_type": unit_type,
		"unit_state": unit_state,
		"unit_category": unit_category,
		"level": level,
		"health": health,
		"move_points": move_points,
		"is_persistent" : is_persistent,
		"stat_points": stat_points,
		"stat_props": stat_props,
		"combat_stats": combat_stats,
		"attached_units": attached_units.map(func(u:UnitStats) -> Dictionary: return u.on_save_data())
	}


func on_load_data(_data: Dictionary) -> void:
	title 		  = _data["title"]
	unit_name 	  = _data["unit_name"]
	unit_type 	  = _data["unit_type"]
	unit_state 	  = _data["unit_state"]
	unit_category = _data["unit_category"]
	level 		  = _data["level"]
	health 		  = _data["health"]
	move_points   = _data["move_points"]
	is_persistent = _data["is_persistent"]
	stat_points   = _data["stat_points"]
	stat_props    = _data["stat_props"]
	combat_stats  = _data["combat_stats"]

	for unit_data:Dictionary in _data["attached_units"]:
		var unit : UnitStats = UnitStats.new()
		unit.on_load_data(unit_data)
		unit.player = player
		attached_units.append(unit)

#endregion
