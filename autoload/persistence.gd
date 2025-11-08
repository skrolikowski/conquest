extends Node

const SAVE_PATH_PREFIX : String = "conquest_save_"

const SECTION : Dictionary = {
	GAME   = "game",
	PLAYER = "player",
	CAMERA = "camera",
	WORLD  = "world",
}

var is_new_game : bool = false
var game_name   : String = ""  # ← Track current game name


func new_game() -> void:
	"""
	Set flag for new game.

	Note: Map generation is handled by GameSession/WorldGen.
	This just sets the flag for save/load logic.
	"""
	print("[Persistence] Starting New Game")
	is_new_game = true

func has_save_file() -> bool:
	"""
	Check if a save file exists for the current game.
	"""
	assert(game_name != "", "[Persistence] `game_name` not found - remember to set Persistence.game_name")
	var save_path : String = "user://" + SAVE_PATH_PREFIX + game_name + ".ini"
	return FileAccess.file_exists(save_path)

func save_game() -> bool:
	"""
	Save the current game state to file.
	"""
	assert(game_name != "", "[Persistence] `game_name` not found - remember to set Persistence.game_name")
	var world_manager : WorldManager = Def.get_world() as WorldManager
	var turn_orchestrator : TurnOrchestrator = world_manager.turn_orchestrator as TurnOrchestrator
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

	var player_data : Dictionary = turn_orchestrator.on_save_data()
	for key: String in player_data:
		config.set_value(SECTION.PLAYER, key, player_data[key])

	# --
	var save_path : String = "user://" + SAVE_PATH_PREFIX + game_name + ".ini"
	var err : Error = config.save(save_path)
	if err != OK:
		print("Error saving save file: " + str(err))
		return false

	print("[Persistence] Save Game Successful")
	return true


func load_game() -> bool:
	var config : ConfigFile = ConfigFile.new()
	var save_path : String = "user://" + SAVE_PATH_PREFIX + game_name + ".ini"
	var err : Error = config.load(save_path)
	if err == OK:
		print("[Persistence] Load Game Successful")
	else:
		if err == ERR_FILE_NOT_FOUND:
			print("[Persistence] No Save File Found, Starting New Game")
		elif err == ERR_PARSE_ERROR:
			print("Error parsing save file: " + str(err))
		else:
			print("Error loading save file: " + str(err))
		return false
		
	return true


func load_section(_section: String) -> Dictionary:
	"""
	Load a specific section of the save file.
	"""
	assert(game_name != "", "No game loaded to load section from")
	var config : ConfigFile = ConfigFile.new()
	var save_path : String = "user://" + SAVE_PATH_PREFIX + game_name + ".ini"
	var err : Error = config.load(save_path)
	if err != OK:
		print("Error loading save file: " + str(err))
		return {}

	# -- Load Camera data..
	var data : Dictionary = {}
	for key in config.get_section_keys(_section):
		data[key] = config.get_value(_section, key)

	return data
