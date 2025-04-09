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
	var total_population      : int = colony.get_total_population()

	var unit_population      : int = colony.get_unit_population()
	var next_unit_population : int = colony.get_next_unit_population()
	# var next_total_population : int = colony.get_total_population() + colony.get_immigration()

	var labor_demand      : int = colony.get_labor_demand()
	var free_labor        : int = colony.get_free_labor()
	var next_labor_demand : int = colony.get_next_labor_demand()

	%ColonyTitle.text = colony.title

	%BasePopulationValue.text  = str(base_population)
	%TotalPopulationValue.text = str(total_population)
	%UnitPopulationValue.text  = str(unit_population)
	%MaxPopulationValue.text   = str(max_population)
	%LaborDemandValue.text     = str(labor_demand)
	%FreeLaborValue.text       = str(free_labor)
	
	if immigration > 0:
		%ImmigrationValue.text = "(+" + str(immigration) + ")"
	elif immigration < 0:
		%ImmigrationValue.text = "(" + str(immigration) + ")"
	else:
		%ImmigrationValue.text = "(+0)"
	
	if next_unit_population > 0:
		%UnitPopulationNextValue.text = "(+" + str(next_unit_population) + ")"
	elif next_unit_population < 0:
		%UnitPopulationNextValue.text = "(" + str(next_unit_population) + ")"
	else:
		%UnitPopulationNextValue.text = "(+0)"
	
	if next_max_population > 0:
		%MaxPopulationNextValue.text  = "(+" + str(next_max_population) + ")"
	elif next_max_population < 0:
		%MaxPopulationNextValue.text  = "(" + str(next_max_population) + ")"
	else:
		%MaxPopulationNextValue.text  = "(+0)"

	if next_labor_demand > 0:
		%LaborDemandNextValue.text = "(+" + str(next_labor_demand) + ")"
	elif next_labor_demand < 0:
		%LaborDemandNextValue.text = "(" + str(next_labor_demand) + ")"
	else:
		%LaborDemandNextValue.text = "(+0)"
	
	# -- Crops needed..
	var crops_needed : int = colony.get_crops_needed()
	%CropsNeededValue.text = str(crops_needed)

	# -- Colony message..
	if colony.is_starving():
		%ColonyMessage.text = "Colony is starving!"
	elif base_population > max_population:
		%ColonyMessage.text = "Housing Shortage."
	elif colony.is_at_max_population():
		%ColonyMessage.text = "Colony at maximum capacity."

	else:
		# -- Immigration message..
		var immigration_bonus : int = colony.get_immigration_bonus()
		if immigration_bonus > 0:
			%ColonyMessage.text = "Church Immigration Bonus: " + str(immigration_bonus)
		else:
			%ColonyMessage.text = "Colony Immigration Normal."


func _on_close_pressed() -> void:
	Def.get_world_canvas().close_sub_ui(self)
