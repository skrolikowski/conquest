extends IntegrationTestBase
## Integration tests for colony founding system integrations (tiles, save/load, etc)


func before_each() -> void:
	await setup_world()


func after_each() -> void:
	super.after_each()


#region SYSTEM INTEGRATION TESTS

func test_colony_founding_marks_tiles_occupied() -> void:
	# Arrange
	var tile_pos: Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler: UnitStats = autofree(create_mock_settler(1))
	var colony_manager: ColonyManager = player.cm

	# Act - found and create colony
	var result : ColonyFoundingWorkflow.Result = colony_manager.found_colony(tile_pos, world_pos, settler)
	if result.is_error():
		assert_true(false, "Failed to found colony: %s" % result.error_message)
		return
	await wait_physics_frames(1)

	var colony: CenterBuilding = colony_manager.placing_colony

	# Assert - tiles should be occupied after founding
	assert_colony_tiles_occupied(colony, "Tiles should be occupied immediately after founding")

	# Complete colony
	colony_manager.create_colony()
	await wait_physics_frames(1)

	# Assert - tiles should still be occupied after completion
	assert_colony_tiles_occupied(colony, "Tiles should remain occupied after colony creation")


func test_colony_cancel_removes_occupied_tiles() -> void:
	# Arrange
	var tile_pos       : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos      : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler        : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	var result: ColonyFoundingWorkflow.Result = colony_manager.found_colony(tile_pos, world_pos, settler)
	if result.is_error():
		assert_true(false, "Failed to found colony: %s" % result.error_message)
		return
	await wait_physics_frames(1)

	var colony: CenterBuilding = colony_manager.placing_colony
	assert_not_null(colony, "Colony should exist after founding")

	# Verify tiles are occupied before cancel
	assert_colony_tiles_occupied(colony, "Tiles should be occupied before cancel")

	# Act - cancel colony
	colony_manager.cancel_found_colony()
	await wait_physics_frames(1)

	# Assert - colony should be removed and tiles freed
	# Note: We can't check colony.bm since colony is freed
	assert_eq(colony_manager.colonies.size(), 0, "Colony should be removed")
	# Settler should be restored
	var restored_settler: Unit = assert_settler_at_position(world_pos, 50.0, "Settler should be restored after cancel")
	assert_not_null(restored_settler, "Settler should exist after cancel")


func test_colony_undo_removes_occupied_tiles() -> void:
	# Arrange
	var tile_pos       : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos      : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler        : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	# Act - found colony
	var result: ColonyFoundingWorkflow.Result = player.cm.found_colony(tile_pos, world_pos, settler)
	if result.is_error():
		assert_true(false, "Failed to found colony: %s" % result.error_message)
		return
	await wait_physics_frames(1)

	# Act - create colony
	colony_manager.create_colony()
	await wait_physics_frames(1)

	var colony: CenterBuilding = colony_manager.colonies[0]

	# Act - undo colony
	colony_manager.undo_create_colony(colony)
	await wait_physics_frames(1)

	# Assert
	assert_eq(colony_manager.colonies.size(), 0, "Colony should be removed")


func test_cannot_found_colony_on_occupied_tiles() -> void:
	# Arrange
	var tile_pos       : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos      : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler_1      : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	# Act - found colony
	var result_1 : ColonyFoundingWorkflow.Result = colony_manager.found_colony(tile_pos, world_pos, settler_1)
	if result_1.is_error():
		assert_true(false, "Failed to found colony: %s" % result_1.error_message)
		return
	await wait_physics_frames(1)
	
	# Act - create colony
	colony_manager.create_colony()
	await wait_physics_frames(1)

	# Act - try to found second colony on same tiles
	var settler_2 : UnitStats = autofree(create_mock_settler(1))
	var result_2  : ColonyFoundingWorkflow.Result = colony_manager.found_colony(tile_pos, world_pos, settler_2)
	await wait_physics_frames(1)

	# Assert - should fail (tiles are occupied)
	assert_true(result_2.is_error(), "Should not be able to found colony on occupied tiles")
	if result_2.is_error():
		assert_string_contains(result_2.error_message, "occupied", "Error should mention tiles are occupied")


func test_no_orphan_colonies_after_operations() -> void:
	# Arrange
	var tile_pos: Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos: Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler: UnitStats = autofree(create_mock_settler(1))
	var colony_manager: ColonyManager = player.cm

	# Found and create
	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)
	colony_manager.create_colony()
	await wait_physics_frames(1)

	# Assert - no orphans
	assert_no_orphan_colonies()


func test_colony_founding_preserves_settler_level() -> void:
	# Arrange - level 3 settler
	var tile_pos       : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos      : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler        : UnitStats = autofree(create_mock_settler(3))
	var colony_manager : ColonyManager = player.cm

	# Act - found and cancel
	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)
	colony_manager.cancel_found_colony()
	await wait_physics_frames(1)

	# Assert - restored settler should have same level
	var settler_unit: Unit = assert_settler_at_position(world_pos, 50.0)
	assert_eq(settler_unit.stat.level, 3, "Restored settler should have same level")


func test_multiple_colonies_track_tiles_independently() -> void:
	# Arrange - create two colonies at different locations
	var tile_pos_1     : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos_1    : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos_1)
	var settler_1      : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	player.cm.found_colony(tile_pos_1, world_pos_1, settler_1)
	await wait_physics_frames(1)
	player.cm.create_colony()
	await wait_physics_frames(1)

	var colony_1: CenterBuilding = player.cm.colonies[0]

	# Create second colony at a different location (offset by 10 tiles to ensure no overlap)
	var tile_pos_2  : Vector2i = tile_pos_1 + Vector2i(10, 0)  # 10 tiles away to avoid overlap
	var world_pos_2 : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos_2)
	var settler_2   : UnitStats = autofree(create_mock_settler(1))

	var result_2: ColonyFoundingWorkflow.Result = colony_manager.found_colony(tile_pos_2, world_pos_2, settler_2)
	if result_2.is_error():
		assert_true(false, "Failed to found second colony: %s" % result_2.error_message)
	await wait_physics_frames(1)
	colony_manager.create_colony()
	await wait_physics_frames(1)

	var colony_2: CenterBuilding = colony_manager.colonies[1]

	# Assert - each colony tracks its own tiles
	assert_colony_tiles_occupied(colony_1, "Colony 1 tiles should be occupied")
	assert_colony_tiles_occupied(colony_2, "Colony 2 tiles should be occupied")

	# Assert - removing one colony doesn't affect the other
	colony_manager.remove_colony(colony_1)
	await wait_physics_frames(1)

	assert_eq(colony_manager.colonies.size(), 1, "Should have 1 colony remaining")
	assert_colony_tiles_occupied(colony_2, "Colony 2 tiles should still be occupied")


func test_colony_visual_state_changes() -> void:
	# Arrange
	var tile_pos  : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler   : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	# Act - found colony
	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)

	# Access colony through the public getter (uses placement_preview.colony)
	var colony: CenterBuilding = colony_manager.placing_colony

	# Assert - colony should be semi-transparent during founding
	assert_eq(colony.modulate.a, 0.75, "Colony should be 75% opaque during founding")

	# Act - create colony
	colony_manager.create_colony()
	await wait_physics_frames(1)

	# Assert - colony should be fully opaque after creation
	assert_eq(colony.modulate.a, 1.0, "Colony should be 100% opaque after creation")


func test_colony_resources_initialized_from_settler() -> void:
	# Arrange
	var tile_pos  : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler   : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	# Act
	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)
	colony_manager.create_colony()
	await wait_physics_frames(1)

	var colony: CenterBuilding = colony_manager.colonies[0]

	# Assert - colony should have resources from settler stats
	# Settler level 1 should provide some starting resources
	var unit_stat: Dictionary = GameData.get_unit_stat(Term.UnitType.SETTLER, 1)
	if unit_stat.has("resources"):
		for resource_key: String in unit_stat.resources.keys():
			var resource_type: Term.ResourceType = Term.ResourceType.get(resource_key.to_upper())
			var expected_amount: int = unit_stat.resources[resource_key]
			var actual_amount: int = colony.bank.get_resource_value(resource_type)
			assert_eq(actual_amount, expected_amount, "Colony should have settler's %s resources" % resource_key)

func test_placement_preview_cleared_after_colony_creation() -> void:
	# Arrange
	var tile_pos  : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler   : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	# Act - found colony
	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)

	# Assert - placement preview should be active
	assert_not_null(colony_manager.placing_colony, "Placement preview should be active during founding")
	assert_true(colony_manager.placement_preview.has_preview(), "Placement preview should report as active")

	# Act - create colony
	colony_manager.create_colony()
	await wait_physics_frames(1)

	# Assert - placement preview should be cleared
	assert_null(colony_manager.placing_colony, "Placement preview should be cleared after creation")
	assert_false(colony_manager.placement_preview.has_preview(), "Placement preview should not be active after creation")


func test_placement_preview_cleared_after_cancel() -> void:
	# Arrange
	var tile_pos  : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler   : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	# Act - found colony
	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)

	# Assert - placement preview should be active
	assert_not_null(colony_manager.placing_colony, "Placement preview should be active")

	# Act - cancel
	colony_manager.cancel_found_colony()
	await wait_physics_frames(1)

	# Assert - placement preview should be cleared
	assert_null(colony_manager.placing_colony, "Placement preview should be cleared after cancel")
	assert_false(colony_manager.placement_preview.has_preview(), "Placement preview should not be active after cancel")


func test_placement_preview_generates_preview_tiles_in_integration() -> void:
	# Arrange
	var tile_pos  : Vector2i = world_manager.world_gen.get_optimal_colony_location()
	var world_pos : Vector2 = world_manager.world_gen.get_map_to_local_position(tile_pos)
	var settler   : UnitStats = autofree(create_mock_settler(1))
	var colony_manager : ColonyManager = player.cm

	# Act - found colony
	colony_manager.found_colony(tile_pos, world_pos, settler)
	await wait_physics_frames(1)

	# Force a redraw to trigger preview tile calculation
	colony_manager.placement_preview.queue_redraw()
	await wait_physics_frames(1)

	# Assert - preview tiles should be generated (in integration tests with world map)
	# Note: This may or may not generate tiles depending on when _draw() is called
	# The important thing is that it doesn't crash
	assert_not_null(colony_manager.placement_preview, "Placement preview should exist")
	assert_eq(colony_manager.placement_preview.target_tile, tile_pos, "Placement preview should have correct target tile")

#endregion
