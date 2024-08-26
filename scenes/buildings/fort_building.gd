extends Building
class_name FortBuilding

var train_level : int
var train_unit : Term.UnitType = Term.UnitType.NONE

func _ready() -> void:
	super._ready()
	
	building_type = Term.BuildingType.FORT
	building_size = Term.BuildingSize.LARGE


func get_unit_capacity_value() -> int:
	return Def.get_building_stat(building_type, level).max_military_units


func can_train_military_unit(i_unit_type: Term.UnitType) -> bool:
	if i_unit_type == train_unit:
		return true
	
	if building_state != Term.BuildingState.ACTIVE:
		return false
	
	if train_unit != Term.UnitType.NONE:
		return false

	# -- Military unit capacity check..
	var unit_count    : int = colony.get_military_unit_count()
	var unit_capacity : int = colony.get_max_military_unit_count()
	if unit_count >= unit_capacity:
		return false

	# -- Resource availability check..
	var unit_cost : Transaction = Def.get_unit_cost(i_unit_type, train_level)
	return colony.bank.can_afford_this_turn(unit_cost)
