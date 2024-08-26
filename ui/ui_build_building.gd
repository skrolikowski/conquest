extends PanelContainer
class_name UIBuildBuilding

var colony : CenterBuilding : set = _set_colony


func _set_colony(_building: CenterBuilding) -> void:
	colony = _building


func _ready() -> void:
	for i:String in Term.BuildingType:
		var building_type : Term.BuildingType = Term.BuildingType[i]
		if building_type == Term.BuildingType.NONE or building_type == Term.BuildingType.CENTER:
			continue
			
		create_button(building_type)
		
		
func create_button(_building_type : Term.BuildingType) -> void:
	var build_button : Button = Button.new()
	build_button.text = Def._convert_building_type_to_name(_building_type)
	
	var build_cost : Transaction = Def.get_building_cost(_building_type)
	if colony.bank.can_afford_this_turn(build_cost):
		build_button.connect("pressed", _on_button_pressed.bind(_building_type))
	else:
		build_button.disabled = true
	
	build_button.connect("mouse_entered", _on_button_entered.bind(_building_type))
	build_button.connect("mouse_exited", _on_button_exited)
	
	%BuildingButtons.add_child(build_button)


func _on_button_pressed(_building_type: Term.BuildingType) -> void:
	colony.create_building(_building_type)

	Def.get_world_canvas().close_all_ui()
	Def.get_world().unselect_all()


func _on_button_entered(_building_type: Term.BuildingType) -> void:
	Def.get_world_canvas().update_status(Print.build_building_type(_building_type))


func _on_button_exited() -> void:
	Def.get_world_canvas().clear_status()
