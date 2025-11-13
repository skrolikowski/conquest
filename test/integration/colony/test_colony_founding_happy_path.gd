extends IntegrationTestBase
## Integration tests for colony founding happy path scenarios


func before_each() -> void:
	await setup_world()


func after_each() -> void:
	super.after_each()


#region HAPPY PATH TESTS

func test_found_colony_creates_colony_at_tile() -> void:
	# Arrange
	var tile_pos       : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos      : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler        : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	# Act
	var result: ColonyFoundingWorkflow.Result = colony_manager.found_colony(tile_pos, world_pos, settler)
	if result.is_error():
		assert_true(false, "Failed to found colony: %s" % result.error_message)
		return
	await wait_physics_frames(1)

	# Assert
	assert_true(result.is_ok(), "Colony founding should succeed")
	assert_colony_founding_state(colony_manager, ColonyFoundingWorkflow.State.CONFIRMING)
	assert_not_null(colony_manager.placing_colony, "Placing colony should exist")
	assert_eq(colony_manager.colonies.size(), 1, "Should have 1 colony in colonies array")


func test_create_colony_transitions_to_active() -> void:
	# Arrange
	var tile_pos       : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos      : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler        : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)

	assert_colony_founding_state(colony_manager, ColonyFoundingWorkflow.State.CONFIRMING)
	var colony: CenterBuilding = colony_manager.placing_colony

	# Act - confirm the colony
	var result: ColonyFoundingWorkflow.Result = colony_manager.create_colony()
	await wait_physics_frames(1)

	# Assert
	assert_true(result.is_ok(), "Colony creation should succeed")
	assert_colony_founding_state(colony_manager, ColonyFoundingWorkflow.State.IDLE)
	assert_eq(colony.modulate.a, 1.0, "Colony should be fully opaque (active)")
	assert_colony_tiles_occupied(colony, "Colony tiles should be occupied")
	assert_eq(colony_manager.colonies.size(), 1, "Should still have 1 colony")


func test_cancel_found_colony_restores_settler() -> void:
	# Arrange
	var tile_pos       : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos      : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler        : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)

	# var colony_tiles: Array[Vector2i] = get_colony_tiles(tile_pos)
	assert_colony_founding_state(colony_manager, ColonyFoundingWorkflow.State.CONFIRMING)

	# Act - cancel the colony
	var result: ColonyFoundingWorkflow.Result = colony_manager.cancel_found_colony()
	await wait_physics_frames(1)

	# Assert
	assert_true(result.is_ok(), "Colony cancellation should succeed")
	assert_colony_founding_state(colony_manager, ColonyFoundingWorkflow.State.IDLE)
	assert_eq(colony_manager.colonies.size(), 0, "Should have 0 colonies after cancel")

	# Check settler was restored
	var settler_unit: Unit = assert_settler_at_position(world_pos, 50.0)
	assert_eq(settler_unit.stat.unit_type, Term.UnitType.SETTLER, "Restored unit should be settler")


func test_sequential_colony_founding() -> void:
	# Test founding multiple colonies sequentially (not concurrently)

	# Arrange
	var tile_pos_1     : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos_1    : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos_1)
	var settler_1      : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	var result_1: ColonyFoundingWorkflow.Result = colony_manager.found_colony(tile_pos_1, world_pos_1, settler_1)
	await wait_physics_frames(1)

	assert_true(result_1.is_ok())
	colony_manager.create_colony()
	await wait_physics_frames(1)

	assert_colony_founding_state(colony_manager, ColonyFoundingWorkflow.State.IDLE)

	# Found second colony
	var tile_pos_2  : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos_2 : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos_2)
	var settler_2   : UnitStats = autofree(create_mock_settler(1))

	var result_2: ColonyFoundingWorkflow.Result = colony_manager.found_colony(tile_pos_2, world_pos_2, settler_2)
	await wait_physics_frames(1)

	assert_true(result_2.is_ok())
	colony_manager.create_colony()
	await wait_physics_frames(1)

	# Assert both colonies exist
	assert_eq(colony_manager.colonies.size(), 2, "Should have 2 colonies")
	assert_colony_founding_state(colony_manager, ColonyFoundingWorkflow.State.IDLE)


func test_undo_create_colony_restores_settler() -> void:
	# Arrange - create a NEW colony (not yet active)
	var tile_pos       : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos      : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler        : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)
	colony_manager.create_colony()
	await wait_physics_frames(1)

	var colony: CenterBuilding = colony_manager.colonies[0]
	var colony_position : Vector2 = colony.global_position
	assert_eq(colony.building_state, Term.BuildingState.NEW, "Colony should be in NEW state")

	# Act - undo the colony
	var result: ColonyFoundingWorkflow.Result = colony_manager.undo_create_colony(colony)
	await wait_physics_frames(1)

	# Assert
	assert_true(result.is_ok(), "Undo should succeed")
	assert_eq(colony_manager.colonies.size(), 0, "Should have 0 colonies after undo")

	# Check settler was restored
	var settler_unit: Unit = assert_settler_at_position(colony_position, 50.0)
	assert_eq(settler_unit.stat.unit_type, Term.UnitType.SETTLER, "Restored unit should be settler")

#endregion
