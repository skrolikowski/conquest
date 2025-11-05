extends Building
class_name DockBuilding

var construct_ship : bool


func _ready() -> void:
	super._ready()

	title = "Dock"
	
	building_type = Term.BuildingType.DOCK
	building_size = Term.BuildingSize.SMALL


func get_unit_capacity_value() -> int:
	return GameData.get_building_stat(building_type, level).max_ships


func can_construct_ship() -> bool:
	# -- Allow for unchecking..
	if construct_ship:
		return true

	# -- Building state check..
	if building_state != Term.BuildingState.ACTIVE:
		return false
		
	# -- Unit capacity check..
	var unit_count    : int = colony.get_ship_unit_count()
	var unit_capacity : int = colony.get_max_ship_unit_count()
	if unit_count >= unit_capacity:
		return false
		
	# -- Resource availability check..
	var unit_cost : Transaction = GameData.get_unit_cost(Term.UnitType.SHIP, level)
	return colony.bank.can_afford_this_turn(unit_cost)
