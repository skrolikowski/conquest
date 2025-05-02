extends Node2D
class_name WorldSelector

var mouse_pos : Vector2 = Vector2.ZERO

# -- Selection..
var selected  : Node
var selection : Array[Unit] = []
var selection_tweens : Array[Tween] = []

# -- Dragging..
var is_dragging : bool = false
var drag_start  : Vector2 = Vector2.ZERO
var drag_end    : Vector2 = Vector2.ZERO


func _process(_delta: float) -> void:
	mouse_pos = get_global_mouse_position()


func _draw() -> void:
	if is_dragging:
		if selected is Unit:
			var _unit : Unit = selected as Unit
			_unit.move_delta = drag_end - _unit.position
			_unit.queue_redraw()

			for selected_unit:Unit in selection:
				selected_unit.move_delta = drag_end - selected_unit.position
				selected_unit.queue_redraw()

		elif _is_valid_drag():
			draw_rect(Rect2(drag_start, mouse_pos - drag_start), Color.LIGHT_GRAY, false, 2.0)


func clear_selected() -> void:
	if selected:
		selected.selected = false
		selected = null


func clear_selection() -> void:
	for node: Unit in selection:
		node.selected = false
	selection = []


func _input(_event: InputEvent) -> void:
	if Def.get_world_canvas().locking_ui != null:
		"""
			Dev-note:
			If locking_ui is open, we don't want to process any input events until it's closed..
		"""
		return
	
	# --
	if _event is InputEventMouseButton:
		var mouse_event    : InputEventMouseButton = _event as InputEventMouseButton
		var world_position : Vector2 = Vector2(mouse_pos.x, mouse_pos.y)

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.double_click:
				"""
				DOUBLE-CLICK
				"""
				if selected:
					clear_selection()

					if selected is Unit:
						Def.get_world_canvas().open_unit_menu(selected as Unit)
					elif selected is Building:
						Def.get_world_canvas().open_building_menu(selected as Building)
					elif selected is Village:
						Def.get_world_canvas().open_village_menu(selected as Village)

			elif mouse_event.pressed:
				"""
				CLICK
				"""
				_select_point(world_position)
				_drag_start(world_position)
			
			elif is_dragging and _is_valid_drag():
				"""
				RELEASE
				"""
				if selected is Unit:
					selected.move_delta = Vector2.ZERO
					selected.queue_redraw()
					selected.on_drag_release(world_position)
					
					for node: Unit in selection:
						node.move_delta = Vector2.ZERO
						node.queue_redraw()
						node.on_drag_release(world_position)
				else:
					_drag_end(world_position)
					_select_drag_rect(world_position)
				

	elif _event is InputEventMouseMotion and is_dragging:
		var mouse_event   : InputEventMouseMotion = _event as InputEventMouseMotion
		var drag_position : Vector2 = Vector2(mouse_pos.x, mouse_pos.y)
		
		if mouse_event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			_drag_update(drag_position)


#region DRAG & DRAG
func _is_valid_drag() -> bool:
	return drag_start.distance_to(drag_end) > Def.TILE_SIZE.x * 0.1


func _drag_start(_position: Vector2) -> void:
	is_dragging = true
	drag_start  = _position
	drag_end    = _position


func _drag_update(_position: Vector2) -> void:
	is_dragging = true
	drag_end = _position
	queue_redraw()


func _drag_end(_position: Vector2) -> void:
	is_dragging = false
	drag_end    = _position
	queue_redraw()

#endregion


#region VIEWPORT CLICK DETECTION
func _select_point(_position: Vector2, _collision_mask: Term.CollisionMask = Term.CollisionMask.OBJECT) -> void:
	var pick : Node
	
	# --
	var collision : Node = point_collision(_position, _collision_mask)
	if collision:
		if collision is Unit:
			pick = collision as Unit
		elif collision is Building:
			pick = collision as Building
		elif collision is Village:
			pick = collision as Village

	if pick:
		if selected == null:
			selected = pick
			selected.selected = true
			Def.get_world().map_set_focus_node(selected)
		elif selected != pick:
			selected.selected = false
			selected = pick
			selected.selected = true
			Def.get_world().map_set_focus_node(selected)

		if selected is Building or selected is Village:
			clear_selection()
		elif selected is Unit and not selected in selection:
			clear_selection()
	else:
		if selected:
			clear_selected()
			clear_selection()


func _select_drag_rect(_position: Vector2, _collision_mask: Term.CollisionMask = Term.CollisionMask.OBJECT) -> void:
	var center : Vector2 = (_position + drag_start) / 2
	var rect   : RectangleShape2D = RectangleShape2D.new()
	rect.extents = abs(_position - drag_start) / 2
	_select_rect_shape2d(center, rect, _collision_mask)


func _select_rect_shape2d(_position: Vector2, _shape: RectangleShape2D, _collision_mask: Term.CollisionMask = Term.CollisionMask.OBJECT) -> void:
	clear_selection()

	var collision : Array[Dictionary] = shape_collision(_position, _shape, _collision_mask)
	if collision.size() > 0:
		for result in collision:
			if result['collider'] is Unit:
				var unit : Unit = result['collider'] as Unit
				unit.selected = true
				selection.append(unit)
	

func point_collision(_position: Vector2, _collision_mask: Term.CollisionMask = Term.CollisionMask.OBJECT) -> Node:
	var space : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query : PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.collide_with_areas  = true
	query.collide_with_bodies = false
	query.collision_mask      = _collision_mask
	query.position = _position

	var results : Array[Dictionary] = space.intersect_point(query, 1)
	"""
		Dev-note:
		Some Units/Buildings have multiple Area2D
	"""
	if results.size() > 0:
		return results[0]['collider']
	return null


func shape_collision(_position: Vector2, _shape: RectangleShape2D, _collision_mask: Term.CollisionMask = Term.CollisionMask.OBJECT) -> Array[Dictionary]:
	var space : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query : PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.collide_with_areas  = true
	query.collide_with_bodies = false
	query.collision_mask      = _collision_mask
	query.shape = _shape
	query.transform = Transform2D(0, _position)
	return space.intersect_shape(query)

#endregion
