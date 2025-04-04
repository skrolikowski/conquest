extends Node

const SAVE_PATH : String = "user://conquest_save_01.json"

const SECTION : Dictionary = {
	GAME   = "game",
	PLAYER = "player",
	CAMERA = "camera",
	WORLD  = "world",
}

func new_game() -> void:
	var world_manager : WorldManager = Def.get_world() as WorldManager
	world_manager.world_gen.new_game()
	world_manager.world_gen.connect("map_loaded", _on_new_map_loaded, CONNECT_ONE_SHOT)


func save_game() -> void:
	var world_manager : WorldManager = Def.get_world() as WorldManager
	var data : Dictionary = {}
	data[SECTION.GAME] = {}
	data[SECTION.PLAYER] = {}
	data[SECTION.CAMERA] = {}
	data[SECTION.WORLD] = {}

	# -- Game Data..
	var game_data : Dictionary = world_manager.on_save_data()
	for key: String in game_data.keys():
		data[SECTION.GAME][key] = game_data[key]

	# -- Player Settings..
	var player_data : Dictionary = world_manager.player.on_save_data()
	for key: String in player_data.keys():
		data[SECTION.PLAYER][key] = player_data[key]

	# -- Camera Settings..
	var camera_data : Dictionary = world_manager.world_camera.on_save_data()
	for key: String in camera_data.keys():
		data[SECTION.CAMERA][key] = camera_data[key]

	# -- World Settings..
	var world_data : Dictionary = world_manager.world_gen.on_save_data()
	for key: String in world_data.keys():
		data[SECTION.WORLD][key] = world_data[key]

	# --
	var file_access : FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file_access:
		print("An error happened while saving data: ", FileAccess.get_open_error())
		return

	# --
	file_access.store_line(JSON.stringify(data))
	file_access.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	# -- Load Game..
	var world_manager : WorldManager = Def.get_world() as WorldManager
	var file_access : FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string := file_access.get_line()
	file_access.close()

	# -- Parse JSON..
	var json : JSON = JSON.new()
	var error : int = json.parse(json_string)
	if not error == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return

	var data : Dictionary = json.data

	# -- Load WorldGen..
	var world_data : Dictionary = {}
	for key: String in data[SECTION.WORLD]:
		world_data[key] = data[SECTION.WORLD][key]
	world_manager.world_gen.on_load_data(world_data)
	world_manager.world_gen.connect("map_loaded", _on_old_map_loaded, CONNECT_ONE_SHOT)






func _on_new_map_loaded() -> void:
	"""
	Game World was loaded, now continue..
	"""
	
	# -- New player data..
	var world_manager : WorldManager = Def.get_world() as WorldManager
	world_manager.player.new_game()


func _on_old_map_loaded() -> void:
	"""
	Game World was loaded, now load the rest of the game..
	"""
	var file_access : FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string := file_access.get_line()
	file_access.close()
	
	# -- Parse JSON..
	var json : JSON = JSON.new()
	var error : int = json.parse(json_string)
	if not error == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return

	var world_manager : WorldManager = Def.get_world() as WorldManager
	var data : Dictionary = json.data
	
	# -- Load Game data..
	var game_data : Dictionary = {}
	for key: String in data[SECTION.GAME]:
		game_data[key] = data[SECTION.GAME][key]
	world_manager.on_load_data(game_data)

	# -- Load Camera data..
	var camera_data : Dictionary = {}
	for key: String in data[SECTION.CAMERA]:
		camera_data[key] = data[SECTION.CAMERA][key]
	world_manager.world_camera.on_load_data(camera_data)

	# -- Load Player data..
	var player_data : Dictionary = {}
	for key: String in data[SECTION.PLAYER]:
		player_data[key] = data[SECTION.PLAYER][key]
	world_manager.player.on_load_data(player_data)
