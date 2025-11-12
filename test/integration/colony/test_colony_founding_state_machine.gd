extends IntegrationTestBase
## Integration tests for colony founding state machine validation

func before_each() -> void:
	await setup_world()


func after_each() -> void:
	super.after_each()


#region STATE MACHINE TESTS

func test_initial_state_is_idle() -> void:
	# Arrange
	var colony_manager : ColonyManager = player.cm

	# Assert
	assert_colony_founding_state(colony_manager, ColonyFoundingWorkflow.State.IDLE)
	assert_true(colony_manager.workflow.can_start_founding(), "Should be able to start founding from IDLE")
	assert_false(colony_manager.workflow.is_founding(), "Should not be founding initially")


func test_found_colony_transitions_to_founding_then_confirming() -> void:
	# Arrange
	var tile_pos: Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler: UnitStats = autofree(create_mock_settler(1))
	var colony_manager: ColonyManager = player.cm

	# Act - found colony
	var result: ColonyFoundingWorkflow.Result = colony_manager.found_colony(tile_pos, world_pos, settler)
	if result.is_error():
		assert_true(false, "Failed to found colony: %s" % result.get_error())
	await wait_physics_frames(1)

	# Assert - should be in CONFIRMING (skips FOUNDING internally and goes straight to CONFIRMING)
	assert_true(result.is_ok())
	assert_colony_founding_state(colony_manager, ColonyFoundingWorkflow.State.CONFIRMING)
	assert_true(colony_manager.workflow.is_founding(), "Should be in founding process")
	assert_false(colony_manager.workflow.can_start_founding(), "Should not be able to start new founding")


func test_create_colony_transitions_to_founded_then_idle() -> void:
	# Arrange - found a colony first
	var tile_pos: Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler: UnitStats = autofree(create_mock_settler(1))
	var colony_manager: ColonyManager = player.cm

	var res1: ColonyFoundingWorkflow.Result = colony_manager.found_colony(tile_pos, world_pos, settler)
	if res1.is_error():
		assert_true(false, "Failed to found colony: %s" % res1.get_error())
	await wait_physics_frames(1)

	assert_colony_founding_state(colony_manager, ColonyFoundingWorkflow.State.CONFIRMING)

	# Act - create colony
	var res2: ColonyFoundingWorkflow.Result = colony_manager.create_colony()
	if res2.is_error():
		assert_true(false, "Failed to create colony: %s" % res2.get_error())
	await wait_physics_frames(1)

	# Assert - should reset to IDLE after completion
	assert_true(res2.is_ok())
	assert_colony_founding_state(colony_manager, ColonyFoundingWorkflow.State.IDLE)
	assert_false(colony_manager.workflow.is_founding(), "Should not be founding after completion")
	assert_true(colony_manager.workflow.can_start_founding(), "Should be able to start new founding")


func test_cancel_colony_transitions_to_cancelled_then_idle() -> void:
	# Arrange - found a colony first
	var tile_pos: Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler: UnitStats = autofree(create_mock_settler(1))

	var result: ColonyFoundingWorkflow.Result = player.cm.found_colony(tile_pos, world_pos, settler)
	if result.is_error():
		assert_true(false, "Failed to start founding: %s" % result.error_message)
	await wait_physics_frames(1)

	assert_colony_founding_state(player.cm, ColonyFoundingWorkflow.State.CONFIRMING)

	# Act - cancel colony
	var cancel_result: ColonyFoundingWorkflow.Result = player.cm.cancel_found_colony()
	await wait_physics_frames(1)

	# Assert - should reset to IDLE after cancellation
	assert_true(cancel_result.is_ok(), "Cancel should succeed but got: %s" % cancel_result.error_message)
	assert_not_null(cancel_result.value, "Cancel should return settler unit")
	assert_true(cancel_result.value is SettlerUnit, "Cancel should return a SettlerUnit")
	assert_colony_founding_state(player.cm, ColonyFoundingWorkflow.State.IDLE)
	assert_false(player.cm.workflow.is_founding(), "Should not be founding after cancel")
	assert_true(player.cm.workflow.can_start_founding(), "Should be able to start new founding")


func test_cannot_skip_states() -> void:
	# Test that you cannot go from IDLE -> FOUNDED without going through FOUNDING/CONFIRMING

	# Try to complete founding without starting
	var dummy_colony: CenterBuilding = autofree(CenterBuilding.new())
	var result: ColonyFoundingWorkflow.Result = player.cm.workflow.complete_founding(dummy_colony)

	assert_true(result.is_error(), "Should not be able to complete from IDLE")
	assert_colony_founding_state(player.cm, ColonyFoundingWorkflow.State.IDLE)


func test_cannot_cancel_from_idle() -> void:
	# Try to cancel when not founding
	var result: ColonyFoundingWorkflow.Result = player.cm.cancel_found_colony()

	assert_true(result.is_error(), "Should not be able to cancel from IDLE")
	assert_colony_founding_state(player.cm, ColonyFoundingWorkflow.State.IDLE)


func test_workflow_context_preserved_during_founding() -> void:
	# Arrange
	var tile_pos: Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler: UnitStats = autofree(create_mock_settler(2))  # Level 2
	var colony_manager: ColonyManager = player.cm

	# Act - found colony
	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)

	# Assert - context should be preserved
	assert_not_null(colony_manager.workflow.context, "Context should exist during founding")
	assert_eq(colony_manager.workflow.context.target_tile, tile_pos, "Target tile should match")
	assert_eq(colony_manager.workflow.context.settler_position, world_pos, "Settler position should match")
	assert_eq(colony_manager.workflow.context.settler_stats.level, 2, "Settler level should be preserved")


func test_workflow_context_cleared_after_completion() -> void:
	# Arrange - complete full founding cycle
	var tile_pos: Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler: UnitStats = autofree(create_mock_settler(1))
	var colony_manager: ColonyManager = player.cm

	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)

	# Act - complete colony
	colony_manager.create_colony()
	await wait_physics_frames(1)

	# Assert - context should be cleared
	assert_colony_founding_state(colony_manager, ColonyFoundingWorkflow.State.IDLE)
	assert_null(colony_manager.workflow.context, "Context should be cleared after completion")


func test_workflow_context_cleared_after_cancel() -> void:
	# Arrange - start and cancel founding
	var tile_pos: Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler: UnitStats = autofree(create_mock_settler(1))
	var colony_manager: ColonyManager = player.cm

	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)

	# Act - cancel colony
	colony_manager.cancel_found_colony()
	await wait_physics_frames(1)

	# Assert - context should be cleared
	assert_colony_founding_state(colony_manager, ColonyFoundingWorkflow.State.IDLE)
	assert_null(colony_manager.workflow.context, "Context should be cleared after cancel")


func test_get_state_name_returns_readable_string() -> void:
	# Test that state names are human-readable
	assert_eq(player.cm.workflow.get_state_name(), "IDLE", "Should return IDLE initially")

	# Transition to CONFIRMING
	var tile_pos: Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler: UnitStats = autofree(create_mock_settler(1))
	var colony_manager: ColonyManager = player.cm

	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)

	assert_eq(colony_manager.workflow.get_state_name(), "CONFIRMING", "Should return CONFIRMING")

#endregion
