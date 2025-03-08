extends PanelContainer
class_name UIBuilding

@onready var btn_close : Button = %BtnClose as Button

var building       : Building : set = _set_building
var building_state : Term.BuildingState


func _ready() -> void:
	btn_close.connect("pressed", _on_close_pressed)
	
	%BuildingDemolish.connect("toggled", _on_building_demolish_toggled)
	%BuildingUpgrade.connect("toggled", _on_building_upgrade_toggled)
	%BuildingRefund.connect("pressed", _on_building_refund_pressed)


func refresh_ui() -> void:
	%BuildingDemolish.disabled = not building.can_demolish()
	%BuildingUpgrade.disabled  = not building.can_upgrade()


func _set_building(_building: Building) -> void:
	building = _building
	building_state = building.building_state
	
	%BuildingTitle.text = building.title
	%ColonyTitle.text   = "Colony: " + building.colony.title
	%BuildingLevel.text = "Level: " + str(building.level)
	
	if building_state == Term.BuildingState.NEW:
		%BuildingRefund.show()
	else:
		%BuildingRefund.hide()

	refresh_ui()


func _on_building_refund_pressed() -> void:
	building.colony.sell_building(building)
	Def.get_world_canvas().close_all_ui()


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
	Def.get_world_canvas().close_all_ui()
