extends PanelContainer
class_name UIBuilding

@onready var btn_demolish : CheckBox = %BtnDemolish as CheckBox
@onready var btn_upgrade  : CheckBox = %BtnUpgrade as CheckBox
@onready var btn_refund   : Button = %BtnRefund as Button
@onready var btn_close    : Button = %BtnClose as Button

@onready var action_container := %ActionContainer as HBoxContainer

var building       : Building : set = _set_building
var building_state : Term.BuildingState


func _ready() -> void:
	btn_close.connect("pressed", _on_close_pressed)
	
	btn_demolish.connect("toggled", _on_building_demolish_toggled)
	btn_upgrade.connect("toggled", _on_building_upgrade_toggled)
	btn_refund.connect("pressed", _on_building_refund_pressed)


func refresh_ui() -> void:
	btn_demolish.disabled = not building.can_demolish()
	btn_upgrade.disabled  = not building.can_upgrade()

	if building.building_state == Term.BuildingState.NEW:
		action_container.hide()
	else:
		action_container.show()


func _set_building(_building: Building) -> void:
	building = _building
	building_state = building.building_state
	
	%BuildingTitle.text = building.title
	%ColonyTitle.text   = "Colony: " + building.colony.title
	
	
	if building_state == Term.BuildingState.NEW:
		%BuildingLevel.text = "Level: 0"
		btn_refund.show()
	else:
		%BuildingLevel.text = "Level: " + str(building.level)
		btn_refund.hide()

	refresh_ui()


func _on_building_refund_pressed() -> void:
	building.colony.sell_building(building)
	WorldService.get_world_canvas().close_all_ui()


func _on_building_demolish_toggled(toggled_on:bool) -> void:
	if toggled_on:
		building.building_state = Term.BuildingState.SELL
	else:
		building.building_state = building_state
	
	refresh_ui()


func _on_building_upgrade_toggled(toggled_on:bool) -> void:
	if toggled_on:
		building.building_state = Term.BuildingState.UPGRADE
	else:
		building.building_state = building_state
		
	refresh_ui()


func _on_close_pressed() -> void:
	WorldService.get_world_canvas().close_all_ui()
