extends GutTest
## Unit tests for the Transaction class (resource management system)
##
## GUT Test Naming Convention:
## - test_* : Each test method must start with "test_"
## - All tests run in alphabetical order by default


#region SETUP AND TEARDOWN

## Runs once before all tests
func before_all() -> void:
	pass


## Runs before each test
func before_each() -> void:
	pass


## Runs after each test
func after_each() -> void:
	pass


## Runs once after all tests
func after_all() -> void:
	pass

#endregion


#region BASIC INITIALIZATION TESTS

func test_transaction_initializes_with_zero_resources() -> void:
	# Arrange & Act
	var transaction:Transaction = autofree(Transaction.new())

	# Assert
	assert_not_null(transaction, "Transaction should be created")
	assert_eq(transaction.get_resource_amount(Term.ResourceType.GOLD), 0, "Gold should start at 0")
	assert_eq(transaction.get_resource_amount(Term.ResourceType.WOOD), 0, "Wood should start at 0")
	assert_eq(transaction.get_resource_amount(Term.ResourceType.CROPS), 0, "Crops should start at 0")
	assert_eq(transaction.get_resource_amount(Term.ResourceType.METAL), 0, "Metal should start at 0")


func test_transaction_contains_all_resource_types() -> void:
	# Arrange & Act
	var transaction:Transaction = autofree(Transaction.new())

	# Assert - Check all resource types are present
	assert_true(transaction.resources.has(Term.ResourceType.GOLD), "Should have GOLD")
	assert_true(transaction.resources.has(Term.ResourceType.WOOD), "Should have WOOD")
	assert_true(transaction.resources.has(Term.ResourceType.CROPS), "Should have CROPS")
	assert_true(transaction.resources.has(Term.ResourceType.GOODS), "Should have GOODS")
	assert_true(transaction.resources.has(Term.ResourceType.METAL), "Should have METAL")

#endregion


#region ADDING RESOURCES TESTS

func test_add_resource_amount_by_type_increases_resource() -> void:
	# Arrange
	var transaction:Transaction = autofree(Transaction.new())

	# Act
	transaction.add_resource_amount_by_type(Term.ResourceType.GOLD, 100)

	# Assert
	assert_eq(transaction.get_resource_amount(Term.ResourceType.GOLD), 100, "Gold should be 100")


func test_add_resource_amount_by_type_accumulates() -> void:
	# Arrange
	var transaction:Transaction = autofree(Transaction.new())

	# Act
	transaction.add_resource_amount_by_type(Term.ResourceType.WOOD, 50)
	transaction.add_resource_amount_by_type(Term.ResourceType.WOOD, 30)

	# Assert
	assert_eq(transaction.get_resource_amount(Term.ResourceType.WOOD), 80, "Wood should accumulate to 80")


func test_add_multiple_different_resources() -> void:
	# Arrange
	var transaction:Transaction = autofree(Transaction.new())

	# Act
	transaction.add_resource_amount_by_type(Term.ResourceType.GOLD, 100)
	transaction.add_resource_amount_by_type(Term.ResourceType.WOOD, 50)
	transaction.add_resource_amount_by_type(Term.ResourceType.CROPS, 200)

	# Assert
	assert_eq(transaction.get_resource_amount(Term.ResourceType.GOLD), 100)
	assert_eq(transaction.get_resource_amount(Term.ResourceType.WOOD), 50)
	assert_eq(transaction.get_resource_amount(Term.ResourceType.CROPS), 200)


func test_add_resources_from_dictionary() -> void:
	# Arrange
	var transaction:Transaction = autofree(Transaction.new())
	var resource_dict : Dictionary = {
		"gold": 150,
		"wood": 75,
		"crops": 300
	}

	# Act
	transaction.add_resources(resource_dict)

	# Assert
	assert_eq(transaction.get_resource_amount(Term.ResourceType.GOLD), 150)
	assert_eq(transaction.get_resource_amount(Term.ResourceType.WOOD), 75)
	assert_eq(transaction.get_resource_amount(Term.ResourceType.CROPS), 300)

#endregion


#region TRANSACTION OPERATIONS TESTS

func test_clone_creates_independent_copy() -> void:
	# Arrange
	var original:Transaction = autofree(Transaction.new())
	original.add_resource_amount_by_type(Term.ResourceType.GOLD, 100)
	original.add_resource_amount_by_type(Term.ResourceType.WOOD, 50)

	# Act
	var cloned:Transaction = autofree(original.clone())

	# Assert - Values should match
	assert_eq(cloned.get_resource_amount(Term.ResourceType.GOLD), 100, "Cloned gold matches")
	assert_eq(cloned.get_resource_amount(Term.ResourceType.WOOD), 50, "Cloned wood matches")

	# Modify original to verify independence
	original.add_resource_amount_by_type(Term.ResourceType.GOLD, 50)
	assert_eq(original.get_resource_amount(Term.ResourceType.GOLD), 150, "Original gold changed")
	assert_eq(cloned.get_resource_amount(Term.ResourceType.GOLD), 100, "Cloned gold unchanged")


func test_add_transaction_merges_resources() -> void:
	# Arrange
	var transaction1:Transaction = autofree(Transaction.new())
	transaction1.add_resource_amount_by_type(Term.ResourceType.GOLD, 100)
	transaction1.add_resource_amount_by_type(Term.ResourceType.WOOD, 50)

	var transaction2:Transaction = autofree(Transaction.new())
	transaction2.add_resource_amount_by_type(Term.ResourceType.GOLD, 50)
	transaction2.add_resource_amount_by_type(Term.ResourceType.CROPS, 200)

	# Act
	transaction1.add_transaction(transaction2)

	# Assert
	assert_eq(transaction1.get_resource_amount(Term.ResourceType.GOLD), 150, "Gold should merge (100 + 50)")
	assert_eq(transaction1.get_resource_amount(Term.ResourceType.WOOD), 50, "Wood unchanged")
	assert_eq(transaction1.get_resource_amount(Term.ResourceType.CROPS), 200, "Crops added")


func test_add_transaction_does_not_modify_source() -> void:
	# Arrange
	var transaction1:Transaction = autofree(Transaction.new())
	transaction1.add_resource_amount_by_type(Term.ResourceType.GOLD, 100)

	var transaction2:Transaction = autofree(Transaction.new())
	transaction2.add_resource_amount_by_type(Term.ResourceType.GOLD, 50)

	# Act
	transaction1.add_transaction(transaction2)

	# Assert - transaction2 should be unchanged
	assert_eq(transaction2.get_resource_amount(Term.ResourceType.GOLD), 50, "Source transaction unchanged")

#endregion


#region EDGE CASES AND NEGATIVE VALUES

func test_negative_resource_amounts() -> void:
	# Arrange
	var transaction:Transaction = autofree(Transaction.new())

	# Act - Add negative amount (representing cost/consumption)
	transaction.add_resource_amount_by_type(Term.ResourceType.GOLD, -50)

	# Assert
	assert_eq(transaction.get_resource_amount(Term.ResourceType.GOLD), -50, "Negative amounts allowed for costs")


func test_zero_resource_amount() -> void:
	# Arrange
	var transaction:Transaction = autofree(Transaction.new())

	# Act
	transaction.add_resource_amount_by_type(Term.ResourceType.GOLD, 0)

	# Assert
	assert_eq(transaction.get_resource_amount(Term.ResourceType.GOLD), 0, "Zero amount handled")


func test_large_resource_amounts() -> void:
	# Arrange
	var transaction:Transaction = autofree(Transaction.new())
	var large_amount:int = 999999

	# Act
	transaction.add_resource_amount_by_type(Term.ResourceType.GOLD, large_amount)

	# Assert
	assert_eq(transaction.get_resource_amount(Term.ResourceType.GOLD), large_amount, "Large amounts supported")

#endregion


#region PRACTICAL USE CASES

func test_building_cost_transaction() -> void:
	# Arrange - Simulate a building cost (Farm level 1)
	var cost:Transaction = autofree(Transaction.new())
	cost.add_resources({
		"wood": 10,
		"crops": 5
	})

	# Assert
	assert_eq(cost.get_resource_amount(Term.ResourceType.WOOD), 10)
	assert_eq(cost.get_resource_amount(Term.ResourceType.CROPS), 5)
	assert_eq(cost.get_resource_amount(Term.ResourceType.GOLD), 0, "Unused resources remain 0")


func test_production_calculation() -> void:
	# Arrange - Simulate farm production
	var production:Transaction = autofree(Transaction.new())
	production.add_resource_amount_by_type(Term.ResourceType.CROPS, 50)  # Farm makes crops

	var consumption:Transaction = autofree(Transaction.new())
	consumption.add_resource_amount_by_type(Term.ResourceType.CROPS, -10)  # Farm needs crops

	# Act - Combine production and consumption
	var net:Transaction = autofree(production.clone())
	net.add_transaction(consumption)

	# Assert
	assert_eq(net.get_resource_amount(Term.ResourceType.CROPS), 40, "Net production: 50 - 10 = 40")


func test_resource_transfer_between_entities() -> void:
	# Arrange - Simulate settler founding colony (resource transfer)
	var settler_resources:Transaction = autofree(Transaction.new())
	settler_resources.add_resources({
		"wood": 50,
		"crops": 100,
		"gold": 10
	})

	var colony_resources:Transaction = autofree(Transaction.new())

	# Act - Transfer from settler to colony
	colony_resources.add_transaction(settler_resources)

	# Assert
	assert_eq(colony_resources.get_resource_amount(Term.ResourceType.WOOD), 50)
	assert_eq(colony_resources.get_resource_amount(Term.ResourceType.CROPS), 100)
	assert_eq(colony_resources.get_resource_amount(Term.ResourceType.GOLD), 10)

#endregion
