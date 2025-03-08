extends PanelContainer
class_name UIPopulationDetail

@onready var btn_close : Button = %BtnClose as Button

var colony : CenterBuilding : set = _set_colony


func _ready() -> void:
	btn_close.connect("pressed", _on_close_pressed)


func _set_colony(_building : CenterBuilding) -> void:
	colony = _building
	
	var base_population       : int = colony.population
	var immigration           : int = colony.get_immigration()
	var max_population        : int = colony.get_max_population()
	var next_max_population   : int = colony.get_next_max_population()
	# var next_total_population : int = colony.get_total_population() + colony.get_immigration()

	%ColonyTitle.text = colony.title
	
	%BasePopulationValue.text     = str(base_population)
	%UnitPopulationValue.text     = str(colony.get_unit_population())
	%UnitPopulationNextValue.text = str(colony.get_next_unit_population())
	%ImmigrationValue.text        = str(immigration)
	%TotalPopulationValue.text    = str(colony.get_total_population())
	%MaxPopulationValue.text      = str(max_population)
	%MaxPopulationNextValue.text  = str(next_max_population)

	%LaborDemandValue.text     = str(colony.get_labor_demand())
	%LaborDemandNextValue.text = str(colony.get_next_labor_demand())
	%FreeLaborValue.text       = str(colony.get_free_labor())
	
	# -- Crops needed..
	var crops_needed : int = colony.get_crops_needed()
	%CropsNeededValue.text = str(crops_needed)

	# -- Colony message..
	if colony.is_starving():
		%ColonyMessage.text = "Colony is starving!"
	elif base_population > max_population:
		%ColonyMessage.text = "Housing Shortage"
	elif colony.is_at_max_population():
		%ColonyMessage.text = "Colony at maximum capacity."

	# elif:
	# 	%ColonyMessage.text = "Church Immigration Bonus: "
	else:
		%ColonyMessage.text = "Colony Immigration Normal"


func _on_close_pressed() -> void:
	Def.get_world_canvas().close_sub_ui(self)


