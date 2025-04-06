extends PanelContainer
class_name UIBuildingList

@onready var btn_close : Button = %BtnClose as Button

var colony : CenterBuilding : set = _set_colony


func _ready() -> void:
	btn_close.connect("pressed", _on_close_pressed)


func _set_colony(_building: CenterBuilding) -> void:
	colony = _building
	
	%ColonyTitle.text = colony.title
	
	# -- Building List
	var root : TreeItem = %BuildingList.create_item()
	# root.set_text(0, "Buildings")
	%BuildingList.hide_root = true
	%BuildingList.columns = 2
	%BuildingList.set_column_custom_minimum_width(0, 150)

	var nodes : Array[Building] = colony.get_buildings_sorted_by_building_type()
	for node : Building in nodes:
		var child : TreeItem = %BuildingList.create_item(root)
		child.set_text(0, node.title)

		if node.building_state == Term.BuildingState.NEW:
			child.set_text(1, "+")
		elif node.building_state == Term.BuildingState.UPGRADE:
			child.set_text(1, "^")


func _on_close_pressed() -> void:
	Def.get_world_canvas().close_sub_ui(self)
