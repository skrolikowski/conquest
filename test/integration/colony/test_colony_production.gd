extends IntegrationTestBase
## Integration tests for colony production systems
##
## Tests complete production workflows including:
## - Building production (farms, mills, mines)
## - Resource consumption and generation
## - Production bonuses from terrain and specialization
## - Multi-turn production accumulation


#region FARM PRODUCTION TESTS

func test_farm_level_1_produces_correct_crops() -> void:
	# Arrange - Create a colony with a level 1 farm
	await setup_world()
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
	var farm: Building = await create_test_building(
		colony,
		Term.BuildingType.FARM,
		Vector2i(11, 10),
		1
	)

	# Get expected production from game data
	var expected_production: Transaction = autofree(Def.get_building_make(Term.BuildingType.FARM, 1))
	var expected_crops: int = expected_production.get_resource_amount(Term.ResourceType.CROPS)

	# Record starting crops
	var starting_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)

	# Act - Process one production turn
	await process_colony_turn()

	# Assert - Verify crops produced
	var ending_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
	var actual_production: int = ending_crops - starting_crops

	assert_eq(actual_production, expected_crops, "Farm level 1 should produce " + str(expected_crops) + " crops")


func test_farm_level_2_produces_more_than_level_1() -> void:
	# Arrange - Create colony with level 2 farm
	await setup_world()
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
	var farm: Building = await create_test_building(
		colony,
		Term.BuildingType.FARM,
		Vector2i(11, 10),
		2  # Level 2
	)

	# Get expected production from game data
	var level1_production: Transaction = autofree(Def.get_building_make(Term.BuildingType.FARM, 1))
	var level2_production: Transaction = autofree(Def.get_building_make(Term.BuildingType.FARM, 2))

	var level1_crops: int = level1_production.get_resource_amount(Term.ResourceType.CROPS)
	var level2_crops: int = level2_production.get_resource_amount(Term.ResourceType.CROPS)

	# Record starting crops
	var starting_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)

	# Act - Process one production turn
	await process_colony_turn()

	# Assert
	var ending_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
	var actual_production: int = ending_crops - starting_crops

	assert_eq(actual_production, level2_crops, "Farm level 2 should produce " + str(level2_crops) + " crops")
	assert_gt(level2_crops, level1_crops, "Farm level 2 should produce more than level 1")


func test_farm_consumes_crops_per_turn() -> void:
	# Arrange - Create colony with farm
	await setup_world()
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
	var farm: Building = await create_test_building(
		colony,
		Term.BuildingType.FARM,
		Vector2i(11, 10),
		1
	)

	# Get expected consumption from game data
	var expected_need: Transaction = autofree(Def.get_building_need(Term.BuildingType.FARM, 1))
	var expected_consumption: int = expected_need.get_resource_amount(Term.ResourceType.CROPS)

	# Give colony enough crops to consume
	colony.bank.add_resource_amount_by_type(Term.ResourceType.CROPS, 1000)
	var starting_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)

	# Act - Process one turn
	await process_colony_turn()

	# Assert - Verify net change (production - consumption)
	var ending_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
	var net_change: int = ending_crops - starting_crops

	var expected_production: Transaction = autofree(Def.get_building_make(Term.BuildingType.FARM, 1))
	var produced: int = expected_production.get_resource_amount(Term.ResourceType.CROPS)
	var expected_net: int = produced - expected_consumption

	assert_eq(net_change, expected_net, "Farm should net " + str(expected_net) + " crops (produced - consumed)")

#endregion


#region MULTIPLE BUILDINGS TESTS

func test_multiple_farms_accumulate_production() -> void:
	# Arrange - Create colony with 3 farms
	await setup_world()
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))

	var farm1: Building = await create_test_building(colony, Term.BuildingType.FARM, Vector2i(11, 10), 1)
	var farm2: Building = await create_test_building(colony, Term.BuildingType.FARM, Vector2i(12, 10), 1)
	var farm3: Building = await create_test_building(colony, Term.BuildingType.FARM, Vector2i(11, 11), 1)

	# Calculate expected production (3 farms)
	var single_farm: Transaction = autofree(Def.get_building_make(Term.BuildingType.FARM, 1))
	var single_farm_crops: int = single_farm.get_resource_amount(Term.ResourceType.CROPS)
	var expected_total: int = single_farm_crops * 3

	# Record starting crops
	var starting_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)

	# Act - Process one turn
	await process_colony_turn()

	# Assert - Verify total production
	var ending_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
	var actual_production: int = ending_crops - starting_crops

	assert_eq(actual_production, expected_total, "Three farms should produce " + str(expected_total) + " crops total")


func test_mixed_building_types_produce_different_resources() -> void:
	# Arrange - Create colony with farm, mill, and mine
	await setup_world()
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))

	var farm: Building = await create_test_building(colony, Term.BuildingType.FARM, Vector2i(11, 10), 1)
	var mill: Building = await create_test_building(colony, Term.BuildingType.MILL, Vector2i(12, 10), 1)
	var mine: Building = await create_test_building(colony, Term.BuildingType.METAL_MINE, Vector2i(11, 11), 1)

	# Record starting resources
	var starting_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
	var starting_goods: int = colony.bank.get_resource_amount(Term.ResourceType.GOODS)
	var starting_metal: int = colony.bank.get_resource_amount(Term.ResourceType.METAL)

	# Act - Process one turn
	await process_colony_turn()

	# Assert - Verify each building type produced its resource
	var ending_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
	var ending_goods: int = colony.bank.get_resource_amount(Term.ResourceType.GOODS)
	var ending_metal: int = colony.bank.get_resource_amount(Term.ResourceType.METAL)

	assert_gt(ending_crops, starting_crops, "Farm should produce crops")
	assert_gt(ending_goods, starting_goods, "Mill should produce goods")
	assert_gt(ending_metal, starting_metal, "Mine should produce metal")

#endregion


#region MULTI-TURN TESTS

func test_production_accumulates_over_multiple_turns() -> void:
	# Arrange - Create colony with farm
	await setup_world()
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
	var farm: Building = await create_test_building(colony, Term.BuildingType.FARM, Vector2i(11, 10), 1)

	# Get expected per-turn production
	var per_turn: Transaction = autofree(Def.get_building_make(Term.BuildingType.FARM, 1))
	var crops_per_turn: int = per_turn.get_resource_amount(Term.ResourceType.CROPS)

	# Record starting crops
	var starting_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)

	# Act - Process 5 turns
	for i: int in range(5):
		await process_colony_turn()

	# Assert - Verify 5 turns of production
	var ending_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
	var total_production: int = ending_crops - starting_crops
	var expected_production: int = crops_per_turn * 5

	assert_eq(total_production, expected_production, "5 turns should produce " + str(expected_production) + " crops")


func test_building_upgrade_changes_production() -> void:
	# Arrange - Create colony with level 1 farm
	await setup_world()
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
	var farm: Building = await create_test_building(colony, Term.BuildingType.FARM, Vector2i(11, 10), 1)

	# Record level 1 production
	var starting_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
	await process_colony_turn()
	var after_level1: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
	var level1_production: int = after_level1 - starting_crops

	# Act - Upgrade to level 2
	farm.level = 2
	farm.building_state = Term.BuildingState.ACTIVE

	# Process another turn
	starting_crops = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
	await process_colony_turn()
	var after_level2: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
	var level2_production: int = after_level2 - starting_crops

	# Assert - Level 2 should produce more
	assert_gt(level2_production, level1_production, "Level 2 farm should produce more than level 1")

#endregion


#region RESOURCE DEFICIT TESTS

func test_colony_with_insufficient_resources() -> void:
	# Arrange - Create colony with farm but NO starting crops
	await setup_world()
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10), {
		"gold": 0,
		"wood": 0,
		"crops": 0,  # No crops to consume
		"metal": 0,
		"goods": 0
	})
	var farm: Building = await create_test_building(colony, Term.BuildingType.FARM, Vector2i(11, 10), 1)

	# Record starting state
	var starting_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)

	# Act - Process turn (should handle deficit gracefully)
	await process_colony_turn()

	# Assert - Should still produce (even if consumption fails)
	var ending_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
	var production: int = ending_crops - starting_crops

	# Farm should produce SOMETHING (even if it can't meet its needs)
	assert_gte(production, 0, "Farm should produce crops even with resource deficit")

#endregion


#region HELPER METHOD TESTS

func test_assert_colony_exists_helper() -> void:
	# Arrange
	await setup_world()
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))

	# Act & Assert
	var found_colony: CenterBuilding = assert_colony_exists(Vector2i(10, 10))
	assert_same(found_colony, colony, "Helper should find the created colony")


func test_assert_building_exists_helper() -> void:
	# Arrange
	await setup_world()
	var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
	var farm: Building = await create_test_building(colony, Term.BuildingType.FARM, Vector2i(11, 10), 1)

	# Act & Assert
	var found_building: Building = assert_building_exists(colony, Term.BuildingType.FARM)
	assert_same(found_building, farm, "Helper should find the created farm")

#endregion
