extends Node2D
class_name WorldManager

@onready var world_camera   := %WorldCamera as WorldCamera
@onready var world_gen      := %WorldGen as WorldGen
@onready var world_canvas   := %WorldCanvas as CanvasLayer
@onready var player_manager := $PlayerManager as PlayerManager

# --
var focus_tile  : Vector2i
var focus_node  : Node
var turn_number : int = 0

# -- Selection (for Unit/Building)
var selection_tween : Tween
var selection  : Node : set = _set_selection

# -- Dragging (for Unit Movement)
var is_dragging : bool = false
var drag_start  : Vector2 = Vector2.ZERO
var drag_end    : Vector2 = Vector2.ZERO
var drag_offset : Vector2 = Vector2.ZERO


func _ready() -> void:
	world_camera.reset()

	world_gen.connect("map_loaded", _on_map_loaded)

	world_canvas.connect("end_turn", _on_end_turn)
	world_canvas.connect("camera_zoom", world_camera.change_zoom)

	# --
	# print("[WorldManager] New Game")
	Persistence.new_game()
	# print("[WorldManager] Load Game")
	# Persistence.load_game()


func _draw() -> void:
	if selection is Unit:
		var unit : Unit = selection as Unit
		unit.move_delta = drag_end - drag_start
		unit.queue_redraw()


func _on_map_loaded() -> void:
	print("[WorldManager] Map Loaded")
	
	if Persistence.is_new_game:
		player_manager.new_game()
	else:
		var game_data : Dictionary = Persistence.load_section(Persistence.SECTION.GAME)
		on_load_data(game_data)

		var camera_data : Dictionary = Persistence.load_section(Persistence.SECTION.CAMERA)
		world_camera.on_load_data(camera_data)
		
		var player_data : Dictionary = Persistence.load_section(Persistence.SECTION.PLAYER)
		player_manager.on_load_data(player_data)



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
				elif selection is Village:
					world_canvas.open_village_menu(selection as Village)
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
					drag_offset = world_position - selection.global_position
					drag_unit_start(world_position)

			elif is_dragging and is_valid_drag():
				"""
				Mouse Button - Release
				"""
				drag_unit_end(world_position + drag_offset)
				
				if selection is Unit:
					var unit : Unit = selection as Unit
					unit.on_drag_release(world_position)

	elif _event is InputEventMouseMotion and is_dragging:
		var mouse_event   : InputEventMouseMotion = _event as InputEventMouseMotion
		var drag_position : Vector2 = get_global_mouse_position() + drag_offset
		
		if mouse_event.button_mask == 1:
			"""
			Mouse Button - Dragging
			"""
			drag_unit_update(drag_position)


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
		if results.size() == 1:
			return results[0]['collider']
		else:
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
	world_gen.clear_cursor_tiles()

	if focus_node == null:
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

	# -- Tile index..
	# var _cd : String = ""
	# if world_gen.is_water_tile(focus_tile):
	# 	_cd += "W"
	# else:
	# 	_cd += "L"
	# if world_gen.is_ocean_tile(focus_tile):
	# 	_cd += "O"
	# elif world_gen.is_river_tile(focus_tile):
	# 	_cd += "R"
	# else:
	# 	_cd += "-"
	# if world_gen.is_shore_tile(focus_tile):
	# 	_cd += "S"
	# else:
	# 	_cd += "-"
	# if world_gen.has_ocean_access_tile(focus_tile):
	# 	_cd += "A"
	# else:
	# 	_cd += "-"
	tile_status.append(str(focus_tile))# + " " + str(_cd))

	# -- Tile height..
	var tile_height : float = world_gen.get_tile_height(focus_tile)
	tile_status.append(str(snapped(tile_height, 0.01)))

	# -- Industry modifiers..
	var mod_data : Dictionary = world_gen.get_terrain_modifier_by_industry_type(focus_tile)
	if mod_data.size() > 0:
		var mod_text : PackedStringArray = PackedStringArray()
		mod_text.append("Farm: " + str(mod_data[Term.IndustryType.FARM]) + "%")
		mod_text.append("Mill: " + str(mod_data[Term.IndustryType.MILL]) + "%")
		mod_text.append("Mine: " + str(mod_data[Term.IndustryType.MINE]) + "%")
		tile_status.append(", ".join(mod_text))

	world_canvas.update_tile_status(Def.STATUS_SEP.join(tile_status))


func map_set_focus_node(_node: Node) -> void:
	focus_node = _node
	map_refresh_status()

#endregion


#region NODE SELECTION
func attempt_select_area2D(_position : Vector2) -> void:
	var collision : Node = detect_collision(_position)
	if collision:
		if collision is Unit:
			select_unit(collision as Unit)
		elif collision is Building:
			select_building(collision as Building)
		elif collision is Village:
			select_village(collision as Village)
	else:
		unselect_all()


func select_building(_building: Building) -> void:
	if selection != _building and _building.is_selectable:
		selection = _building


func select_unit(_unit: Unit) -> void:
	if selection != _unit:
		selection = _unit
		_unit.on_selected()


func select_village(_village: Village) -> void:
	if selection != _village:
		selection = _village
		
		
func unselect_all() -> void:
	selection = null


func _set_selection(_selection: Node) -> void:
	if selection:
		stop_pulsing_effect()

	selection = _selection
	
	if selection != null:
		start_pulsing_effect()
		world_canvas.close_all_ui()

	# --
	map_set_focus_tile(focus_tile)

#endregion


#region PULSING HIGHLIGHT EFFECT
func start_pulsing_effect() -> void:
	if selection_tween:
		selection_tween.stop()
		selection_tween = null
		
	selection_tween = create_tween()
	selection_tween.set_ease(Tween.EASE_IN_OUT)
	selection_tween.set_trans(Tween.TRANS_SINE)

	var sprite : Sprite2D = selection.get_node("Sprite2D") as Sprite2D
	selection_tween.tween_property(sprite, "modulate", Color.LIGHT_GRAY, 0.5)
	selection_tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)

	selection_tween.set_loops(-1)


func stop_pulsing_effect() -> void:
	if selection_tween:
		selection_tween.stop()
		selection_tween = null
		
	var sprite : Sprite2D = selection.get_node("Sprite2D") as Sprite2D
	if sprite:
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


#region TURN MANAGEMENT
func begin_turn() -> void:
	print("[WorldManager] Begin Turn")

	# -- Update canvas..
	world_canvas.turn_number = turn_number
	world_canvas.refresh_current_ui()

	player_manager.begin_turn()


func end_turn() -> void:
	print("[WorldManager] End Turn")

	# -- End turn for all players..
	player_manager.end_turn()

	# -- repeat..
	begin_turn()


func _on_end_turn() -> void:
	print("[NOTE] End Turn")

	Def.get_world_canvas().close_all_ui()
	unselect_all()

	turn_number += 1

	# --
	end_turn()
	
#endregion


#region GAME PERSISTENCE
func on_save_data() -> Dictionary:
	return {
		"turn_number": turn_number,
	}


func on_load_data(_data: Dictionary) -> void:
	turn_number = _data["turn_number"]

#endregion
