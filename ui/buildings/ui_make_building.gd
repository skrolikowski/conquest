extends UIBuilding
class_name UIMakeBuilding

@onready var production_container := %Production as VBoxContainer


func _set_building(_building: Building) -> void:
	super._set_building(_building)

	# --
	refresh_ui()


func refresh_ui() -> void:
	super.refresh_ui()

	# -- Make Building Data
	var make_building : MakeBuilding = building as MakeBuilding
	
	# -- Production
	%ThisBuildingValue.text = str(make_building.get_expected_produce_value())
	%AllBuildingsValue.text = str(make_building.colony.get_expected_produce_value_by_building_type(make_building.building_type))
	%StockpileValue.text    = str(make_building.colony.bank.get_resource_value(make_building.make_resource_type))
	
	# Modifier
	refresh_modifier()


func refresh_modifier() -> void:
	var make_building : MakeBuilding = building as MakeBuilding

	# -- Modifier
	if make_building.building_state == Term.BuildingState.NEW:
		var terrain_modifier : int = make_building.get_terrain_modifier()
		if terrain_modifier > 0:
			%Modifier.text = "Modifier: " + str(terrain_modifier) + "%"
		else:
			%Modifier.text = "Modifier: None"
	else:
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
