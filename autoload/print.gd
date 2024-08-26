extends Node2D
class_name PrintRef


static func build_building_type(_building_type: Term.BuildingType) -> String:
	var text : PackedStringArray = PackedStringArray()

	# -- Building name..
	var building_name : String = Def._convert_building_type_to_name(_building_type)
	text.append(building_name)
	
	# -- Building cost..
	var building_cost : Transaction = Def.get_building_cost(_building_type, 1)
	var cost_text     : PackedStringArray = PackedStringArray()

	for i: String in Term.ResourceType:
		var resource_type  : Term.ResourceType = Term.ResourceType[i]
		var resource_name  : String = Def._convert_resource_type_to_name(resource_type)
		var resource_value : int = building_cost.get_resource_amount(resource_type)
		
		if resource_value > 0:
			cost_text.append(str(resource_value) + " " + resource_name)
	
	text.append("Cost: " + ", ".join(cost_text))
	
	# -- Labor demand..
	var labor_demand : int = Def.get_building_labor_demand(_building_type, 1)
	if labor_demand > 0:
		text.append("Labor: +" + str(labor_demand))

	return (" " + Def.STATUS_SEP + " ").join(text)
