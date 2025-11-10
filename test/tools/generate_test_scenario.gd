extends Node
## One-time tool to generate and save a test map scenario
##
## Usage:
##   1. Run this scene from Godot editor (F6)
##   2. Wait for "Test scenario saved!" message
##   3. Find the saved file at: test/scenarios/test_map_base.ini
##   4. Update IntegrationTestBase to use load_scenario("test_map_base")
##
## This creates a small, deterministic map for fast integration testing.

signal generation_complete

var game_controller: GameController
var game_session: GameSession
var world_manager: WorldManager


func _ready() -> void:
	print("\n========================================")
	print("Test Scenario Generator")
	print("========================================\n")

	# Create game controller
	game_controller = GameController.new()
	add_child(game_controller)

	# Setup game systems
	game_controller._setup_game()
	await get_tree().process_frame

	# Get references
	game_session = game_controller.game_session
	world_manager = game_controller.world_manager

	# Generate the test map
	print("[1/3] Generating test map...")
	await game_session.start_new_game("test")

	#TODO: set camera position to settler spawn
	# world_manager.world_camera.position = Vector2(2472, 1560)

	print("[2/3] Test map generated successfully!")

	# Save the scenario
	print("[3/3] Saving scenario to test/scenarios/test_map_base.ini...")
	var success: bool = await save_test_scenario()

	if success:
		print("\n✅ SUCCESS! Test scenario saved!")
		print("   Location: res://test/scenarios/test_map_base.ini")
		print("\nNext steps:")
		print("   1. Update IntegrationTestBase._initialize_minimal_world()")
		print("   2. Replace start_new_game() with load_scenario('test_map_base')")
		print("   3. Run integration tests to verify")
	else:
		print("\n❌ FAILED to save test scenario")
		print("   Check console for errors")

	print("\n========================================\n")

	# Exit after a short delay
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()


func save_test_scenario() -> bool:
	"""
	Saves the current game state as a test scenario.
	Returns true if successful.
	"""
	var player_data: Dictionary = {}
	var player : Player = game_session.turn_orchestrator.player
	if player:
		player_data = player.on_save_data()

	var save_data : Dictionary = {
		Persistence.SECTION.GAME: { "turn_number": game_session.turn_orchestrator.current_turn },
		Persistence.SECTION.WORLD: world_manager.world_gen.on_save_data(),
		Persistence.SECTION.CAMERA: world_manager.world_camera.on_save_data(),
		Persistence.SECTION.PLAYER: player_data,
	}
	
	Persistence.game_name = "test"
	return Persistence.save_game(game_session, save_data)
