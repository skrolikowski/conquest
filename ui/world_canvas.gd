extends CanvasLayer
class_name WorldCanvas


signal end_turn
signal camera_zoom(_direction:int)

@onready var confirm       := %ConfirmationDialog as ConfirmationDialog
@onready var btn_diplomacy := %BtnDiplomacy as Button
@onready var btn_unit_list := %BtnUnitList as Button
@onready var btn_next      := %BtnNext as Button
@onready var btn_close     := %BtnCloseUI as Button
@onready var btn_zoom_in   := %BtnZoomIn as Button
@onready var btn_zoom_out  := %BtnZoomOut as Button
@onready var btn_end_turn  := %BtnEndTurn as Button
@onready var btn_menu      := %BtnMenu as Button

@export var world_manager : WorldManager

var current_ui     : PanelContainer
var locking_ui     : PanelContainer
var current_sub_ui : Array[PanelContainer] = []
# var current_unit_list_ui : PanelContainer

var turn_number : int : set = _set_turn_number


func _ready() -> void:
	btn_zoom_in.connect("pressed", _on_zoom_in_pressed)
	btn_zoom_out.connect("pressed", _on_zoom_out_pressed)
	# btn_close.connect("pressed", _on_close_ui_pressed)
	btn_menu.connect("pressed", _on_menu_pressed)
	
	btn_diplomacy.connect("pressed", _on_diplomacy_pressed)
	
	if Preload.C.CONFIRM_END_TURN_ENABLED:
		btn_end_turn.connect("pressed", _on_end_turn_pressed)
	else:
		btn_end_turn.connect("pressed", _on_end_turn_confirmed)
	
	#TODO:
	btn_unit_list.disabled = true
	#btn_unit_list.connect("pressed", _on_unit_list_pressed)
	
	#TODO:
	btn_next.disabled = true
	#btn_next.connect("pressed", _on_next_pressed)


func _set_turn_number(_value: int) -> void:
	%TurnNumber.text = "Turn: " + str(_value)


#func _process(_delta: float) -> void:
	#close_btn.visible = current_ui.size() > 0


func _on_diplomacy_pressed() -> void:
	open_diplomacy_menu()


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
func close_all_ui() -> void:
	if current_ui != null:
		%Panels.remove_child(current_ui)
		current_ui.queue_free()

	for ui: PanelContainer in current_sub_ui:
		%Panels.remove_child(ui)
		ui.queue_free()

	current_ui     = null
	locking_ui	   = null
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


func open_found_colony_menu(_colony_manager: ColonyManager) -> void:
	# [MAIN UI]
	# --
	close_all_ui()

	var ui : UIFoundColony = Preload.ui_found_colony_scene.instantiate() as UIFoundColony
	ui.colony_manager = _colony_manager
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)

	current_ui = ui
	locking_ui = ui

#endregion


#region NPC MENUS
func open_village_menu(_village: Village) -> void:
	# [MAIN UI]
	# --
	close_all_ui()

	var scene : PackedScene = Preload.ui_village_scene
	var ui    : PanelContainer = scene.instantiate() as PanelContainer
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)
	
	ui.village = _village
	current_ui = ui
#endregion


#region DIPLOMACY MENUS
func open_diplomacy_menu() -> void:
	# [MAIN UI]
	# --
	close_all_ui()

	var scene : PackedScene = Preload.ui_diplomacy_scene
	var ui    : PanelContainer = scene.instantiate() as PanelContainer
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)
	
	current_ui = ui

#endregion


#region TRADE MENUS
func open_trade_menu(_colony:CenterBuilding) -> void:
	# [MAIN UI]
	# --
	close_all_sub_ui()

	var scene : PackedScene = Preload.ui_trade_scene
	var ui    : PanelContainer = scene.instantiate() as PanelContainer
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)
	
	ui.player = world_manager.turn_orchestrator.player
	ui.colony = _colony
	current_sub_ui.append(ui)


func open_new_trade_menu(_colony:CenterBuilding) -> void:
	# [SUB UI]
	# --
	# close_all_sub_ui()

	var scene : PackedScene = Preload.ui_new_trade_scene
	var ui    : PanelContainer = scene.instantiate() as PanelContainer
	
	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)
	
	ui.colony = _colony
	ui.player = world_manager.turn_orchestrator.player
	current_sub_ui.append(ui)

#endregion


#region BUILDING MENUS
func open_building_menu(_building: Building) -> void:
	# [MAIN UI]
	# --
	close_all_ui()

	var scene : PackedScene = PreloadsRef.get_building_ui_scene(_building.building_type)
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

#endregion


#region UNIT MENUS
func open_unit_menu(_unit: Unit) -> void:
	# [MAIN UI]
	# --
	close_all_ui()

	var scene : PackedScene = PreloadsRef.get_unit_ui_scene(_unit.stat.unit_type)
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


func open_create_leader_unit_menu(_building: CenterBuilding, _leader: UnitStats) -> void:
	# [SUB UI]
	# --
	close_all_sub_ui()
	
	var scene : PackedScene = Preload.ui_create_leader_scene
	var ui    : UICreateLeaderUnit = scene.instantiate() as UICreateLeaderUnit

	%Panels.add_child(ui)
	%Panels.move_child(ui, 0)
	
	ui.building = _building
	ui.leader = _leader
	current_sub_ui.append(ui)

#endregion


#region REFRESH UI
func refresh_current_ui() -> void:
	if current_ui != null and current_ui.has_method("refresh_ui"):
		current_ui.refresh_ui()

	for ui : PanelContainer in current_sub_ui:
		if ui.has_method("refresh_ui"):
			ui.refresh_ui()

#endregion


#region STATUS INFORMATION
func update_status(_status: String) -> void:
	%StatusInformation.text = _status


func clear_status() -> void:
	%StatusInformation.text = ""


func update_tile_status(_status: String) -> void:
	%TileStatus.text = _status


func update_tile_focus(tile_info: Dictionary) -> void:
	"""
	Update tile status display from tile information dictionary
	Handles formatting of tile data for display
	"""
	var tile_status: PackedStringArray = PackedStringArray()

	# Position
	if tile_info.has("position"):
		tile_status.append(str(tile_info["position"]))

	# Height
	if tile_info.has("height"):
		tile_status.append(str(snapped(tile_info["height"], 0.01)))

	# TileData
	if tile_info.has("tile_data"):
		var tile_data:TileCustomData = tile_info["tile_data"]
		# tile_status.append("Biome: " + Preload.TR.biome_to_name(tile_data.biome))
		# if tile_data.is_water:
		# 	tile_status.append("Water Tile")
		# else:
		# 	tile_status.append("Land Tile")
		if tile_data.is_shore:
			tile_status.append("Shore")
		elif tile_data.is_ocean:
			tile_status.append("Ocean")
		elif tile_data.is_river:
			tile_status.append("River")
			
		if tile_data.has_ocean_access:
			tile_status.append("(OA)")

	# Industry modifiers
	if tile_info.has("modifiers") and tile_info["modifiers"].size() > 0:
		var mod_data: Dictionary = tile_info["modifiers"]
		var mod_text: PackedStringArray = PackedStringArray()
		mod_text.append("Farm: " + str(mod_data[Term.IndustryType.FARM]) + "%")
		mod_text.append("Mill: " + str(mod_data[Term.IndustryType.MILL]) + "%")
		mod_text.append("Mine: " + str(mod_data[Term.IndustryType.MINE]) + "%")
		tile_status.append(", ".join(mod_text))

	update_tile_status(Preload.C.STATUS_SEP.join(tile_status))


func clear_tile_status() -> void:
	%TileStatus.text = ""

#endregion
