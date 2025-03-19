extends Node2D
class_name WorldManager

@onready var camera         := $Camera2D as Camera2D
@onready var world_gen      := %WorldGen as WorldGen
@onready var world_canvas   := %WorldCanvas as CanvasLayer
@onready var player         := $Player as Player

# --
var focus_tile : Vector2i
var focus_node : Node

# -- Selection (for Unit/Building)
var selection_tween : Tween
var selection  : Node : set = _set_selection

# -- Dragging (for Unit Movement)
var is_dragging : bool = false
var drag_start  : Vector2 = Vector2.ZERO
var drag_end    : Vector2 = Vector2.ZERO


func _ready() -> void:
	camera.position = Vector2(256, 256)
	camera.zoom = Vector2(camera_zoom, camera_zoom)
	
	world_gen.connect("map_loaded", _on_map_loaded)
	
	world_canvas.connect("end_turn", _on_end_turn)
	world_canvas.connect("camera_zoom", _on_camera_zoom)


func _process(_delta:float) -> void:
	if Input.is_action_just_pressed("zoom_in"):
		_camera_zoom(1)
	elif Input.is_action_just_pressed("zoom_out"):
		_camera_zoom(-1)
	
	# --
	var x : float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y : float  = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	var movement : Vector2 = Vector2(x, y).normalized()
	
	camera.position += movement * camera_move_speed * _delta


func _draw() -> void:
	if selection is Unit:
		var unit : Unit = selection as Unit
		unit.move_delta = drag_end - drag_start
		unit.queue_redraw()



func _unhandled_input(_event:InputEvent) -> void:
	if _event is InputEventMouseButton:
		var mouse_event    : InputEventMouseButton = _event as InputEventMouseButton
		var world_position : Vector2 = get_global_mouse_position()
		
		if mouse_event.button_index == 1:	
			if mouse_event.double_click:
				"""
				Mouse Button - Double-Click
				"""
				if selection is Unit:
					world_canvas.open_unit_menu(selection as Unit)
					unselect_all()
				elif selection is Building:
					world_canvas.open_building_menu(selection as Building)
					unselect_all()

			elif mouse_event.pressed:
				#var tile_map : TileMap = world_map.tile_map
				#var map_pos  : Vector2 = tile_map.local_to_map(mouse_event.position)
				#var tile_data : TileData = tile_map.get_cell_tile_data(0, map_pos)
				#print(tile_map.get_cell_atlas_coords(0, map_pos))
				#print(tile_data.get_custom_data("weight"))
				
				"""
				Mouse Button - Press
				"""
				attempt_select_area2D(world_position)
				
				if selection is Unit:
					drag_unit_start(world_position)

			elif is_dragging and is_valid_drag():
				"""
				Mouse Button - Release
				"""
				drag_unit_end(world_position)
				
				if selection is Unit:
					var unit : Unit = selection as Unit
					unit.on_drag_release(world_position)

	elif _event is InputEventMouseMotion and is_dragging:
		var mouse_event    : InputEventMouseMotion = _event as InputEventMouseMotion
		var world_position : Vector2 = get_global_mouse_position()
		
		if mouse_event.button_mask == 1:
			"""
			Mouse Button - Dragging
			"""
			drag_unit_update(world_position)

	elif _event is InputEventPanGesture:
		camera.position += _event.delta * camera_move_speed * 0.01


	# --
	# -- Map Information..
	if _event is InputEventMouse:
		var world_position : Vector2 = get_global_mouse_position()
		var tile_coords    : Vector2i = world_gen.tilemap_layers[WorldGen.MapLayer.LAND].local_to_map(world_position)
		#var tile_coords    : Vector2i = world_map.tile_map.local_to_map(world_position)

		if focus_tile != tile_coords:
			map_set_focus_tile(tile_coords)


func detect_collision(_position:Vector2) -> Node:
	var space : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query : PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.collide_with_areas  = true
	query.collide_with_bodies = false
	query.position            = _position

	var results : Array[Dictionary] = space.intersect_point(query, 2)
	"""
		Dev-note:
		Some Units/Buildings have multiple Area2D
	"""
	if results.size() > 0:
		if results[0]['collider'] is Unit or results[0]['collider'] is Building:
			return results[0]['collider']
		elif results[1]['collider'] is Unit or results[1]['collider'] is Building:
			return results[1]['collider']
	return null


#region MAP INFORMATION / CURSOR
func map_set_focus_tile(_tile: Vector2i) -> void:
	focus_tile = _tile

	map_refresh_cursor()
	map_refresh_tile_status()


func map_refresh_cursor() -> void:
	#world_map.clear_cursor_tiles()
	world_gen.clear_cursor_tiles()

	if focus_node == null:
		#world_map.set_cursor_tile(focus_tile)
		world_gen.set_cursor_tile(focus_tile)


func map_refresh_status() -> void:
	if selection != null:
		if selection is Unit:
			var node : Unit = selection as Unit
			var info : String = node.get_status_information(focus_tile)
			world_canvas.update_status(info)
		elif selection is Building:
			var node : Building = selection as Building
			var info : String = node.get_status_information(focus_tile)
			world_canvas.update_status(info)
	elif focus_node != null:
		var node : Building = focus_node as Building
		var info : String = node.get_status_information(focus_tile)
		world_canvas.update_status(info)
	else:
		# --
		var status_text : PackedStringArray = PackedStringArray()
		status_text.append("Tile: " + str(focus_tile))
		
		world_canvas.update_status(Def.STATUS_SEP.join(status_text))
		# world_canvas.clear_status()


func map_refresh_tile_status() -> void:
	var tile_status : PackedStringArray = PackedStringArray()

	# -- Tile height..
	var tile_height : float = world_gen.get_tile_height(focus_tile)
	tile_status.append("Height: " + str(snapped(tile_height, 0.01)))

	# -- Industry modifiers..
	var mod_data : Dictionary = world_gen.get_terrain_modifier_by_industry_type(focus_tile)
	var mod_text : PackedStringArray = PackedStringArray()
	mod_text.append("Farm: " + str(mod_data[Term.IndustryType.FARM]) + "%")
	mod_text.append("Mill: " + str(mod_data[Term.IndustryType.MILL]) + "%")
	mod_text.append("Mine: " + str(mod_data[Term.IndustryType.MINE]) + "%")
	tile_status.append("Industry: " + ", ".join(mod_text))

	world_canvas.update_tile_status(Def.STATUS_SEP.join(tile_status))


func map_set_focus_node(_node: Node) -> void:
	focus_node = _node
	map_refresh_status()

#endregion


#region CAMERA
var camera_move_speed : float = 600.0
var camera_zoom       : float = 1.00
var camera_zoom_min   : float = 0.50
var camera_zoom_max   : float = 2.00
var camera_zoom_step  : float = 0.50

func _on_camera_zoom(_direction:int) -> void:
	_camera_zoom(_direction)

func _camera_zoom(_direction:int) -> void:
	camera_zoom = clamp(camera_zoom + camera_zoom_step * _direction, camera_zoom_min, camera_zoom_max)
	camera.zoom = Vector2(camera_zoom, camera_zoom)
	
#endregion


#region TURN MANAGEMENT
func _on_map_loaded() -> void:
	print("[NOTE] World Map Loaded")


func _on_end_turn() -> void:
	print("[NOTE] Turn Ended")

	Def.get_world_canvas().close_all_ui()
	unselect_all()

	# combat_manager.begin_turn()
	#player.begin_turn()
	
#endregion


#region NODE SELECTION
func attempt_select_area2D(_position : Vector2) -> void:
	var collision : Node = detect_collision(_position)
	if collision:
		if collision is Unit:
			select_unit(collision as Unit)
		elif collision is Building:
			select_building(collision as Building)
	else:
		unselect_all()


func select_building(_building: Building) -> void:
	if selection != _building and _building.is_selectable:
		selection = _building


func select_unit(_unit: Unit) -> void:
	if selection != _unit:
		selection = _unit
		_unit.on_selected()
		
		
func unselect_all() -> void:
	selection = null


func _set_selection(_selection: Node) -> void:
	if selection:
		stop_pulsing_effect(selection)

	selection = _selection
	
	if selection != null:
		start_pulsing_effect(selection)
		world_canvas.close_all_ui()

	# --
	map_set_focus_tile(focus_tile)

#endregion


#region PULSING HIGHLIGHT EFFECT
func start_pulsing_effect(node: Node) -> void:
	if selection_tween:
		selection_tween.stop()
		selection_tween = null
		
	selection_tween = create_tween()
	selection_tween.set_ease(Tween.EASE_IN_OUT)
	selection_tween.set_trans(Tween.TRANS_SINE)

	var sprite : Sprite2D = node.get_node("Sprite2D") as Sprite2D
	selection_tween.tween_property(sprite, "modulate", Color.LIGHT_GRAY, 0.5)
	selection_tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)

	selection_tween.set_loops(-1)


func stop_pulsing_effect(node: Node) -> void:
	if selection_tween:
		selection_tween.stop()
		selection_tween = null
		
	var sprite : Sprite2D = node.get_node("Sprite2D") as Sprite2D
	sprite.modulate = Color.WHITE
#endregion


#region UNIT DRAGGING
func drag_unit_start(_position: Vector2) -> void:
	is_dragging = true
	drag_start = _position
	drag_end   = _position


func drag_unit_update(_position: Vector2) -> void:
	is_dragging = true
	drag_end = _position
	
	# --
	queue_redraw()


func is_valid_drag() -> float:
	return drag_start.distance_to(drag_end) > 8


func drag_unit_end(_position: Vector2) -> void:
	# var drag_delta : Vector2 = _position - drag_start

	is_dragging = false
	drag_start  = Vector2.ZERO
	drag_end    = Vector2.ZERO
	
	# --
	queue_redraw()


func draw_drag_unit_line() -> void:
	if is_dragging:
		draw_line(drag_start, drag_end, Color.LIGHT_GRAY, 2)

#endregion
