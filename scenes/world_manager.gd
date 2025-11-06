extends Node2D
class_name WorldManager

@onready var world_selector := $WorldSelector as WorldSelector
@onready var world_camera   := %WorldCamera as WorldCamera
@onready var world_gen      := %WorldGen as WorldGen
@onready var world_canvas   := %WorldCanvas as CanvasLayer
@onready var player_manager := $PlayerManager as PlayerManager

# --
var focus_tile  : Vector2i
var focus_node  : Node
var turn_number : int = 0


func _ready() -> void:
	world_camera.reset()

	world_selector.connect("cursor_updated", _on_cursor_updated)

	world_gen.connect("map_loaded", _on_map_loaded)

	world_canvas.connect("end_turn", _on_end_turn)
	world_canvas.connect("camera_zoom", world_camera.change_zoom)

	# Initialize FogOfWarService
	FogOfWarService.initialize(world_gen, Preload.C.FOG_OF_WAR_ENABLED)

	# --
	# print("[WorldManager] New Game")
	#Persistence.new_game()
	# print("[WorldManager] Load Game")
	Persistence.load_game()


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


#region MAP INFORMATION / CURSOR
func _on_cursor_updated(_cursor_position: Vector2) -> void:
	var tile_coords : Vector2i = world_gen.get_local_to_map_position(_cursor_position)
	if focus_tile != tile_coords:
		map_set_focus_tile(tile_coords)


func map_set_focus_tile(_tile: Vector2i) -> void:
	focus_tile = _tile

	map_refresh_cursor()
	map_refresh_tile_status()


func map_refresh_cursor() -> void:
	world_gen.clear_cursor_tiles()

	if focus_node == null:
		world_gen.set_cursor_tile(focus_tile)


func map_refresh_status() -> void:
	if focus_node != null:
		# if focus_node is Unit:
		# 	var node : Unit = focus_node as Unit
		# 	var info : String = node.get_status_information(focus_tile)
		# 	world_canvas.update_status(info)
		if focus_node is Building:
			var node : Building = focus_node as Building
			var info : String = node.get_status_information(focus_tile)
			world_canvas.update_status(info)
	else:
		# --
		var status_text : PackedStringArray = PackedStringArray()
		status_text.append("Tile: " + str(focus_tile))
		
		world_canvas.update_status(Preload.C.STATUS_SEP.join(status_text))


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

	world_canvas.update_tile_status(Preload.C.STATUS_SEP.join(tile_status))


func map_set_focus_node(_node: Node) -> void:
	focus_node = _node
	map_refresh_status()

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

	world_canvas.close_all_ui()
	# unselect_all()

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
