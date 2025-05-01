extends Node2D
class_name WorldSelector

var mouse_pos   : Vector2 = Vector2.ZERO

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
			# var unit : Unit = selected as Unit
			# unit.move_delta = drag_end - drag_start
			# unit.queue_redraw()
			for selected_unit:Unit in selection:
				selected_unit.move_delta = drag_end - selected_unit.position
				selected_unit.queue_redraw()
		elif _is_valid_drag():
			draw_rect(Rect2(drag_start, mouse_pos - drag_start), Color.LIGHT_GRAY, false, 2.0)


func clear_selection() -> void:
	_stop_all_pulsing_effects()
	selection = []


func _input(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		var mouse_event    : InputEventMouseButton = _event as InputEventMouseButton
		var world_position : Vector2 = Vector2(mouse_pos.x, mouse_pos.y)

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.double_click:
				"""
				DOUBLE-CLICK
				"""
				if selected:
					_start_pulsing_effect(selected)

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
				
				if selected == null:
					_stop_all_pulsing_effects()
			
			elif is_dragging and _is_valid_drag():
				"""
				RELEASE
				"""
				if selected is Unit:
					for node: Unit in selection:
						node.move_delta = Vector2.ZERO
						node.queue_redraw()
						node.on_drag_release(world_position)
				else:
					_drag_end(world_position)
					_select_drag_rect(world_position)
					_start_pulsing_effects()
				selected = null
				

	elif _event is InputEventMouseMotion and is_dragging:
		var mouse_event   : InputEventMouseMotion = _event as InputEventMouseMotion
		var drag_position : Vector2 = Vector2(mouse_pos.x, mouse_pos.y)
		
		if mouse_event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			_drag_update(drag_position)


#region DRAG & DRAG
func _is_valid_drag() -> bool:
	return drag_start.distance_to(drag_end) > Def.TILE_SIZE.x * 0.25


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
	selected = null

	var collision : Node = point_collision(_position, _collision_mask)
	if collision:
		if collision is Unit:
			selected = collision as Unit
			selected.on_selected()
			selection.append(selected)
		elif collision is Building:
			selected = collision as Building
		elif collision is Village:
			selected = collision as Village


func _select_drag_rect(_position: Vector2, _collision_mask: Term.CollisionMask = Term.CollisionMask.OBJECT) -> void:
	var center : Vector2 = (_position + drag_start) / 2
	var rect   : RectangleShape2D = RectangleShape2D.new()
	rect.extents = abs(_position - drag_start) / 2
	_select_rect_shape2d(center, rect, _collision_mask)


func _select_rect_shape2d(_position: Vector2, _shape: RectangleShape2D, _collision_mask: Term.CollisionMask = Term.CollisionMask.OBJECT) -> void:
	selection = []
	
	var collision : Array[Dictionary] = shape_collision(_position, _shape, _collision_mask)
	if collision.size() > 0:
		for result in collision:
			if result['collider'] is Unit:
				var unit : Unit = result['collider'] as Unit
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


#region PULSE HIGHLIGHT EFFECT
func _start_pulsing_effect(_node: Node) -> void:
	var tween : Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_loops(-1)
	
	# -- Set highlight effect..
	var property : Sprite2D = _node.sprite as Sprite2D
	tween.tween_property(property, "modulate", Color.LIGHT_GRAY, 0.5)
	tween.tween_property(property, "modulate", Color.WHITE, 0.5)
	
	selection_tweens.append(tween)


func _start_pulsing_effects() -> void:
	_stop_all_pulsing_effects()
	
	for node : Node in selection:
		_start_pulsing_effect(node)


func _stop_all_pulsing_effects() -> void:
	if selection_tweens.size() > 0:
		for tween : Tween in selection_tweens:
			tween.stop()
		selection_tweens.clear()

	for node : Node in selection:
		var property : Sprite2D = node.sprite as Sprite2D
		property.modulate = Color.WHITE

#endregion
