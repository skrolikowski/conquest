extends Node
class_name GameSession

## Encapsulates a single game session (new or loaded)
##
## Responsibilities:
## - Owns game services (TurnOrchestrator, FocusService)
## - Manages WorldManager instance (scene container)
## - Handles game lifecycle (start, load, save, end)
## - Manages turn progression (begin_turn, end_turn)
## - Converts input to state (cursor position -> tile coords)
## - Connects signals between systems
## - Save/load methods (kept for Persistence.gd compatibility)
##
## NOT Responsible For (delegated to WorldManager):
## - Focus UI updates (cursor visualization, status display)
##
## Usage:
##   var session = GameSession.new()
##   session.initialize(world_manager)
##   await session.start_new_game("save_01")
##   session.end_turn()  # Progress to next turn

signal session_started
signal session_ended
signal game_saved
signal game_loaded

var world_manager: WorldManager = null
var turn_orchestrator: TurnOrchestrator = null
var focus_service: FocusService = null


func initialize(_world_manager: WorldManager) -> void:
	"""
	Initialize the session with a WorldManager instance.

	Call this after WorldManager scene is loaded but before starting game.
	"""
	world_manager = _world_manager

	# Create services (moved from WorldManager)
	_create_services()
	_connect_signals()


func _create_services() -> void:
	"""Create and configure game services."""
	# FocusService (instance - owned by this session)
	focus_service = FocusService.new()
	focus_service.world_gen = world_manager.world_gen
	add_child(focus_service)

	# Delegate focus UI updates to WorldManager
	world_manager.connect_focus_signals(focus_service)

	# TurnOrchestrator (instance - owned by this session)
	turn_orchestrator = TurnOrchestrator.new()
	add_child(turn_orchestrator)


func _connect_signals() -> void:
	"""Connect signals between components."""
	# WorldGen signals
	world_manager.world_gen.connect("map_loaded", _on_map_loaded)

	# WorldCanvas signals (moved from WorldManager to GameSession)
	world_manager.world_canvas.connect("end_turn", end_turn)
	# Camera zoom stays in WorldManager since it's pure scene management
	# world_manager.world_canvas.connect("camera_zoom", world_manager.world_camera.change_zoom)

	# WorldSelector signals (input -> FocusService state)
	world_manager.world_selector.connect("cursor_updated", _on_cursor_updated)
	world_manager.world_selector.connect("node_selected", focus_service.set_focus_node)


#region GAME LIFECYCLE

func start_new_game(game_name: String) -> void:
	"""
	Start a fresh new game.

	Args:
		game_name: Name for the save file (e.g., "01", "debug")
	"""
	print("[GameSession] Starting new game: ", game_name)

	# Set Persistence state
	Persistence.game_name = game_name
	Persistence.new_game()

	# Generate new map
	world_manager.world_gen.new_game()
	await world_manager.world_gen.map_loaded

	# Map loaded, initialize turn system
	turn_orchestrator.new_game()

	session_started.emit()


func load_game(game_name: String) -> bool:
	"""
	Load a saved game.

	Args:
		game_name: Name of the save file to load (e.g., "01", "debug")

	Returns:
		true if load successful
		false if load failed
	"""
	print("[GameSession] Loading game: ", game_name)

	# Set game name in Persistence
	Persistence.game_name = game_name

	# Check if save file exists
	if not Persistence.has_save_file():
		print("[GameSession] Save file not found for: ", game_name)
		return false

	# Load world data first (before triggering map_loaded)
	var load_success: bool = Persistence.load_game()
	if not load_success:
		print("[GameSession] Failed to load world data")
		return false

	# Now trigger map load (will emit map_loaded when done)
	var world_data  : Dictionary = Persistence.load_section(Persistence.SECTION.WORLD)
	var game_data   : Dictionary = Persistence.load_section(Persistence.SECTION.GAME)
	var camera_data : Dictionary = Persistence.load_section(Persistence.SECTION.CAMERA)
	var player_data : Dictionary = Persistence.load_section(Persistence.SECTION.PLAYER)

	world_manager.world_gen.on_load_data(world_data)
	world_manager.world_camera.on_load_data(camera_data)
	turn_orchestrator.on_load_data(game_data, player_data)

	game_loaded.emit()
	session_started.emit()
	return true


func save_game() -> bool:
	"""
	Save the current game state using Persistence.

	Returns:
		true if save successful
		false if save failed
	"""
	print("[GameSession] Saving game...")

	# Use Persistence.save_game() which handles everything
	var success: bool = Persistence.save_game()
	if success:
		game_saved.emit()

	return success


func end_session() -> void:
	"""Clean up and end the current session."""
	print("[GameSession] Ending session")

	# Disconnect signals (GameSession owns these connections)
	if world_manager and world_manager.world_gen:
		world_manager.world_gen.disconnect("map_loaded", _on_map_loaded)

	if world_manager and world_manager.world_selector:
		world_manager.world_selector.disconnect("cursor_updated", _on_cursor_updated)
		world_manager.world_selector.disconnect("node_selected", focus_service.set_focus_node)

	# Clean up services
	if turn_orchestrator:
		turn_orchestrator.queue_free()
		turn_orchestrator = null

	if focus_service:
		# Note: WorldManager owns focus UI signal connections
		focus_service.queue_free()
		focus_service = null

	# Note: WorldManager is cleaned up by parent (GameController)
	world_manager = null

	session_ended.emit()

#endregion


#region TURN MANAGEMENT

func begin_turn() -> void:
	"""
	Begin a new turn.

	Called automatically by end_turn(), or can be called manually to start first turn.
	"""
	print("[GameSession] Begin Turn")

	# Update WorldManager UI with current turn number
	world_manager.world_canvas.turn_number = turn_orchestrator.current_turn
	world_manager.world_canvas.refresh_current_ui()

	# Delegate to TurnOrchestrator to handle actual turn logic
	turn_orchestrator.begin_turn()


func end_turn() -> void:
	"""
	End the current turn and automatically begin the next turn.

	This is the main entry point for turn progression.
	"""
	print("[GameSession] End Turn")

	# Close all UI panels
	world_manager.world_canvas.close_all_ui()

	# Delegate to TurnOrchestrator (which will call begin_turn automatically)
	turn_orchestrator.end_turn()

	# Refresh UI for the new turn
	begin_turn()

#endregion


#region SIGNAL HANDLERS

func _on_map_loaded() -> void:
	"""
	Called when map finishes loading.
	This is internal - start_new_game() and load_game() await the map_loaded signal.
	"""
	print("[GameSession] Map loaded")


func _on_cursor_updated(_cursor_position: Vector2) -> void:
	"""
	Handle cursor movement - convert input position to tile coords.

	This is input -> state conversion (GameSession responsibility).
	UI updates are handled by WorldManager (via FocusService signals).
	"""
	var tile_coords: Vector2i = world_manager.world_gen.get_local_to_map_position(_cursor_position)
	focus_service.set_focus_tile(tile_coords)

#endregion


#region GAME PERSISTENCE
# Note: Persistence has been moved to GameSession.
# These methods are kept for legacy Persistence.gd compatibility.

func on_save_data() -> Dictionary:
	"""
	Return save data for this manager.

	DEPRECATED: GameSession now handles save coordination.
	This is kept for Persistence.gd compatibility.
	"""
	if turn_orchestrator == null:
		return {}

	return {
		"turn_number": turn_orchestrator.current_turn,
	}


func on_load_data(_data: Dictionary) -> void:
	"""
	Load saved data.

	DEPRECATED: GameSession now handles load coordination.
	Turn number is loaded by TurnOrchestrator directly.
	"""
	# Turn number is loaded by TurnOrchestrator in GameSession
	pass

#endregion
