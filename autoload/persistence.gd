extends Node

const SAVE_PATH : String = "user://conquest_save_01.ini"

const SECTION : Dictionary = {
	GAME   = "game",
	PLAYER = "player",
	CAMERA = "camera",
	WORLD  = "world",
}

var is_new_game : bool = false

func new_game() -> void:
	is_new_game = true
	
	var world_manager : WorldManager = Def.get_world() as WorldManager
	world_manager.world_gen.new_game()


func save_game() -> void:
	var world_manager : WorldManager = Def.get_world() as WorldManager
	var player_manager : PlayerManager = Def.get_player_manager() as PlayerManager
	var config : ConfigFile = ConfigFile.new()

	var game_data : Dictionary = world_manager.on_save_data()
	for key: String in game_data:
		config.set_value(SECTION.GAME, key, game_data[key])

	var camera_data : Dictionary = world_manager.world_camera.on_save_data()
	for key: String in camera_data:
		config.set_value(SECTION.CAMERA, key, camera_data[key])

	var world_data : Dictionary = world_manager.world_gen.on_save_data()
	for key: String in world_data:
		config.set_value(SECTION.WORLD, key, world_data[key])

	var player_data : Dictionary = player_manager.on_save_data()
	for key: String in player_data:
		config.set_value(SECTION.PLAYER, key, player_data[key])

	# --
	config.save(SAVE_PATH)


func load_game() -> void:
	var config : ConfigFile = ConfigFile.new()
	var err    : Error = config.load(SAVE_PATH)
	if err != OK:
		print("Error loading save file: " + str(err))
		return

	# -- Load Map..
	var world_data : Dictionary = {}
	for key in config.get_section_keys(SECTION.WORLD):
		world_data[key] = config.get_value(SECTION.WORLD, key)

	Def.get_world_map().on_load_data(world_data)


func load_section(_section: String) -> Dictionary:
	var config : ConfigFile = ConfigFile.new()
	var err    : Error = config.load(SAVE_PATH)
	if err != OK:
		print("Error loading save file: " + str(err))
		return {}

	# -- Load Camera data..
	var data : Dictionary = {}
	for key in config.get_section_keys(_section):
		data[key] = config.get_value(_section, key)

	return data
