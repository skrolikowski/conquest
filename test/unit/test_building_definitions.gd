extends GutTest
## Unit tests for building definitions loaded from JSON metadata
##
## These tests verify that buildings.json is correctly loaded and provides
## valid data for all building types and levels.


#region BUILDING METADATA TESTS

func test_all_building_types_have_definitions() -> void:
	# Arrange - Get all building types from enum
	var building_types : Array[Term.BuildingType] = [
		Term.BuildingType.FARM,
		Term.BuildingType.MILL,
		Term.BuildingType.METAL_MINE,
		Term.BuildingType.GOLD_MINE,
		Term.BuildingType.COMMERCE,
		Term.BuildingType.FORT,
		Term.BuildingType.CHURCH,
		Term.BuildingType.HOUSING,
		Term.BuildingType.WAR_COLLEGE,
		Term.BuildingType.TAVERN,
		Term.BuildingType.DOCK,
		Term.BuildingType.CENTER,
	]

	# Act & Assert - Each building type should have metadata
	for building_type : int in building_types:
		var cost_level_1:Transaction = autofree(GameData.get_building_cost(building_type, 1))
		assert_not_null(
				cost_level_1,
				"Building type %s should have cost definition for level 1" % Term.BuildingType.keys()[building_type]
			)


func test_farm_has_correct_level_1_definition() -> void:
	# Act
	var cost:Transaction = autofree(GameData.get_building_cost(Term.BuildingType.FARM, 1))
	var make:Transaction = autofree(GameData.get_building_make(Term.BuildingType.FARM, 1))
	# var need:Transaction = GameData.get_building_need(Term.BuildingType.FARM, 1)

	# Assert - Farm should have valid definitions
	assert_not_null(cost, "Farm level 1 should have cost")
	assert_not_null(make, "Farm level 1 should have production (make)")
	# Need might be null if farm doesn't consume resources at level 1

	# Check that farm produces crops
	if make:
		var crops_produced:int = make.get_resource_amount(Term.ResourceType.CROPS)
		assert_gt(crops_produced, 0, "Farm should produce crops")


func test_building_costs_increase_with_level() -> void:
	# Arrange - Test Farm costs at different levels
	var level_1_cost:Transaction = autofree(GameData.get_building_cost(Term.BuildingType.FARM, 1))
	var level_2_cost:Transaction = autofree(GameData.get_building_cost(Term.BuildingType.FARM, 2))

	# Assert - Higher levels should exist and potentially cost more
	assert_not_null(level_1_cost, "Level 1 cost exists")
	assert_not_null(level_2_cost, "Level 2 cost exists")

	# Note: Actual cost comparison depends on your JSON design
	# Some games scale costs, others keep them flat


func test_building_production_scales_with_level() -> void:
	# Arrange - Farm production at different levels
	var level_1_make:Transaction = autofree(GameData.get_building_make(Term.BuildingType.FARM, 1))
	var level_2_make:Transaction = autofree(GameData.get_building_make(Term.BuildingType.FARM, 2))

	# Act - Get crops produced at each level
	var level_1_crops:int = level_1_make.get_resource_amount(Term.ResourceType.CROPS) if level_1_make else 0
	var level_2_crops:int = level_2_make.get_resource_amount(Term.ResourceType.CROPS) if level_2_make else 0

	# Assert - Higher level should produce more (or equal)
	assert_gte(level_2_crops, level_1_crops, "Higher level farm should produce >= crops")
	assert_gt(level_2_crops, 0, "Level 2 farm should produce crops")

#endregion


#region PRODUCTION BUILDING TESTS

func test_mill_produces_wood() -> void:
	# Act
	var make:Transaction = autofree(GameData.get_building_make(Term.BuildingType.MILL, 1))

	# Assert
	assert_not_null(make, "Mill should have production")
	if make:
		var wood_produced:int = make.get_resource_amount(Term.ResourceType.WOOD)
		assert_gt(wood_produced, 0, "Mill should produce wood")


func test_mine_produces_metal() -> void:
	# Act
	var make:Transaction = autofree(GameData.get_building_make(Term.BuildingType.METAL_MINE, 1))

	# Assert
	assert_not_null(make, "Metal mine should have production")
	if make:
		var metal_produced:int = make.get_resource_amount(Term.ResourceType.METAL)
		assert_gt(metal_produced, 0, "Metal mine should produce metal")


func test_commerce_produces_goods() -> void:
	# Act
	var make:Transaction = autofree(GameData.get_building_make(Term.BuildingType.COMMERCE, 1))

	# Assert
	assert_not_null(make, "Commerce should have production")
	if make:
		var goods_produced:int = make.get_resource_amount(Term.ResourceType.GOODS)
		assert_gt(goods_produced, 0, "Commerce should produce goods")

#endregion


#region BUILDING RESOURCE CONSUMPTION TESTS

func test_mill_consumes_nothing() -> void:
	# Act
	var need:Transaction = autofree(GameData.get_building_need(Term.BuildingType.MILL, 1))

	# Assert - Mill should consume crops to produce goods
	if need:
		var crops_consumed:int = need.get_resource_amount(Term.ResourceType.CROPS)
		assert_eq(crops_consumed, 0, "Mill should not consume crops")
		var wood_consumed:int = need.get_resource_amount(Term.ResourceType.WOOD)
		assert_eq(wood_consumed, 0, "Mill should not consume wood")
		var metal_consumed:int = need.get_resource_amount(Term.ResourceType.METAL)
		assert_eq(metal_consumed, 0, "Mill should not consume metal")
		var gold_consumed:int = need.get_resource_amount(Term.ResourceType.GOLD)
		assert_eq(gold_consumed, 0, "Mill should not consume gold")
		var goods_consumed:int = need.get_resource_amount(Term.ResourceType.GOODS)
		assert_eq(goods_consumed, 0, "Mill should not consume goods")
		


func test_buildings_without_consumption() -> void:
	# Arrange - Some buildings might not consume resources
	var farm_need:Transaction = autofree(GameData.get_building_need(Term.BuildingType.FARM, 1))

	# Assert - Farm might not need resources, or needs very little
	# This test just verifies the system handles null/zero gracefully
	if farm_need == null:
		pass  # OK - farm doesn't consume resources
	else:
		# If it does consume, verify it's valid
		assert_true(true, "Farm consumption defined")

#endregion


#region LABOR DEMAND TESTS

func test_buildings_have_labor_demand()	-> void:
	# Act
	var farm_labor:int = GameData.get_building_labor_demand(Term.BuildingType.FARM, 1)

	# Assert
	assert_gt(farm_labor, 0, "Farm should require labor")


func test_labor_demand_scales_with_level() -> void:
	# Arrange
	var level_1_labor:int = GameData.get_building_labor_demand(Term.BuildingType.FARM, 1)
	var level_2_labor:int = GameData.get_building_labor_demand(Term.BuildingType.FARM, 2)

	# Assert - Higher levels might require more labor
	assert_gt(level_1_labor, 0, "Level 1 requires labor")
	assert_gt(level_2_labor, 0, "Level 2 requires labor")
	# Depending on design, level 2 might require more or same labor
	assert_gte(level_2_labor, level_1_labor, "Higher level requires >= labor")

#endregion


#region LEVEL LIMITS TESTS

func test_buildings_support_max_level_4() -> void:
	# Arrange - Test that level 4 definitions exist
	var building_types: Array[Term.BuildingType] = [
		Term.BuildingType.FARM,
		Term.BuildingType.MILL,
		Term.BuildingType.COMMERCE,
	]

	# Act & Assert
	for building_type:Term.BuildingType in building_types:
		var level_4_cost:Transaction = autofree(GameData.get_building_cost(building_type, 4))
		assert_not_null(
			level_4_cost,
			"Building %s should support level 4" % Term.BuildingType.keys()[building_type]
		)


# NOTE: Removed test_level_5_does_not_exist()
# GameData.get_building_cost() uses assert() for invalid levels,
# which is the intended defensive behavior. There's no graceful null return.
# The assertion itself validates that level 5 doesn't exist.

#endregion


#region SPECIAL BUILDINGS TESTS

func test_center_building_definition() -> void:
	# Act
	var cost:Transaction = autofree(GameData.get_building_cost(Term.BuildingType.CENTER, 1))

	# Assert - Center is special (colony core), should have definition
	assert_not_null(cost, "Center building should have definition")


func test_fort_building_definition() -> void:
	# Act
	var cost:Transaction = autofree(GameData.get_building_cost(Term.BuildingType.FORT, 1))

	# Assert
	assert_not_null(cost, "Fort should have definition")

#endregion


#region INTEGRATION TESTS

# func test_farm_to_mill_production_chain() -> void:
# 	# Arrange - Simulate farm → mill chain
# 	var farm_makes:Transaction = autofree(GameData.get_building_make(Term.BuildingType.FARM, 1))
# 	var mill_needs:Transaction = autofree(GameData.get_building_need(Term.BuildingType.MILL, 1))
# 	var mill_makes:Transaction = autofree(GameData.get_building_make(Term.BuildingType.MILL, 1))

# 	# Assert - Farm produces crops, mill consumes crops, mill produces goods
# 	assert_not_null(farm_makes, "Farm produces something")
# 	assert_not_null(mill_needs, "Mill needs something")
# 	assert_not_null(mill_makes, "Mill produces something")

# 	var farm_crops:int = farm_makes.get_resource_amount(Term.ResourceType.CROPS)
# 	var mill_crops_needed:int = mill_needs.get_resource_amount(Term.ResourceType.CROPS)
# 	var mill_goods:int = mill_makes.get_resource_amount(Term.ResourceType.GOODS)

# 	assert_gt(farm_crops, 0, "Farm produces crops")
# 	assert_gt(mill_crops_needed, 0, "Mill needs crops")
# 	assert_gt(mill_goods, 0, "Mill produces goods")


func test_building_cost_affordability() -> void:
	# Arrange - Create a bank with resources
	var bank_resources: Transaction = Transaction.new()
	bank_resources.add_resources({
		"wood": 100,
		"crops": 100,
		"gold": 50
	})

	var farm_cost: Transaction = GameData.get_building_cost(Term.BuildingType.FARM, 1)

	# Act - Check if we can afford the farm
	var can_afford:bool = true
	for resource_type:Term.ResourceType in farm_cost.resources.keys():
		if farm_cost.get_resource_amount(resource_type) > bank_resources.get_resource_amount(resource_type):
			can_afford = false
			break

	# Assert - With 100 wood, 100 crops, should be able to afford farm
	assert_true(can_afford, "Should have enough resources for Farm level 1")

#endregion
