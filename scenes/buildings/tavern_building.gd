extends Building
class_name TavernBuilding

var recruit_explorer : bool


func _ready() -> void:
	super._ready()
	
	title = "Tavern"

	building_type = Term.BuildingType.TAVERN
	building_size = Term.BuildingSize.SMALL


func get_unit_capacity_value() -> int:
	return GameData.get_building_stat(building_type, level).max_explorers


func can_recruit_explorer() -> bool:
	# -- Allow for unchecking..
	if recruit_explorer:
		return true

	# -- Building state check..
	if building_state != Term.BuildingState.ACTIVE:
		return false
		
	# -- Unit capacity check..
	var unit_count    : int = colony.get_explorer_unit_count()
	var unit_capacity : int = colony.get_max_explorer_unit_count()
	if unit_count >= unit_capacity:
		return false
		
	# -- Resource availability check..
	var unit_cost : Transaction = GameData.get_unit_cost(Term.UnitType.EXPLORER, level)
	return colony.bank.can_afford_this_turn(unit_cost)
