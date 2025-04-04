extends Node

const SAVE_PATH : String = "user://conquest_save_01.ini"

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
	var config : ConfigFile = ConfigFile.new()

	# -- Game Data..
	var game_data : Dictionary = world_manager.on_save_data()
	for key: String in game_data.keys():
		config.set_value(SECTION.GAME, key, game_data[key])

	# -- Player Settings..
	var player_data : Dictionary = world_manager.player.on_save_data()
	for key: String in player_data.keys():
		config.set_value(SECTION.PLAYER, key, player_data[key])

	# -- Camera Settings..
	var camera_data : Dictionary = world_manager.world_camera.on_save_data()
	for key: String in camera_data.keys():
		config.set_value(SECTION.CAMERA, key, camera_data[key])

	# -- World Settings..
	var world_data : Dictionary = world_manager.world_gen.on_save_data()
	for key: String in world_data.keys():
		config.set_value(SECTION.WORLD, key, world_data[key])

	# --
	config.save(SAVE_PATH)


func load_game() -> void:
	var world_manager : WorldManager = Def.get_world() as WorldManager
	var config : ConfigFile = ConfigFile.new()

	var err : Error = config.load(SAVE_PATH)
	if err != OK:
		print("Error loading save file: " + str(err))
		return

	# -- Load WorldGen..
	var world_data : Dictionary = {}
	for key in config.get_section_keys(SECTION.WORLD):
		world_data[key] = config.get_value(SECTION.WORLD, key)
		
	world_manager.world_gen.connect("map_loaded", _on_old_map_loaded, CONNECT_ONE_SHOT)
	world_manager.world_gen.on_load_data(world_data)


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
	var world_manager : WorldManager = Def.get_world() as WorldManager
	var config : ConfigFile = ConfigFile.new()
	
	var err : Error = config.load(SAVE_PATH)
	if err != OK:
		print("Error loading save file: " + str(err))
		return
	
	# -- Load Game data..
	var game_data : Dictionary = {}
	for key in config.get_section_keys(SECTION.GAME):
		game_data[key] = config.get_value(SECTION.GAME, key)
	world_manager.on_load_data(game_data)

	# -- Load Camera data..
	var camera_data : Dictionary = {}
	for key in config.get_section_keys(SECTION.CAMERA):
		camera_data[key] = config.get_value(SECTION.CAMERA, key)
	world_manager.world_camera.on_load_data(camera_data)

	# -- Load Player data..
	var player_data : Dictionary = {}
	for key in config.get_section_keys(SECTION.PLAYER):
		player_data[key] = config.get_value(SECTION.PLAYER, key)
	world_manager.player.on_load_data(player_data)
