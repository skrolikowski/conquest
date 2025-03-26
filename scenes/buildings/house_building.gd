extends Building
class_name HouseBuilding

var recruit_settler : bool


func _ready() -> void:
	super._ready()
	
	title = "Housing"

	building_type = Term.BuildingType.HOUSING
	building_size = Term.BuildingSize.SMALL


func get_population_capacity_value() -> int:
	return Def.get_building_stat(building_type, level).max_population


func can_recruit_settler() -> bool:
	# -- Allow for unchecking..
	if recruit_settler:
		return true

	# -- Building state check..
	if building_state != Term.BuildingState.ACTIVE:
		return false
		
	var unit_cost : Transaction = Def.get_unit_cost(Term.UnitType.SETTLER, level)
	return colony.bank.can_afford_this_turn(unit_cost)
