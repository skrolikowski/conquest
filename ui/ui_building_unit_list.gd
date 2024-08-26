extends PanelContainer
class_name UIBuildingUnitList

var building : CenterBuilding : set = _set_building


func _ready() -> void:
	%UnitList.connect("item_selected", _on_unit_selected)
	%DetachSelected.connect("pressed", _on_detach_unit_pressed)


func _on_unit_selected() -> void:
	var tree_item : TreeItem = %UnitList.get_selected()
	%DetachSelected.disabled = tree_item == null
	

func _on_detach_unit_pressed() -> void:
	var tree_item : TreeItem = %UnitList.get_selected()
	if tree_item == null:
		return
#
	var unit_stat : UnitStats = tree_item.get_metadata(0) as UnitStats
	if unit_stat == null:
		return

	building.detach_unit(unit_stat)
	%UnitList.remove_tree_item(tree_item)


func _set_building(_building: CenterBuilding) -> void:
	building = _building

	%BuildingTitle.text = building.title
	
	# -- Nothing selected..
	%DetachSelected.disabled = true
	
	# -- Create Tree root..
	var root : TreeItem = %UnitList.create_item()
	%UnitList.hide_root = true
	%UnitList.columns = 1
	root.set_text(0, "Units")

	# -- Unit List..
	var unit_stats : Array[UnitStats] = building.get_units_sorted_by_unit_type()
	for unit_stat : UnitStats in unit_stats:
		var tree_item : TreeItem = %UnitList.create_item(root)
		tree_item.set_text(0, unit_stat.title + " (" + str(unit_stat.level) + ")")
		tree_item.set_metadata(0, unit_stat)
		
