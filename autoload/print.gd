extends Node2D
class_name PrintRef


static func build_building_type(_building_type: Term.BuildingType) -> String:
	var text : PackedStringArray = PackedStringArray()

	# -- Building name..
	var building_name : String = Def._convert_building_type_to_name(_building_type)
	text.append(building_name)
	
	# -- Building cost..
	var building_cost : Transaction = Def.get_building_cost(_building_type, 1)
	var cost_text : String = get_cost_text(building_cost)
	text.append("Cost: " + cost_text)
	
	# -- Labor demand..
	var labor_demand : int = Def.get_building_labor_demand(_building_type, 1)
	if labor_demand > 0:
		text.append("Labor: +" + str(labor_demand))

	return (" " + Def.STATUS_SEP + " ").join(text)


static func buy_unit_type(_unit_type: Term.UnitType) -> String:
	var text : PackedStringArray = PackedStringArray()
	
	# -- Unit name..
	var unit_name : String = Def._convert_unit_type_to_name(_unit_type)
	text.append(unit_name)
	
	# -- Unit cost..
	var unit_cost : Transaction = Def.get_unit_cost(_unit_type, 1)
	var cost_text : String = get_cost_text(unit_cost)
	text.append("Cost: " + cost_text)
	
	return (" " + Def.STATUS_SEP + " ").join(text)


static func get_cost_text(_cost : Transaction) -> String:
	var text : PackedStringArray = PackedStringArray()
	
	for i: String in Term.ResourceType:
		var resource_type  : Term.ResourceType = Term.ResourceType[i]
		var resource_name  : String = Def._convert_resource_type_to_name(resource_type)
		var resource_value : int = _cost.get_resource_amount(resource_type)
		
		if resource_value > 0:
			text.append(str(resource_value) + " " + resource_name)
	
	return  (" " + Def.STATUS_SEP + " ").join(text)
