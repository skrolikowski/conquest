extends Node
class_name GameController

## Root controller for the entire game
##
## Responsibilities:
## - Manage main menu
## - Create and destroy game sessions
## - Handle transitions between menu and gameplay
## - Provide save file management

signal game_session_started
signal game_session_ended
signal returned_to_menu

# var main_menu: Control = null
var game_session : GameSession
var world_manager : WorldManager

# Packed scenes
var world_manager_scene: PackedScene = preload("res://scenes/world_manager.tscn")
# var main_menu_scene: PackedScene = preload("res://ui/main_menu.tscn")  # Phase 5


func _ready() -> void:
	# PHASE 4: Skip menu for now, auto-start game
	"""Temporary: Auto-start game without menu (for testing)"""
	load_saved_game("debug")

	# PHASE 5: Will be replaced with:
	# show_main_menu()


func _setup_game() -> void:
	# Clean up existing session
	# if game_session:
	# 	await _end_current_session()

	# Load WorldManager scene
	world_manager = world_manager_scene.instantiate()
	add_child(world_manager)

	# Create and initialize session
	game_session = GameSession.new()
	add_child(game_session)
	game_session.initialize(world_manager)


func start_new_game(_game_name: String) -> void:
	"""Start a new game session."""
	print("[GameController] Starting new game")

	await _setup_game()

	# Start new game
	await game_session.start_new_game(_game_name)

	game_session_started.emit()


func load_saved_game(_game_name: String) -> void:
	"""Load a saved game session."""
	print("[GameController] Loading saved game")

	await _setup_game()

	# Load the save
	var success: bool = await game_session.load_game(_game_name)
	if success:
		game_session_started.emit()
	else:
		print("[GameController] Load failed, starting new game")
		await game_session.start_new_game(_game_name)
		game_session_started.emit()


func return_to_main_menu() -> void:
	"""End current game and return to main menu."""
	print("[GameController] Returning to main menu")

	# await _end_current_session()
	# show_main_menu()

	returned_to_menu.emit()


func _end_current_session() -> void:
	"""Clean up the current game session."""
	if game_session:
		game_session.end_session()
		await get_tree().process_frame
		game_session.queue_free()
		game_session = null

	if world_manager:
		world_manager.queue_free()
		world_manager = null

	game_session_ended.emit()
