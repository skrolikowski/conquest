extends CanvasLayer
class_name WorldCanvas

signal end_turn
signal camera_zoom(_direction:int)

@onready var confirm := %ConfirmationDialog as ConfirmationDialog
@onready var close_btn := %CloseUI as Button

var current_ui : Array[PanelContainer] = []
var current_unit_list_ui : PanelContainer


func _ready() -> void:
	%ZoomIn.connect("pressed", _on_zoom_in_pressed)
	%ZoomOut.connect("pressed", _on_zoom_out_pressed)
	close_btn.connect("pressed", _on_close_ui_pressed)
	%Menu.connect("pressed", _on_menu_pressed)
	
	if Def.CONFIRM_END_TURN_ENABLED:
		%EndTurn.connect("pressed", _on_end_turn_pressed)
	else:
		%EndTurn.connect("pressed", _on_end_turn_confirmed)
	
	#TODO:
	%UnitList.disabled = true
	#%UnitList.connect("pressed", _on_unit_list_pressed)
	
	#TODO:
	%Next.disabled = true
	#%Next.connect("pressed", _on_next_pressed)


func _process(_delta: float) -> void:
	close_btn.visible = current_ui.size() > 0


func _on_end_turn_confirmed() -> void:
	end_turn.emit()


func _on_end_turn_pressed() -> void:
	confirm.confirmed.connect(_on_end_turn_confirmed, CONNECT_ONE_SHOT)
	confirm.dialog_text = "Are you sure?"
	confirm.visible = true
	

func _on_unit_list_pressed() -> void:
	#TODO: open player unit list ui
	pass


func _on_zoom_in_pressed() -> void:
	camera_zoom.emit(1)


func _on_zoom_out_pressed() -> void:
	camera_zoom.emit(-1)


func _on_next_pressed() -> void:
	#TODO: cycle through Player's Units on map (w/ move points > 0)
	#TODO: cycle through Player's CenterBuildings
	pass


func _on_menu_pressed() -> void:
	%GameMenu.visible = not %GameMenu.visible


#region CLOSE UI
func _on_close_ui_pressed() -> void:
	close_all_ui()


func close_all_ui() -> void:
	for ui:PanelContainer in current_ui:
		%Panels.remove_child(ui)
		ui.queue_free()
	
	current_ui = []


func close_last_ui() -> void:
	if current_ui.size() > 0:
		var ui:PanelContainer = current_ui.pop_back()
		%Panels.remove_child(ui)
		ui.queue_free()
		

func close_ui(_ui:PanelContainer) -> void:
	if current_ui.has(_ui):
		current_ui.erase(_ui)
		%Panels.remove_child(_ui)
		_ui.queue_free()

#endregion


#region CENTER BUILDING MENUS
func open_colony_build_building_menu(_building: CenterBuilding) -> void:
	
	# --
	for ui: PanelContainer in current_ui:
		if ui is UIBuildBuilding:
			close_ui(ui)
			break
	
	# --
	var ui : UIBuildBuilding = Preload.ui_build_building_scene.instantiate() as UIBuildBuilding
	ui.colony = _building

	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)

	current_ui.append(ui)


func open_colony_population_detail(_building: CenterBuilding) -> void:
	
	# --
	for ui: PanelContainer in current_ui:
		if ui is UIPopulationDetail:
			close_ui(ui)
			break
	
	# --
	var ui : UIPopulationDetail = Preload.ui_pop_detail_scene.instantiate() as UIPopulationDetail
	ui.colony = _building
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)
	
	current_ui.append(ui)


func open_colony_commodity_detail(_building: CenterBuilding) -> void:
	
	# --
	for ui: PanelContainer in current_ui:
		if ui is UICommodityDetails:
			close_ui(ui)
			break

	# --
	var ui : UICommodityDetails = Preload.ui_commodity_detail_scene.instantiate() as UICommodityDetails
	ui.colony = _building

	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)

	current_ui.append(ui)


func open_colony_building_list(_building: CenterBuilding) -> void:
	
	# --
	for ui: PanelContainer in current_ui:
		if ui is UIBuildingList:
			close_ui(ui)
			break
	
	# --
	var ui : UIBuildingList = Preload.ui_building_list_scene.instantiate() as UIBuildingList
	ui.colony = _building
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)

	current_ui.append(ui)


func open_found_colony_menu(_cm: ColonyManager) -> void:
	close_all_ui()
	# --

	var ui : UIFoundColony = Preload.ui_found_colony_scene.instantiate() as UIFoundColony
	ui.colony_manager = _cm
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)

	current_ui.append(ui)

#endregion


func open_building_menu(_building: Building) -> void:
	close_all_ui()
	# --

	var scene : PackedScene = Def.get_ui_building_scene_by_type(_building.building_type)
	var ui    : PanelContainer = scene.instantiate() as PanelContainer
	ui.building = _building
		
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)

	current_ui.append(ui)


func open_building_unit_list(_building: CenterBuilding) -> void:
	var ui : UIBuildingUnitList = Preload.ui_building_unit_list_scene.instantiate() as UIBuildingUnitList
	ui.building = _building
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)

	current_ui.append(ui)
	current_unit_list_ui = ui


#region UNIT MENUS
func open_unit_menu(_unit: Unit) -> void:
	close_all_ui()
	# --

	var scene : PackedScene = Def.get_ui_unit_scene_by_type(_unit.stat.unit_type)
	var ui    : PanelContainer = scene.instantiate() as PanelContainer
	ui.unit = _unit
		
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)
	
	current_ui.append(ui)


func open_carrier_unit_list(_unit: Unit) -> void:
	var ui : UICarrierUnitList = Preload.ui_carrier_unit_list_scene.instantiate() as UICarrierUnitList
	ui.carrier = _unit
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)

	current_ui.append(ui)
	current_unit_list_ui = ui

#endregion


#region STATUS INFORMATION
func update_status(_status: String) -> void:
	%StatusInformation.text = _status


func clear_status() -> void:
	%StatusInformation.text = ""


func update_tile_status(_status: String) -> void:
	%TileStatus.text = _status


func clear_tile_status() -> void:
	%TileStatus.text = ""

#endregion
