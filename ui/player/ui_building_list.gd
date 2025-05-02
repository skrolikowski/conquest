extends PanelContainer
class_name UIBuildingList

@onready var building_list := %BuildingList as Tree
@onready var btn_close : Button = %BtnClose as Button

var colony : CenterBuilding : set = _set_colony


func _ready() -> void:
	building_list.connect("item_selected", _on_building_list_item_selected)
	
	btn_close.connect("pressed", _on_close_pressed)


func _on_building_list_item_selected() -> void:
	var selected : TreeItem = building_list.get_selected()
	var building : Building = selected.get_metadata(0) as Building
	
	# -- Center on building and highlight..
	Def.get_world_selector().set_selected(building)
	Def.get_world().world_camera.position = building.global_position + Vector2(100, 0)


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
		child.set_metadata(0, node)

		if node.building_state == Term.BuildingState.NEW:
			child.set_text(1, "+")
			child.set_tooltip_text(1, "New")
		elif node.building_state == Term.BuildingState.UPGRADE:
			child.set_text(1, "^")
			child.set_tooltip_text(1, "Upgrade")


func _on_close_pressed() -> void:
	Def.get_world_canvas().close_sub_ui(self)
