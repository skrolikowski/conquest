extends GutTest
class_name IntegrationTestBase
## Base class for integration tests
##
## Integration tests load full game scenes and test system interactions.
## This base class provides utilities for:
## - Loading test scenarios (saved game states)
## - Setting up world manager and game systems
## - Creating entities (colonies, buildings, units)
## - Cleaning up after tests
##
## Usage:
##   extends IntegrationTestBase
##   func test_my_scenario():
##       setup_world()
##       var colony = create_test_colony(Vector2i(10, 10))
##       # ... test logic


#region TEST WORLD MANAGEMENT

## Reference to the instantiated WorldManager for this test
var world_manager: WorldManager = null

## Reference to player for convenience
var player: Player = null


## Sets up a minimal game world for testing
## Call this in before_each() or at the start of each test
func setup_world() -> void:
	# Instantiate the main game scene
	var world_scene: PackedScene = load("res://scenes/world_manager.tscn")
	world_manager = autofree(world_scene.instantiate()) as WorldManager

	# Add to scene tree so autoloads can find it
	add_child_autofree(world_manager)

	# Initialize with minimal map
	_initialize_minimal_world()

	# Get player reference
	player = world_manager.turn_orchestrator.player as Player

	# Wait for everything to initialize
	await wait_frames(2)


## Initialize a minimal world (small map, no fancy generation)
func _initialize_minimal_world() -> void:
	# For now, just initialize with default map generation
	# TODO: Add skip_generation flag and generate_test_map() to WorldGen
	await wait_frames(1)


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
		await wait_frames(1)

	# Load world data
	var world_data: Dictionary = {}
	for key: String in config.get_section_keys(Persistence.SECTION.WORLD):
		world_data[key] = config.get_value(Persistence.SECTION.WORLD, key)
	world_manager.world_gen.on_load_data(world_data)

	# Load player data
	var player_data: Dictionary = {}
	for key: String in config.get_section_keys(Persistence.SECTION.PLAYER):
		player_data[key] = config.get_value(Persistence.SECTION.PLAYER, key)
	world_manager.turn_orchestrator.on_load_data(player_data)

	await wait_frames(2)
	return true

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

	# Create settler stats with resources
	var settler_stats: UnitStats = UnitStats.new()
	settler_stats.unit_type = Term.UnitType.SETTLER
	settler_stats.level = 1
	settler_stats.player = player
	settler_stats.resources.add_resources(starting_resources)

	# Found the colony through ColonyManager
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	player.cm.found_colony(tile_pos, world_pos, settler_stats)

	await wait_frames(1)

	# Get the colony that was just added (should be the last one)
	var colony: CenterBuilding = player.cm.placing_colony
	assert_not_null(colony, "Colony should have been created")
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

	# Get building scene
	var building_scene: PackedScene = Def.get_building_scene_by_type(building_type)
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

	await wait_frames(1)
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

	await wait_frames(1)
	return unit

#endregion


#region SIMULATION HELPERS

## Simulates N turns of the game
##
## @param num_turns: Number of turns to simulate
func simulate_turns(num_turns: int) -> void:
	for i: int in range(num_turns):
		world_manager.end_turn()
		await wait_frames(1)


## Processes a single turn for all colonies
## Useful for testing production calculations
func process_colony_turn() -> void:
	for colony: CenterBuilding in player.cm.colonies:
		colony.begin_turn()
	await wait_frames(1)

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
		var resource_type: Term.ResourceType = Def._convert_to_resource_type(resource_name)
		var actual: int = colony.bank.get_resource_amount(resource_type)
		var expected_amount: int = expected[resource_name]

		var msg: String = message if message != "" else resource_name + " should be at least " + str(expected_amount)
		assert_gte(actual, expected_amount, msg)


## Asserts that a production transaction matches expected values
func assert_production(actual: Transaction, expected: Dictionary, message: String = "") -> void:
	for resource_name: String in expected:
		var resource_type: Term.ResourceType = Def._convert_to_resource_type(resource_name)
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
	world_manager = null
	player = null

#endregion
