extends GutTest
## Unit tests for ColonyPlacementPreview
##
## Tests the visual preview service for colony placement,
## verifying that preview state is managed correctly.


var preview: Node2D
var mock_colony: CenterBuilding


func before_each() -> void:
	# Create preview instance
	preview = preload("res://scenes/player/colony/colony_placement_preview.gd").new()
	add_child_autofree(preview)

	# Create mock colony
	mock_colony = autofree(CenterBuilding.new())
	mock_colony.global_position = Vector2(100, 100)


func after_each() -> void:
	preview = null
	mock_colony = null


#region BASIC FUNCTIONALITY

func test_new_preview_has_no_colony() -> void:
	# Assert
	assert_null(preview.colony, "New preview should have no colony")
	assert_false(preview.has_preview(), "New preview should not have active preview")
	assert_eq(preview.target_tile, Vector2i.ZERO, "New preview should have zero target tile")
	assert_eq(preview.preview_tiles.size(), 0, "New preview should have no preview tiles")


func test_set_preview_sets_colony_and_tile() -> void:
	# Arrange
	var target_tile: Vector2i = Vector2i(10, 10)

	# Act
	preview.set_preview(mock_colony, target_tile)
	await wait_physics_frames(1)

	# Assert
	assert_eq(preview.colony, mock_colony, "Preview should store the colony")
	assert_eq(preview.target_tile, target_tile, "Preview should store the target tile")
	assert_true(preview.has_preview(), "Preview should be active")


func test_clear_preview_resets_state() -> void:
	# Arrange
	var target_tile: Vector2i = Vector2i(10, 10)
	preview.set_preview(mock_colony, target_tile)
	await wait_physics_frames(1)

	# Act
	preview.clear_preview()
	await wait_physics_frames(1)

	# Assert
	assert_null(preview.colony, "Colony should be cleared")
	assert_eq(preview.target_tile, Vector2i.ZERO, "Target tile should be reset")
	assert_false(preview.has_preview(), "Preview should not be active")
	assert_eq(preview.preview_tiles.size(), 0, "Preview tiles should be cleared")


func test_get_colony_returns_colony() -> void:
	# Arrange
	preview.set_preview(mock_colony, Vector2i(10, 10))

	# Act
	var result: CenterBuilding = preview.get_colony()

	# Assert
	assert_eq(result, mock_colony, "get_colony() should return the stored colony")


func test_get_colony_returns_null_when_no_preview() -> void:
	# Act
	var result: CenterBuilding = preview.get_colony()

	# Assert
	assert_null(result, "get_colony() should return null when no preview active")


#endregion


#region PREVIEW TILES

func test_set_preview_with_no_world_map_handles_gracefully() -> void:
	# Arrange
	var target_tile: Vector2i = Vector2i(10, 10)

	# Act - Set preview without world map (unit test scenario)
	preview.set_preview(mock_colony, target_tile)
	await wait_physics_frames(1)

	# Assert
	# In unit tests (no world map), preview_tiles should be empty
	# This is expected behavior - preview tiles require world map
	assert_eq(preview.preview_tiles.size(), 0, "Preview tiles should be empty without world map")


func test_set_preview_with_zero_tile_clears_preview_tiles() -> void:
	# Arrange
	preview.set_preview(mock_colony, Vector2i(10, 10))
	await wait_physics_frames(1)

	# Act
	preview.set_preview(mock_colony, Vector2i.ZERO)
	await wait_physics_frames(1)

	# Assert
	assert_eq(preview.preview_tiles.size(), 0, "Preview tiles should be cleared with zero tile")


#endregion


#region STATE TRANSITIONS

func test_multiple_set_preview_calls_update_state() -> void:
	# Arrange
	var colony2: CenterBuilding = autofree(CenterBuilding.new())
	colony2.global_position = Vector2(200, 200)

	# Act
	preview.set_preview(mock_colony, Vector2i(10, 10))
	await wait_physics_frames(1)

	preview.set_preview(colony2, Vector2i(20, 20))
	await wait_physics_frames(1)

	# Assert
	assert_eq(preview.colony, colony2, "Colony should be updated to second colony")
	assert_eq(preview.target_tile, Vector2i(20, 20), "Target tile should be updated")
	assert_true(preview.has_preview(), "Should still have an active preview")


func test_has_preview_reflects_current_state() -> void:
	# Assert - Initially no preview
	assert_false(preview.has_preview(), "Should not have preview initially")

	# Act - Set preview
	preview.set_preview(mock_colony, Vector2i(10, 10))
	assert_true(preview.has_preview(), "Should have preview after setting")

	# Act - Clear preview
	preview.clear_preview()
	assert_false(preview.has_preview(), "Should not have preview after clearing")


#endregion


#region EDGE CASES

func test_set_preview_with_null_colony_handles_gracefully() -> void:
	# Act
	preview.set_preview(null, Vector2i(10, 10))
	await wait_physics_frames(1)

	# Assert
	assert_null(preview.colony, "Colony should remain null")
	assert_false(preview.has_preview(), "Should not have preview with null colony")


func test_clear_preview_when_already_clear_is_safe() -> void:
	# Act - Clear when already clear
	preview.clear_preview()
	preview.clear_preview()
	await wait_physics_frames(1)

	# Assert - Should not crash
	assert_null(preview.colony, "Colony should remain null")
	assert_false(preview.has_preview(), "Should not have preview")


#endregion
