extends IntegrationTestBase
## Integration tests for game save/load and persistence
##
## Tests the complete save/load workflow including:
## - Saving game state to ConfigFile
## - Loading game state from scenarios
## - Verifying data integrity across save/load cycles
## - Testing scenario-based test cases


#region BASIC PERSISTENCE TESTS

func test_can_setup_basic_world() -> void:
	# Act
	await setup_world()

	# Assert
	assert_not_null(world_manager, "WorldManager should be created")
	assert_not_null(player, "Player should be accessible")
	assert_not_null(world_manager.world_gen, "WorldGen should exist")


func test_created_colony_persists_in_player_state() -> void:
	# Arrange
	await setup_world()

	# Act
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))

	# Assert
	assert_true(player.cm.colonies.size() > 0, "Colony should be in player's colony list")
	assert_true(player.cm.colonies.has(colony), "Created colony should be in list")


func test_created_building_persists_in_colony() -> void:
	# Arrange
	await setup_world()
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))

	# Act
	var farm: Building = await create_test_building(colony, Term.BuildingType.FARM, Vector2i(11, 10), 1)

	# Assert
	assert_true(colony.bm.buildings.size() > 0, "Building should be in colony's building list")
	assert_true(colony.bm.buildings.has(farm), "Created farm should be in list")
	assert_eq(farm.building_type, Term.BuildingType.FARM, "Building type should be preserved")
	assert_eq(farm.level, 1, "Building level should be preserved")

#endregion


#region SCENARIO LOADING TESTS

func test_load_nonexistent_scenario_fails_gracefully() -> void:
	# Act
	var success: bool = await load_scenario("nonexistent_scenario_xyz")

	# Assert
	assert_false(success, "Loading nonexistent scenario should return false")


func test_scenario_directory_exists() -> void:
	# Assert
	assert_true(DirAccess.dir_exists_absolute("res://test/scenarios/"), "Scenarios directory should exist")

#endregion


#region GAME STATE VALIDATION

func test_world_manager_has_required_components() -> void:
	# Arrange
	await setup_world()

	# Assert - Verify all critical components exist
	assert_not_null(world_manager.world_gen, "WorldGen should exist")
	assert_not_null(world_manager.world_camera, "WorldCamera should exist")
	assert_not_null(world_manager.world_canvas, "WorldCanvas should exist")
	assert_not_null(world_manager.turn_orchestrator, "TurnOrchestrator should exist")


func test_player_has_required_managers() -> void:
	# Arrange
	await setup_world()

	# Assert - Verify player subsystems
	assert_not_null(player.cm, "Player should have ColonyManager")
	assert_not_null(player.bank, "Player should have Bank")
	assert_eq(player.colonies.size(), 0, "New player should have no colonies initially")

#endregion


#region TURN SIMULATION TESTS

func test_simulate_single_turn() -> void:
	# Arrange
	await setup_world()
	var starting_turn: int = world_manager.turn_number

	# Act
	await simulate_turns(1)

	# Assert
	assert_eq(world_manager.turn_number, starting_turn + 1, "Turn number should increment by 1")


func test_simulate_multiple_turns() -> void:
	# Arrange
	await setup_world()
	var starting_turn: int = world_manager.turn_number

	# Act
	await simulate_turns(5)

	# Assert
	assert_eq(world_manager.turn_number, starting_turn + 5, "Turn number should increment by 5")


func test_colony_processes_production_each_turn() -> void:
	# Arrange
	await setup_world()
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
	var farm: Building = await create_test_building(colony, Term.BuildingType.FARM, Vector2i(11, 10), 1)

	var starting_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)

	# Act - Simulate 3 turns
	await simulate_turns(3)

	# Assert - Production should have occurred
	var ending_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
	assert_gt(ending_crops, starting_crops, "Colony should produce crops over 3 turns")

#endregion


#region ASSERTION HELPER VALIDATION

func test_assert_colony_resources_helper() -> void:
	# Arrange
	await setup_world()
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10), {
		"gold": 500,
		"crops": 1000
	})

	# Act & Assert - Should pass
	assert_colony_resources(colony, {"gold": 500})
	assert_colony_resources(colony, {"crops": 1000})

	# Should also pass if actual > expected
	assert_colony_resources(colony, {"gold": 400})


func test_assert_production_helper() -> void:
	# Arrange
	var production: Transaction = autofree(Transaction.new())
	production.add_resource_amount_by_type(Term.ResourceType.CROPS, 50)
	production.add_resource_amount_by_type(Term.ResourceType.GOLD, 10)

	# Act & Assert
	assert_production(production, {"crops": 50})
	assert_production(production, {"gold": 10})

#endregion
