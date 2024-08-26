extends UIBuilding
class_name UITavernBuilding

@onready var recruit_explorer : CheckBox = %RecruitExplorerp as CheckBox


func _ready() -> void:
	recruit_explorer.connect("toggled", _on_recruit_explorer_toggled)


func _set_building(_building: Building) -> void:
	super._set_building(_building)
	
	
	# -- Tavern Building Data
	_building = _building as TavernBuilding

	var unit_count    : int = _building.colony.get_explorer_unit_count()
	var unit_capacity : int = _building.colony.get_max_explorer_unit_count()
	%ExplorerCountValue.text = "Explorer Count: " + str(unit_count) + "/" + str(unit_capacity)
	
	# -- Recruit Explorer
	recruit_explorer.disabled = not _building.can_recruit_explorer()


func refresh_ui() -> void:
	super.refresh_ui()
	
	building = building as TavernBuilding
	
	recruit_explorer.disabled = not building.can_recruit_explorer()


func _on_recruit_explorer_toggled(toggled_on : bool) -> void:
	building = building as TavernBuilding

	if toggled_on:
		building.recruit_explorer = true
		building.building_state = Term.BuildingState.TRAIN
	else:
		building.recruit_explorer = false
		building.building_state = Term.BuildingState.ACTIVE
		
	refresh_ui()
