extends UIBuilding
class_name UIHouseBuilding

@onready var recruit_settler : CheckBox = %RecruitSettler as CheckBox


func _ready() -> void:
	recruit_settler.connect("pressed", _on_recruit_settler_toggled)


func _set_building(_building: Building) -> void:
	super._set_building(_building)


	# -- House Building Data
	building = building as HouseBuilding

	%ThisBuildingValue.text    = str(building.get_population_capacity_value())
	%AllBuildingsValue.text    = str(building.colony.get_total_population_capacity_value(Term.BuildingType.HOUSING))
	%TotalPopulationValue.text = str(building.colony.get_total_population())

	recruit_settler.disabled = not building.can_recruit_settler()


func refresh_ui() -> void:
	super.refresh_ui()
	
	# building = building as HouseBuilding
	
	recruit_settler.disabled = not building.can_recruit_settler()


func _on_recruit_settler_toggled(toggled_on : bool) -> void:
	if toggled_on:
		building.recruit_settler = true
		building.building_state = Term.BuildingState.TRAIN
	else:
		building.recruit_settler = false
		building.building_state = building_state
		
	refresh_ui()
