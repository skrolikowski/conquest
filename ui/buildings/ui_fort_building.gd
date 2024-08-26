extends UIBuilding
class_name UIFortBuilding

@onready var train_infantry  : CheckBox = %TrainInfantryUnit as CheckBox
@onready var train_calvary   : CheckBox = %TrainCalvaryUnit as CheckBox
@onready var train_artillary : CheckBox = %TrainArtillaryUnit as CheckBox
@onready var unit_level_selector : OptionButton = %UnitLevelSelect as OptionButton


func _ready() -> void:
	super._ready()
	
	train_infantry.connect("toggled", _on_train_infantry_toggled)
	#train_infantry.connect("mouse_entered", _on_train_infantry_mouse_entered)
	#train_infantry.connect("mouse_exited", _on_train_infantry_mouse_exited)
	
	train_calvary.connect("toggled", _on_train_calvary_toggled)
	train_artillary.connect("toggled", _on_train_artillary_toggled)
	
	unit_level_selector.connect("item_selected", _on_unit_level_selected)
	for i in range(4):
		unit_level_selector.add_item("Level " + str(i+1))


#func _on_train_infantry_mouse_entered() -> void:
	#Popups.ItemPopup(Rect2i(global_position, size), )
	#
#func _on_train_infantry_mouse_exited() -> void:
	#Popups.HideItemPopup()

func _on_unit_level_selected(index: int) -> void:
	building = building as FortBuilding
	building.train_level = index + 1


func _on_train_infantry_toggled(toggled_on:bool) -> void:
	if toggled_on:
		building.train_unit = Term.UnitType.INFANTRY
		building.building_state = Term.BuildingState.TRAIN
	else:
		building.train_unit = Term.UnitType.NONE
		building.building_state = building_state
		
	refresh_ui()


func _on_train_calvary_toggled(toggled_on:bool) -> void:
	if toggled_on:
		building.train_unit = Term.UnitType.CALVARY
		building.building_state = Term.BuildingState.TRAIN
	else:
		building.train_unit = Term.UnitType.NONE
		building.building_state = building_state
	
	refresh_ui()


func _on_train_artillary_toggled(toggled_on:bool) -> void:
	if toggled_on:
		building.train_unit = Term.UnitType.ARTILLARY
		building.building_state = Term.BuildingState.TRAIN
	else:
		building.train_unit = Term.UnitType.NONE
		building.building_state = building_state
		
	refresh_ui()


func refresh_ui() -> void:
	super.refresh_ui()
	
	train_infantry.disabled  = not building.can_train_military_unit(Term.UnitType.INFANTRY)
	train_calvary.disabled   = not building.can_train_military_unit(Term.UnitType.CALVARY)
	train_artillary.disabled = not building.can_train_military_unit(Term.UnitType.ARTILLARY)

	
func _set_building(_building: Building) -> void:
	super._set_building(_building)
	
	# --
	var unit_count    : int = building.colony.get_military_unit_count()
	var unit_capacity : int = building.colony.get_max_military_unit_count()
	%TotalArmyCount.text = "Total Army: " + str(unit_count) + " / " + str(unit_capacity)
	
	# --
	var infantry_units  : Dictionary = building.colony.get_military_unit_level_count_by_unit_type(Term.UnitType.INFANTRY)
	var calvary_units   : Dictionary = building.colony.get_military_unit_level_count_by_unit_type(Term.UnitType.CALVARY)
	var artillary_units : Dictionary = building.colony.get_military_unit_level_count_by_unit_type(Term.UnitType.ARTILLARY)
	
	%InfantryUnits1.text = str(infantry_units[1])
	%InfantryUnits2.text = str(infantry_units[2])
	%InfantryUnits3.text = str(infantry_units[3])
	%InfantryUnits4.text = str(infantry_units[4])

	%CalvaryUnits1.text = str(calvary_units[1])
	%CalvaryUnits2.text = str(calvary_units[2])
	%CalvaryUnits3.text = str(calvary_units[3])
	%CalvaryUnits4.text = str(calvary_units[4])

	%ArtillaryUnits1.text = str(artillary_units[1])
	%ArtillaryUnits2.text = str(artillary_units[2])
	%ArtillaryUnits3.text = str(artillary_units[3])
	%ArtillaryUnits4.text = str(artillary_units[4])
	
	for i in range(4):
		unit_level_selector.set_item_disabled(i, building.level < i+1)
