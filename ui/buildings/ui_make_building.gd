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
	var total_modifier : float = make_building.get_total_production_modifier()
	if total_modifier > 0.0:
		%Modifier.text = "Modifier: " + str(int(total_modifier * 100)) + "%"
		
		var special_modifier  : float = building.get_specialized_industry_modifier()
		var artifact_modifier : float = building.artifact_modifier
		
		if special_modifier > 0.0:
			%Modifier.text += " (+" + str(int(special_modifier * 100)) + "%)"
			
		if artifact_modifier > 0.0:
			%Modifier.text += " [+" + str(int(artifact_modifier * 100)) + "%]"
	else:
		%Modifier.text = "Modifier: None"
