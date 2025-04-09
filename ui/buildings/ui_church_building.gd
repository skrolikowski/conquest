extends UIBuilding
class_name UIChurchBuilding

@onready var production_container := %Production as VBoxContainer

func _set_building(_building: Building) -> void:
	super._set_building(_building)
	
	# --
	refresh_ui()


func refresh_ui() -> void:
	super.refresh_ui()
	
	var church_building : ChurchBuilding = building as ChurchBuilding
	
	# -- Production
	if church_building.building_state == Term.BuildingState.NEW:
		production_container.hide()
	else:
		production_container.show()
		
		%ThisBuildingValue.text = str(church_building.get_immigration_bonus())
		%AllBuildingsValue.text = str(church_building.colony.get_immigration())
