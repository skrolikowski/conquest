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
	%BuildingList.hide_root = true
	# root.set_text(0, "Buildings")

	var nodes : Array[Building] = colony.get_buildings_sorted_by_building_type()
	for node : Building in nodes:
		var child : TreeItem = %BuildingList.create_item(root)
		child.set_text(0, node.title)


func _on_close_pressed() -> void:
	Def.get_world_canvas().close_sub_ui(self)
