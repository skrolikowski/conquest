extends IntegrationTestBase
## Integration tests for colony founding error cases


func before_each() -> void:
	await setup_world()


func after_each() -> void:
	super.after_each()


#region ERROR CASE TESTS

func test_found_colony_on_water_fails() -> void:
	# Arrange - find a water tile (height <= -0.01)
	var water_tile: Vector2i = Vector2i(-1, -1)
	var found_water: bool = false

	# Search for water tile
	for tile: Vector2i in world_manager.world_gen.tile_heights.keys():
		var height: float = world_manager.world_gen.tile_heights[tile]
		if height <= -0.01:  # Water
			water_tile = tile
			found_water = true
			break

	if not found_water:
		# Skip test if no water tiles found in test map
		pass_test("No water tiles in test map - skipping")
		return

	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(water_tile)
	var settler: UnitStats = autofree(create_mock_settler(1))

	# Act - try to found colony on water
	var result: ColonyFoundingWorkflow.Result = player.cm.found_colony(water_tile, world_pos, settler)
	await wait_physics_frames(1)

	# Assert
	assert_true(result.is_error(), "Colony founding on water should fail")
	assert_string_contains(result.error_message, "invalid tile", "Error should mention invalid tile")
	assert_colony_founding_state(player.cm, ColonyFoundingWorkflow.State.IDLE)
	assert_eq(player.cm.colonies.size(), 0, "Should have 0 colonies")


func test_create_colony_without_found_colony_fails() -> void:
	# Arrange - fresh ColonyManager (no founding started)
	assert_colony_founding_state(player.cm, ColonyFoundingWorkflow.State.IDLE)

	# Act - try to create colony without founding first
	var result: ColonyFoundingWorkflow.Result = player.cm.create_colony()
	await wait_physics_frames(1)

	# Assert
	assert_true(result.is_error(), "Create colony should fail without founding")
	assert_string_contains(result.error_message, "not in founding state", "Error should mention state")
	assert_eq(player.cm.colonies.size(), 0, "Should have 0 colonies")


func test_cancel_found_colony_twice_fails_gracefully() -> void:
	# Arrange - found a colony
	var tile_pos: Vector2i = Vector2i(10, 10)
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler: UnitStats = autofree(create_mock_settler(1))

	player.cm.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)

	# Act - cancel once (should succeed)
	var result_1: ColonyFoundingWorkflow.Result = player.cm.cancel_found_colony()
	await wait_physics_frames(1)

	assert_true(result_1.is_ok(), "First cancel should succeed")

	# Act - cancel again (should fail)
	var result_2: ColonyFoundingWorkflow.Result = player.cm.cancel_found_colony()
	await wait_physics_frames(1)

	# Assert
	assert_true(result_2.is_error(), "Second cancel should fail")
	assert_string_contains(result_2.error_message, "not in founding state", "Error should mention state")
	assert_colony_founding_state(player.cm, ColonyFoundingWorkflow.State.IDLE)


func test_found_colony_with_null_settler_fails() -> void:
	# Arrange
	var tile_pos: Vector2i = Vector2i(10, 10)
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)

	# Act - try to found colony with null settler
	var result: ColonyFoundingWorkflow.Result = player.cm.found_colony(tile_pos, world_pos, null)
	await wait_physics_frames(1)

	# Assert
	assert_true(result.is_error(), "Colony founding with null settler should fail")
	assert_string_contains(result.error_message, "settler stats are null", "Error should mention null stats")
	assert_colony_founding_state(player.cm, ColonyFoundingWorkflow.State.IDLE)


func test_concurrent_found_colony_calls_fail() -> void:
	# Arrange - start founding first colony
	var tile_pos_1: Vector2i = Vector2i(10, 10)
	var world_pos_1: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos_1)
	var settler_1: UnitStats = autofree(create_mock_settler(1))

	var result_1: ColonyFoundingWorkflow.Result = player.cm.found_colony(tile_pos_1, world_pos_1, settler_1)
	await wait_physics_frames(1)

	assert_true(result_1.is_ok(), "First founding should succeed")
	assert_colony_founding_state(player.cm, ColonyFoundingWorkflow.State.CONFIRMING)

	# Act - try to found second colony while first is still pending
	var tile_pos_2: Vector2i = Vector2i(20, 20)
	var world_pos_2: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos_2)
	var settler_2: UnitStats = autofree(create_mock_settler(1))

	var result_2: ColonyFoundingWorkflow.Result = player.cm.found_colony(tile_pos_2, world_pos_2, settler_2)
	await wait_physics_frames(1)

	# Assert
	assert_true(result_2.is_error(), "Second founding should fail while first is pending")
	assert_string_contains(result_2.error_message, "already founding", "Error should mention already founding")
	assert_eq(player.cm.colonies.size(), 1, "Should still have only 1 colony (the first one)")


func test_undo_create_colony_on_null_building_fails() -> void:
	# Arrange - no colony created
	assert_eq(player.cm.colonies.size(), 0)

	# Act - try to undo with null building
	var result: ColonyFoundingWorkflow.Result = player.cm.undo_create_colony(null)
	await wait_physics_frames(1)

	# Assert
	assert_true(result.is_error(), "Undo with null building should fail")
	assert_string_contains(result.error_message, "building is null", "Error should mention null building")


func test_undo_create_colony_on_active_building_fails() -> void:
	# Arrange - create and activate a colony
	var tile_pos: Vector2i = Vector2i(10, 10)
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler: UnitStats = autofree(create_mock_settler(1))

	player.cm.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)
	player.cm.create_colony()
	await wait_physics_frames(1)

	var colony: CenterBuilding = player.cm.colonies[0]

	# Transition to ACTIVE state (simulate turn processing)
	colony.building_state = Term.BuildingState.ACTIVE

	# Act - try to undo active building
	var result: ColonyFoundingWorkflow.Result = player.cm.undo_create_colony(colony)
	await wait_physics_frames(1)

	# Assert
	assert_true(result.is_error(), "Undo on active building should fail")
	assert_string_contains(result.error_message, "not in NEW state", "Error should mention building state")
	assert_eq(player.cm.colonies.size(), 1, "Colony should still exist")


func test_remove_null_colony_fails() -> void:
	# Act - try to remove null colony
	var result: ColonyFoundingWorkflow.Result = player.cm.remove_colony(null)
	await wait_physics_frames(1)

	# Assert
	assert_true(result.is_error(), "Remove null colony should fail")
	assert_string_contains(result.error_message, "null colony", "Error should mention null")


func test_remove_non_existent_colony_fails() -> void:
	# Arrange - create a colony not in the colonies array
	var rogue_colony: CenterBuilding = autofree(CenterBuilding.new())

	# Act - try to remove it
	var result: ColonyFoundingWorkflow.Result = player.cm.remove_colony(rogue_colony)
	await wait_physics_frames(1)

	# Assert
	assert_true(result.is_error(), "Remove non-existent colony should fail")
	assert_string_contains(result.error_message, "not found", "Error should mention not found")

#endregion
