extends PanelContainer
class_name UICarrierUnitList

@onready var btn_close  : Button = %BtnClose as Button
@onready var btn_detach : Button = %BtnDetach as Button
@onready var unit_list  : Tree = %UnitList as Tree

var carrier        : Unit : set = _set_carrier
var selected_items : Array[TreeItem] = []


func _ready() -> void:
	btn_close.connect("pressed", _on_close_pressed)
	btn_detach.connect("pressed", _on_detach_units_pressed)
	unit_list.connect("multi_selected", _on_multiple_unit_selected)


func _set_carrier(_carrier: CarrierUnit) -> void:
	carrier = _carrier

	_create_unit_list_tree()
	
	refresh_ui()


func refresh_ui() -> void:
	btn_detach.disabled = selected_items.size() == 0 or not carrier.can_detach_unit()
	

func _create_unit_list_tree() -> void:
	var carrier_stat : UnitStats = carrier.stat

	unit_list.hide_root = true
	unit_list.columns = 1
	unit_list.select_mode = Tree.SELECT_MULTI

	var root : TreeItem = unit_list.create_item()
	root.set_text(0, carrier_stat.unit_name)

	_create_unit_list_tree_item(root, carrier_stat)


func _create_unit_list_tree_item(_root : TreeItem, _carrier_stat : UnitStats) -> void:
	var unit_stats : Array[UnitStats] = _carrier_stat.get_units_sorted_by_unit_type()
	for unit_stat : UnitStats in unit_stats:
		var item_name : String

		if unit_stat.unit_type == Term.UnitType.LEADER:
			item_name = unit_stat.unit_name
		elif unit_stat.unit_category == Term.UnitCategory.MILITARY:
			item_name = unit_stat.title + " (" + str(unit_stat.level) + ")"
		else:
			item_name = unit_stat.title


		var tree_item : TreeItem = unit_list.create_item(_root)
		tree_item.set_text(0, item_name)
		tree_item.set_metadata(0, unit_stat)

		if unit_stat.attached_units.size() > 0:
			_create_unit_list_tree_item(tree_item, unit_stat)


func _on_multiple_unit_selected(_item:TreeItem, _column:int, _selected:bool) -> void:
	if _selected:
		selected_items.append(_item)
	else:
		selected_items.erase(_item)
	
	refresh_ui()


func get_selected_items() -> Array[TreeItem]:
	var selected_item : TreeItem = unit_list.get_next_selected(null)
	var selected      : Array[TreeItem] = []

	while selected_item:
		selected.append(selected_item)
		selected_item = unit_list.get_next_selected(selected_item)
	
	return selected


func _on_detach_units_pressed() -> void:
	for item : TreeItem in selected_items:
		var unit_stat : UnitStats = item.get_metadata(0) as UnitStats
		carrier.detach_unit(unit_stat)
		unit_list.remove_tree_item(item)


func _on_close_pressed() -> void:
	Def.get_world_canvas().close_sub_ui(self)
