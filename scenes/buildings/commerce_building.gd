extends MakeBuilding
class_name CommerceBuilding


func _ready() -> void:
	super._ready()
	
	title = "Commerce"
	
	building_type = Term.BuildingType.COMMERCE
	building_size = Term.BuildingSize.SMALL
	
	# -- Make properties..
	make_resource_type = Term.ResourceType.GOODS
	make_industry_type = Term.IndustryType.NONE


#override.. MakeBuilding
func get_expected_produce_value() -> float:
	var make  : Transaction = get_make()
	var need  : Transaction = get_need()
	var value : float = 0
	
	if colony.bank.can_afford_next_turn(need):
		value = make.resources[make_resource_type]
		
	return value


#override.. MakeBuilding
func get_total_production_modifier() -> int:
	# No modifier for Commerce..
	return 0
