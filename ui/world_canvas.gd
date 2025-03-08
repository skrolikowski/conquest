extends CanvasLayer
class_name WorldCanvas

signal end_turn
signal camera_zoom(_direction:int)

@onready var confirm      := %ConfirmationDialog as ConfirmationDialog
@onready var btn_close    := %BtnCloseUI as Button
@onready var btn_zoom_in  := %BtnZoomIn as Button
@onready var btn_zoom_out := %BtnZoomOut as Button
@onready var btn_end_turn := %BtnEndTurn as Button
@onready var btn_menu     := %BtnMenu as Button

var current_ui     : PanelContainer
var current_sub_ui : Array[PanelContainer] = []
# var current_unit_list_ui : PanelContainer

var turn_number : int : set = _set_turn_number


func _ready() -> void:
	btn_zoom_in.connect("pressed", _on_zoom_in_pressed)
	btn_zoom_out.connect("pressed", _on_zoom_out_pressed)
	# btn_close.connect("pressed", _on_close_ui_pressed)
	btn_menu.connect("pressed", _on_menu_pressed)
	
	if Def.CONFIRM_END_TURN_ENABLED:
		btn_end_turn.connect("pressed", _on_end_turn_pressed)
	else:
		btn_end_turn.connect("pressed", _on_end_turn_confirmed)
	
	#TODO:
	%UnitList.disabled = true
	#%UnitList.connect("pressed", _on_unit_list_pressed)
	
	#TODO:
	%Next.disabled = true
	#%Next.connect("pressed", _on_next_pressed)


func _set_turn_number(_value: int) -> void:
	%TurnNumber.text = "Turn: " + str(_value)


#func _process(_delta: float) -> void:
	#close_btn.visible = current_ui.size() > 0


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
# func _on_close_ui_pressed() -> void:
# 	close_all_ui()


func close_all_ui() -> void:
	if current_ui != null:
		%Panels.remove_child(current_ui)
		current_ui.queue_free()

	for ui: PanelContainer in current_sub_ui:
		%Panels.remove_child(ui)
		ui.queue_free()

	current_ui     = null
	current_sub_ui = []


func close_all_sub_ui() -> void:
	for ui: PanelContainer in current_sub_ui:
		%Panels.remove_child(ui)
		ui.queue_free()

	current_sub_ui = []


func close_sub_ui(_ui: PanelContainer) -> void:
	if current_sub_ui.has(_ui):
		current_sub_ui.erase(_ui)
		%Panels.remove_child(_ui)
		_ui.queue_free()

#endregion


#region BLOCKER
func block_other_ui(_ui: PanelContainer) -> void:
	if current_ui != null and current_ui != _ui:
		_add_blocker(current_ui)

	for ui : PanelContainer in current_sub_ui:
		if ui != _ui:
			_add_blocker(ui)


func unblock_all_ui() -> void:
	if current_ui != null:
		_remove_blocker(current_ui)

	for ui : PanelContainer in current_sub_ui:
		_remove_blocker(ui)


func _add_blocker(_ui: PanelContainer) -> void:
	var blocker : PanelContainer = PanelContainer.new()
	blocker.name = "Blocker"
	_ui.add_child(blocker)


func _remove_blocker(_ui: PanelContainer) -> void:
	var blocker : PanelContainer = _ui.get_node("Blocker") as PanelContainer
	if blocker:
		_ui.remove_child(blocker)
		blocker.queue_free()

#endregion


#region CENTER BUILDING MENUS
func open_colony_build_building_menu(_building: CenterBuilding) -> void:
	# [SUB UI]
	# --
	close_all_sub_ui()

	# --
	var ui : UIBuildBuilding = Preload.ui_build_building_scene.instantiate() as UIBuildBuilding
	ui.colony = _building
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)

	current_sub_ui.append(ui)
	
	
func open_colony_population_detail(_building: CenterBuilding) -> void:
	# [SUB UI]
	# --
	close_all_sub_ui()
	
	# --
	var ui : UIPopulationDetail = Preload.ui_pop_detail_scene.instantiate() as UIPopulationDetail
	ui.colony = _building
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)
	
	current_sub_ui.append(ui)


func open_colony_commodity_detail(_building: CenterBuilding) -> void:
	# [SUB UI]
	# --
	close_all_sub_ui()

	# --
	var ui : UICommodityDetails = Preload.ui_commodity_detail_scene.instantiate() as UICommodityDetails
	ui.colony = _building

	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)

	current_sub_ui.append(ui)


func open_colony_building_list(_building: CenterBuilding) -> void:
	# [SUB UI]
	# --
	close_all_sub_ui()
	
	# --
	var ui : UIBuildingList = Preload.ui_building_list_scene.instantiate() as UIBuildingList
	ui.colony = _building
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)

	current_sub_ui.append(ui)


func open_found_colony_menu(_cm: ColonyManager) -> void:
	# [MAIN UI]
	# --
	close_all_ui()

	var ui : UIFoundColony = Preload.ui_found_colony_scene.instantiate() as UIFoundColony
	ui.colony_manager = _cm
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)

	current_ui = ui

#endregion


#region BUILDING MENUS
func open_building_menu(_building: Building) -> void:
	# [MAIN UI]
	# --
	close_all_ui()

	var scene : PackedScene = Def.get_ui_building_scene_by_type(_building.building_type)
	var ui    : PanelContainer = scene.instantiate() as PanelContainer
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)
	
	ui.building = _building
	current_ui = ui


func open_building_unit_list(_building: CenterBuilding) -> void:
	# [SUB UI]
	# --
	close_all_sub_ui()
	
	var ui : UIBuildingUnitList = Preload.ui_building_unit_list_scene.instantiate() as UIBuildingUnitList
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)
	
	ui.building = _building
	current_sub_ui.append(ui)
	# current_unit_list_ui = ui


func refresh_current_building_ui() -> void:
	if current_ui != null:
		"""
		Note: reset the ui to itself to trigger the refresh function
		"""
		if current_ui.building != null:
			current_ui.building = current_ui.building
		elif current_ui.unit != null:
			current_ui.unit = current_ui.unit

#endregion


#region UNIT MENUS
func open_unit_menu(_unit: Unit) -> void:
	# [MAIN UI]
	# --
	close_all_ui()

	var scene : PackedScene = Def.get_ui_unit_scene_by_type(_unit.stat.unit_type)
	var ui    : PanelContainer = scene.instantiate() as PanelContainer
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)
	
	ui.unit = _unit
	current_ui = ui


func open_carrier_unit_list(_unit: Unit) -> void:
	# [SUB UI]
	# --
	close_all_sub_ui()
	
	var scene : PackedScene = Preload.ui_carrier_unit_list_scene
	var ui : UICarrierUnitList = scene.instantiate() as UICarrierUnitList
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)

	ui.carrier = _unit
	current_sub_ui.append(ui)
	# current_unit_list_ui = ui


func open_create_leader_unit_menu(_building: CenterBuilding, _leader: UnitStats) -> void:
	var ui : UICreateLeaderUnit = Preload.ui_create_leader_scene.instantiate() as UICreateLeaderUnit
	current_ui.append(ui)

	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)
	
	ui.building = _building
	ui.leader = _leader


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
