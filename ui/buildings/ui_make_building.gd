extends UIBuilding
class_name UIMakeBuilding


func _set_building(_building: Building) -> void:
	super._set_building(_building)


	# -- Make Building Data
	_building = _building as MakeBuilding
	
	if _building.building_state == Term.BuildingState.NEW:
		%Production.hide()
	else:
		%Production.show()

		%ThisBuildingValue.text = str(_building.get_expected_produce_value())
		%AllBuildingsValue.text = str(_building.colony.get_expected_produce_value_by_building_type(_building.building_type))
		%StockpileValue.text    = str(_building.colony.bank.get_resource_value(_building.make_resource_type))
	
	# Modifier
	refresh_modifier()


func refresh_modifier() -> void:
	var make_building : MakeBuilding = building as MakeBuilding

	# -- Modifier
	var total_modifier : int = make_building.get_total_production_modifier()
	if total_modifier > 0:
		%Modifier.text = "Modifier: " + str(total_modifier) + "%"
		
		var special_modifier  : int = make_building.get_specialized_industry_modifier()
		var artifact_modifier : int = make_building.get_artifact_modifier()
		
		if special_modifier > 0:
			%Modifier.text += " (+" + str(special_modifier) + "%)"
			
		if artifact_modifier > 0:
			%Modifier.text += " [+" + str(artifact_modifier) + "%]"
	else:
		%Modifier.text = "Modifier: None"
