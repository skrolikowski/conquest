extends UIBuilding
class_name UIChurcBuilding


func _set_building(_building: Building) -> void:
	super._set_building(_building)
	
	
	# -- Church Building Data
	_building = _building as ChurchBuilding
	
	if _building.building_state == Term.BuildingState.NEW:
		%Production.hide()
	else:
		%Production.show()
		
		%ThisBuildingValue.text = str(building.get_immigration_bonus())
		%AllBuildingsValue.text = str(building.colony.get_immigration())
