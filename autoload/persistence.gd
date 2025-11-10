extends Node

const SAVE_PATH_PREFIX : String = "conquest_save_"

const SECTION : Dictionary = {
	SESSION = "session",  # GameSession state (turn number, player, etc)
	WORLD   = "world",    # WorldManager state (terrain, camera view)
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


func save_game(_game_session: GameSession, _save_data: Dictionary) -> bool:
	"""
	Save the current game state to file.
	"""
	assert(game_name != "", "[Persistence] `game_name` not found - remember to set Persistence.game_name")
	var config : ConfigFile = ConfigFile.new()

	for section_key : String in _save_data.keys():
		var section_data : Dictionary = _save_data[section_key]
		for key: String in section_data:
			config.set_value(section_key, key, section_data[key])


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


func delete_save_file(_game_name: String) -> void:
	"""
	Delete the current save file.
	"""
	assert(_game_name != "", "No game loaded to delete save file from")

	var save_path : String = "user://" + SAVE_PATH_PREFIX + _game_name + ".ini"
	var dir : DirAccess = DirAccess.open(save_path.get_base_dir())
	var err : Error = dir.remove(save_path.get_file())
	if err == OK:
		print("[Persistence] Save file deleted successfully")
	else:
		print("Error deleting save file: " + str(err))
