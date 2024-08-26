extends PanelContainer
class_name UIBuildingList

var colony : CenterBuilding : set = _set_colony


func _set_colony(_building: CenterBuilding) -> void:
	colony = _building
	
	%ColonyTitle.text = colony.title
	
	# -- Building List
	var root : TreeItem = %BuildingList.create_item()
	%BuildingList.hide_root = false
	root.set_text(0, "Buildings")

	var nodes : Array[Node] = colony.get_buildings_sorted_by_building_type()
	for node in nodes:
		var building : Building = node as Building
		var child : TreeItem = %BuildingList.create_item(root)
		child.set_text(0, building.title)
