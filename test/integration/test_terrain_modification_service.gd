extends IntegrationTestBase

## Integration tests for TerrainModificationService
##
## Tests that the service can be called with a real WorldGen instance
## and doesn't crash. Actual terrain modification behavior is complex
## and depends on WorldGen's internal biome system.

const TerrainModificationService: GDScript = preload("res://scenes/player/colony/terrain_modification_service.gd")


func test_terrain_service_with_real_world_gen() -> void:
	# Set up world
	setup_world()
	await wait_physics_frames(2)

	# Verify WorldGen is available
	assert_not_null(world_manager.world_gen, "WorldGen should be initialized")

	# Get some tiles from the map
	var tiles: Array[Vector2i] = []
	for x: int in range(5):
		for y: int in range(5):
			tiles.append(Vector2i(x, y))

	# Test clear terrain - should not crash
	TerrainModificationService.clear_terrain_for_building(tiles)
	await wait_physics_frames(1)

	# Test restore terrain - should not crash
	TerrainModificationService.restore_terrain_from_building(tiles)
	await wait_physics_frames(1)

	# Test refresh terrain - should not crash
	TerrainModificationService.refresh_terrain_for_colony(tiles)
	await wait_physics_frames(1)

	# All tests passed if we got here without crashing
	pass_test("All terrain modification operations completed without crashing")
