extends PanelContainer
class_name UICarrierUnitList

var carrier : Unit : set = _set_carrier


func _ready() -> void:
	%UnitList.connect("item_selected", _on_unit_selected)
	%DetachSelected.connect("pressed", _on_detach_unit_pressed)


func refresh_ui() -> void:
	%DetachSelected.disabled = not can_detach_unit()


func can_detach_unit() -> bool:
	var tree_item : TreeItem = %UnitList.get_selected()
	return carrier.can_detach_unit() and tree_item != null


func _on_unit_selected() -> void:
	refresh_ui()
	

func _on_detach_unit_pressed() -> void:
	var tree_item : TreeItem = %UnitList.get_selected()
	if tree_item == null:
		return
#
	var unit_stat : UnitStats = tree_item.get_metadata(0) as UnitStats
	if unit_stat == null:
		return

	carrier.detach_unit(unit_stat)
	%UnitList.remove_tree_item(tree_item)


func _set_carrier(_carrier: Unit) -> void:
	carrier = _carrier
	
	%CarrierTitle.text = carrier.stat.title
	
	refresh_ui()
	
	# -- Create Tree root..
	var root : TreeItem = %UnitList.create_item()
	%UnitList.hide_root = true
	%UnitList.columns = 1
	root.set_text(0, "Units")

	# -- Unit List..
	var unit_stats : Array[UnitStats] = carrier.stat.attached_units
	for unit_stat : UnitStats in unit_stats:
		var tree_item : TreeItem = %UnitList.create_item(root)
		tree_item.set_text(0, unit_stat.title + " (" + str(unit_stat.level) + ")")
		tree_item.set_metadata(0, unit_stat)
		
