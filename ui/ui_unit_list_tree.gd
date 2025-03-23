extends Tree

# Multiple Selection..
# func _get_drag_data(_position: Vector2) -> Variant:
# 	var items : Array[Variant] = []
# 	var next  : TreeItem = get_next_selected(null)
# 	var v := VBoxContainer.new()
# 	while next:
# 		if get_root() == next.get_parent():
# 			items.append(next)
# 			var l := Label.new()
# 			l.text = next.get_text(0)
# 			v.add_child(l)
# 		next = get_next_selected(next)
# 	set_drag_preview(v)
# 	return items


# -- Single Selection..
func _get_drag_data(_position: Vector2) -> Variant:
	var item    : TreeItem = get_selected()
	var preview : VBoxContainer = VBoxContainer.new()
	
	var preview_label : Label = Label.new()
	preview_label.text = item.get_text(0)
	preview.add_child(preview_label)

	set_drag_preview(preview)

	return item


func _can_drop_data(_position: Vector2, _data: Variant) -> bool:

	# --
	var drop_section : int = get_drop_section_at_position(_position)
	if drop_section == -100:
		return false
	
	# --
	var drop_item : TreeItem = get_item_at_position(_position)
	if drop_item == _data:
		return false

	# --
	# Item is over another TreeItem..
	if drop_section == 0:
		var drag_unit_stat : UnitStats = _data.get_metadata(0) as UnitStats
		var drop_unit_stat : UnitStats = drop_item.get_metadata(0) as UnitStats

		# -- Can't drop a Leader on another Leader..
		if drag_unit_stat.unit_type == Term.UnitType.LEADER:
			return false

		# -- Check Leader capacity..
		if drop_unit_stat.unit_type == Term.UnitType.LEADER:
			return drop_unit_stat.has_capacity()
		else:
			return false
	
	return true


func _drop_data(_position: Vector2, _data: Variant) -> void:
	var drop_section : int = get_drop_section_at_position(_position)
	var drop_item    : TreeItem = get_item_at_position(_position)
	#print("_drop_data", drop_section)
	# --
	# Item is over another TreeItem..
	if drop_section == 0:
		add_tree_item_as_child(_data, drop_item)
		deselect_all()
		
		# --
		__add_child_parent_relationship(_data, drop_item)
		
	else:
		if drop_section == -1:
			_data.move_before(drop_item)
		elif drop_section == 1:
			_data.move_after(drop_item)
		
		# --
		__remove_child_parent_relationship(_data)


func __add_child_parent_relationship(_child:TreeItem, _parent:TreeItem) -> void:
	"""
	WARNING: The following code doesn't belong here.. not specific to the Tree class
	"""
	
	var unit_stat   : UnitStats = _child.get_metadata(0) as UnitStats
	var leader_stat : UnitStats = _parent.get_metadata(0) as UnitStats
	
	# -- Assign Unit reference..
	leader_stat.attached_units.append(unit_stat)
	
	# -- Assign Leader reference..
	unit_stat.leader = leader_stat


func __remove_child_parent_relationship(_child:TreeItem) -> void:
	"""
	WARNING: The following code doesn't belong here.. not specific to the Tree class
	"""
	
	if _child.get_parent() == null:
		var unit_stat : UnitStats = _child.get_metadata(0) as UnitStats
		
		if unit_stat.leader != null:
			# -- Remove Unit reference..
			unit_stat.leader.attached_units.erase(unit_stat)
			
			# -- Remove Leader reference..
			unit_stat.leader = null


func add_tree_item_as_child(_item:TreeItem, _parent:TreeItem) -> void:
	_item.get_parent().remove_child(_item)
	_parent.add_child(_item)


func remove_tree_item(_item: TreeItem) -> void:
	_item.free()
	#var parent_item : TreeItem = _item.get_parent()
	#parent_item.remove_child(_item)
	#_item.get_parent().remove_child(_item)
