extends GutTest
class_name IntegrationTestBase
## Base class for integration tests
##
## Integration tests load full game scenes and test system interactions.
## This base class provides utilities for:
## - Loading test scenarios (saved game states)
## - Setting up world manager and game systems with fast test map generation
## - Creating entities (colonies, buildings, units)
## - Cleaning up after tests
##
## Performance: Uses WorldGen.skip_generation flag to generate a simple 48x48
## test map instead of expensive procedural generation (no rivers, mountains, etc.)
##
## Usage:
##   extends IntegrationTestBase
##   func test_my_scenario():
##       setup_world()  # Uses fast test map by default
##       var colony = create_test_colony(Vector2i(10, 10))
##       # ... test logic


#region TEST WORLD MANAGEMENT

"""
Run generate_test_scenario.gd
"""
const TEST_MAP: String = "test_scenario_00"

## Reference to the GameController for this test
var game_controller: GameController = null

## Reference to the GameSession for this test
var game_session: GameSession = null

## Reference to the WorldManager for this test
var world_manager: WorldManager = null

## Reference to player for convenience
var player: Player = null


## Sets up a minimal game world for testing
## Call this in before_each() or at the start of each test
func setup_world(_map_name: String = TEST_MAP) -> void:
	# Create GameController (root orchestrator)
	game_controller = autofree(GameController.new())
	add_child_autofree(game_controller)

	# Start a new test game (this creates WorldManager and GameSession internally)
	# Note: We're bypassing GameController._ready() auto-load to control initialization
	game_controller._setup_game()
	await wait_physics_frames(1)

	# Get references to created instances
	game_session = game_controller.game_session
	world_manager = game_controller.world_manager

	# Initialize with minimal map
	await _initialize_minimal_world(_map_name)

	# Get player reference from TurnOrchestrator
	player = game_session.turn_orchestrator.player as Player

	# Wait for everything to initialize
	await wait_physics_frames(2)


## Initialize a minimal world (small map, no fancy generation)
func _initialize_minimal_world(_map_name: String) -> void:
	game_session.load_game(_map_name)
	await wait_physics_frames(1)


## Loads a test scenario from a saved game file
##
## @param scenario_name: Name of the scenario file (without .ini extension)
## @returns: true if loaded successfully
func load_scenario(scenario_name: String) -> bool:
	var scenario_path: String = "res://test/scenarios/" + scenario_name + ".ini"

	# Check if scenario file exists
	if not FileAccess.file_exists(scenario_path):
		push_error("Scenario file not found: " + scenario_path)
		return false

	# Load the scenario using persistence system
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(scenario_path)
	if err != OK:
		push_error("Failed to load scenario: " + scenario_name)
		return false

	# Setup world if not already done
	if world_manager == null:
		setup_world()
		await wait_physics_frames(1)

	# Load session data
	var session_data: Dictionary = {}
	for key: String in config.get_section_keys(Persistence.SECTION.SESSION):
		session_data[key] = config.get_value(Persistence.SECTION.SESSION, key)

	# Load world data (includes camera state)
	var world_data: Dictionary = {}
	for key: String in config.get_section_keys(Persistence.SECTION.WORLD):
		world_data[key] = config.get_value(Persistence.SECTION.WORLD, key)

	# Extract camera data from world section
	var camera_data: Dictionary = {
		"position": world_data.get("camera_position", Vector2.ZERO),
		"zoom_val": world_data.get("camera_zoom_val", 1.0),
	}

	# Load player data
	var player_data: Dictionary = {}
	for key: String in config.get_section_keys(Persistence.SECTION.PLAYER):
		player_data[key] = config.get_value(Persistence.SECTION.PLAYER, key)

	# Load data into components (matches GameSession.load_game pattern)
	game_session.turn_orchestrator.current_turn = session_data.get("turn_number", 0)
	world_manager.world_gen.on_load_data(world_data)
	world_manager.world_camera.on_load_data(camera_data)
	game_session.turn_orchestrator.player.on_load_data(player_data)

	await wait_physics_frames(2)
	return true

#endregion


#region HELPER UTILITIES

## Convert string resource name to ResourceType enum
func _string_to_resource_type(resource_name: String) -> Term.ResourceType:
	match resource_name.to_lower():
		"gold": return Term.ResourceType.GOLD
		"wood": return Term.ResourceType.WOOD
		"crops": return Term.ResourceType.CROPS
		"metal": return Term.ResourceType.METAL
		"goods": return Term.ResourceType.GOODS
		_:
			push_error("Unknown resource type: " + resource_name)
			return Term.ResourceType.NONE

#endregion


#region ENTITY CREATION HELPERS

## Creates a test colony at the specified position
##
## @param tile_pos: Map position for the colony
## @param starting_resources: Optional resource dict (defaults to 1000 of each)
## @returns: The created CenterBuilding
func create_test_colony(tile_pos: Vector2i, starting_resources: Dictionary = {}) -> CenterBuilding:
	assert_not_null(player, "Player must be initialized (call setup_world first)")

	# Default resources if not specified
	if starting_resources.is_empty():
		starting_resources = {
			"gold": 1000,
			"wood": 1000,
			"crops": 1000,
			"metal": 1000,
			"goods": 1000
		}

	# Create settler stats (without resources - those are in player's bank)
	var settler_stats: UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, 1)
	settler_stats.player = player

	# Found the colony through ColonyManager
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	player.cm.found_colony(tile_pos, world_pos, settler_stats)

	await wait_physics_frames(1)

	# Get the colony that was just added (should be the placing_colony)
	var colony: CenterBuilding = player.cm.placing_colony
	assert_not_null(colony, "Colony should have been created")

	# Add starting resources to the colony's bank
	for resource_name: String in starting_resources:
		var resource_type: Term.ResourceType = _string_to_resource_type(resource_name)
		colony.bank.set_resource_value(resource_type, starting_resources[resource_name])

	return colony


## Creates a building in the specified colony
##
## @param colony: The colony to build in
## @param building_type: Type of building to create
## @param tile_pos: Map position for the building
## @param level: Building level (1-4)
## @returns: The created Building
func create_test_building(colony: CenterBuilding, building_type: Term.BuildingType, tile_pos: Vector2i, level: int = 1) -> Building:
	assert_not_null(colony, "Colony cannot be null")
	assert_true(level >= 1 and level <= 4, "Building level must be 1-4")

	# Get building scene (using updated API)
	var building_scene: PackedScene = PreloadsRef.get_building_scene(building_type)
	var building: Building = building_scene.instantiate() as Building

	# Set building properties
	building.building_type = building_type
	building.level = level
	building.building_state = Term.BuildingState.ACTIVE
	building.colony = colony
	building.player = player

	# Position the building
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	building.global_position = world_pos

	# Add to colony's building manager
	colony.bm.add_child(building)
	colony.bm.buildings.append(building)

	await wait_physics_frames(1)
	return building


## Creates a test unit at the specified position
##
## @param unit_type: Type of unit to create
## @param tile_pos: Map position for the unit
## @param level: Unit level (1-5)
## @returns: The created Unit
func create_test_unit(unit_type: Term.UnitType, tile_pos: Vector2i, level: int = 1) -> Unit:
	assert_not_null(player, "Player must be initialized (call setup_world first)")
	assert_true(level >= 1 and level <= 5, "Unit level must be 1-5")

	# Create unit stats
	var unit_stats: UnitStats = UnitStats.new()
	unit_stats.unit_type = unit_type
	unit_stats.level = level
	unit_stats.player = player
	unit_stats.health = 100

	# Create unit through player system
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var unit: Unit = player.create_unit(unit_stats, world_pos)

	await wait_physics_frames(1)
	return unit

#endregion


#region SIMULATION HELPERS

## Simulates N turns of the game
##
## @param num_turns: Number of turns to simulate
func simulate_turns(num_turns: int) -> void:
	for i: int in range(num_turns):
		game_session.end_turn()
		await wait_physics_frames(1)


## Processes a single turn for all colonies
## Useful for testing production calculations
func process_colony_turn() -> void:
	for colony: CenterBuilding in player.cm.colonies:
		colony.begin_turn()
	await wait_physics_frames(1)

#endregion


#region COLONY FOUNDING HELPERS

## Assert that the colony manager is in the expected workflow state
func assert_colony_founding_state(cm: ColonyManager, expected_state: ColonyFoundingWorkflow.State, message: String = "") -> void:
	var msg: String = message if message != "" else "ColonyManager should be in state %s" % ColonyFoundingWorkflow.State.keys()[expected_state]
	assert_eq(cm.workflow.current_state, expected_state, msg)


## Create a mock settler stats for testing colony founding
func create_mock_settler(level: int = 1) -> UnitStats:
	var settler: UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, level)
	settler.player = player
	return settler


## Assert no orphan colonies exist (all colonies have proper parent references)
func assert_no_orphan_colonies() -> void:
	for colony: CenterBuilding in player.cm.colonies:
		assert_not_null(colony.player, "Colony should have player reference")
		assert_not_null(colony.bm, "Colony should have building manager")


## Assert that a settler unit exists at the specified position
func assert_settler_at_position(position: Vector2, tolerance: float = 5.0, message: String = "") -> Unit:
	var settler: Unit = null
	for unit: Unit in player.units:
		if unit.stat.unit_type == Term.UnitType.SETTLER:
			if unit.global_position.distance_to(position) < tolerance:
				settler = unit
				break

	var msg: String = message if message != "" else "Settler should exist at position " + str(position)
	assert_not_null(settler, msg)
	return settler


## Assert that colony tiles are marked as occupied
func assert_colony_tiles_occupied(colony: CenterBuilding, message: String = "") -> void:
	var tiles: Array[Vector2i] = colony.get_tiles()
	for tile: Vector2i in tiles:
		var is_occupied: bool = colony.bm.is_tile_occupied(tile)
		var msg: String = message if message != "" else "Tile %s should be occupied" % str(tile)
		assert_true(is_occupied, msg)


## Assert that colony tiles are NOT marked as occupied
func assert_colony_tiles_not_occupied(tiles: Array[Vector2i], message: String = "") -> void:
	for tile: Vector2i in tiles:
		var is_occupied: bool = player.cm.get_colonies()[0].bm.is_tile_occupied(tile) if player.cm.get_colonies().size() > 0 else false
		var msg: String = message if message != "" else "Tile %s should NOT be occupied" % str(tile)
		assert_false(is_occupied, msg)


## Get all tiles that would be occupied by a colony at the given position
func get_colony_tiles(tile_pos: Vector2i) -> Array[Vector2i]:
	# Assuming 2x2 colony size
	return [
		tile_pos,
		tile_pos + Vector2i(1, 0),
		tile_pos + Vector2i(0, 1),
		tile_pos + Vector2i(1, 1)
	]

#endregion


#region ASSERTION HELPERS

## Asserts that a colony exists at the specified position
func assert_colony_exists(tile_pos: Vector2i, message: String = "") -> CenterBuilding:
	var colony: CenterBuilding = null
	for c: CenterBuilding in player.cm.colonies:
		var colony_tile: Vector2i = world_manager.world_gen.get_local_to_map_position(c.global_position)
		if colony_tile == tile_pos:
			colony = c
			break

	var msg: String = message if message != "" else "Colony should exist at " + str(tile_pos)
	assert_not_null(colony, msg)
	return colony


## Asserts that a building of the specified type exists in a colony
func assert_building_exists(colony: CenterBuilding, building_type: Term.BuildingType, message: String = "") -> Building:
	var building: Building = null
	for b: Building in colony.bm.buildings:
		if b.building_type == building_type:
			building = b
			break

	var msg: String = message if message != "" else "Building type " + str(building_type) + " should exist in colony"
	assert_not_null(building, msg)
	return building


## Asserts that a colony has at least the specified resources
func assert_colony_resources(colony: CenterBuilding, expected: Dictionary, message: String = "") -> void:
	for resource_name: String in expected:
		var resource_type: Term.ResourceType = _string_to_resource_type(resource_name)
		var actual: int = colony.bank.get_resource_value(resource_type)
		var expected_amount: int = expected[resource_name]

		var msg: String = message if message != "" else resource_name + " should be at least " + str(expected_amount)
		assert_gte(actual, expected_amount, msg)


## Asserts that a production transaction matches expected values
func assert_production(actual: Transaction, expected: Dictionary, message: String = "") -> void:
	for resource_name: String in expected:
		var resource_type: Term.ResourceType = _string_to_resource_type(resource_name)
		var actual_amount: int = actual.get_resource_amount(resource_type)
		var expected_amount: int = expected[resource_name]

		var msg: String = message if message != "" else resource_name + " production should be " + str(expected_amount)
		assert_eq(actual_amount, expected_amount, msg)

#endregion


#region LIFECYCLE HOOKS

func before_each() -> void:
	# Subclasses can override to add setup
	pass


func after_each() -> void:
	# Cleanup is automatic via autofree
	game_controller = null
	game_session = null
	world_manager = null
	player = null

#endregion
