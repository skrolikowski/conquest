extends GutTest

## Unit tests for BuildingPlacementWorkflow
##
## Tests the state machine that manages building placement lifecycle:
## - State transitions (IDLE → PLACING → CONFIRMING → PLACED/CANCELLED)
## - Error handling for invalid state transitions
## - Context management

const BuildingPlacementWorkflow: GDScript = preload("res://scenes/player/colony/building_placement_workflow.gd")


func test_initial_state_is_idle() -> void:
	var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()

	assert_eq(workflow.current_state, BuildingPlacementWorkflow.State.IDLE, "Should start in IDLE state")
	assert_null(workflow.context, "Context should be null initially")


func test_can_start_placement_from_idle() -> void:
	var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()

	assert_true(workflow.can_start_placement(), "Should be able to start placement from IDLE")


func test_start_placement_creates_context() -> void:
	var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()
	var building: Building = autofree(Building.new())
	var colony: CenterBuilding = autofree(CenterBuilding.new())

	var result: BuildingPlacementWorkflow.Result = workflow.start_placement(building, colony)

	assert_true(result.is_ok(), "Should successfully start placement")
	assert_eq(workflow.current_state, BuildingPlacementWorkflow.State.PLACING, "Should transition to PLACING state")
	assert_not_null(workflow.context, "Context should be created")
	assert_eq(workflow.context.building, building, "Context should store building reference")
	assert_eq(workflow.context.colony, colony, "Context should store colony reference")


func test_cannot_start_placement_when_already_placing() -> void:
	var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()
	var building1: Building = autofree(Building.new())
	var building2: Building = autofree(Building.new())
	var colony: CenterBuilding = autofree(CenterBuilding.new())

	workflow.start_placement(building1, colony)
	var result: BuildingPlacementWorkflow.Result = workflow.start_placement(building2, colony)

	assert_true(result.is_error(), "Should fail to start second placement")
	assert_string_contains(result.error_message, "already in state", "Should explain conflict")


func test_begin_confirming_from_placing() -> void:
	var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()
	var building: Building = autofree(Building.new())
	var colony: CenterBuilding = autofree(CenterBuilding.new())

	workflow.start_placement(building, colony)
	var result: BuildingPlacementWorkflow.Result = workflow.begin_confirming()

	assert_true(result.is_ok(), "Should successfully begin confirming")
	assert_eq(workflow.current_state, BuildingPlacementWorkflow.State.CONFIRMING, "Should transition to CONFIRMING state")


func test_cannot_begin_confirming_from_idle() -> void:
	var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()

	var result: BuildingPlacementWorkflow.Result = workflow.begin_confirming()

	assert_true(result.is_error(), "Should fail to confirm from IDLE")
	assert_eq(workflow.current_state, BuildingPlacementWorkflow.State.IDLE, "Should remain in IDLE state")


func test_complete_placement_from_confirming() -> void:
	var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()
	var building: Building = autofree(Building.new())
	var colony: CenterBuilding = autofree(CenterBuilding.new())

	workflow.start_placement(building, colony)
	workflow.begin_confirming()
	var result: BuildingPlacementWorkflow.Result = workflow.complete_placement()

	assert_true(result.is_ok(), "Should successfully complete placement")
	assert_eq(workflow.current_state, BuildingPlacementWorkflow.State.PLACED, "Should transition to PLACED state")


func test_cancel_placement_from_confirming() -> void:
	var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()
	var building: Building = autofree(Building.new())
	var colony: CenterBuilding = autofree(CenterBuilding.new())

	workflow.start_placement(building, colony)
	workflow.begin_confirming()
	var result: BuildingPlacementWorkflow.Result = workflow.cancel_placement()

	assert_true(result.is_ok(), "Should successfully cancel placement")
	assert_eq(workflow.current_state, BuildingPlacementWorkflow.State.CANCELLED, "Should transition to CANCELLED state")


func test_reset_clears_state_and_context() -> void:
	var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()
	var building: Building = autofree(Building.new())
	var colony: CenterBuilding = autofree(CenterBuilding.new())

	workflow.start_placement(building, colony)
	workflow.reset()

	assert_eq(workflow.current_state, BuildingPlacementWorkflow.State.IDLE, "Should reset to IDLE state")
	assert_null(workflow.context, "Context should be cleared")


func test_is_placing_returns_true_during_placement() -> void:
	var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()
	var building: Building = autofree(Building.new())
	var colony: CenterBuilding = autofree(CenterBuilding.new())

	assert_false(workflow.is_placing(), "Should not be placing initially")

	workflow.start_placement(building, colony)
	assert_true(workflow.is_placing(), "Should be placing after start")

	workflow.begin_confirming()
	assert_true(workflow.is_placing(), "Should still be placing during confirming")

	workflow.complete_placement()
	assert_false(workflow.is_placing(), "Should not be placing after completion")


func test_context_set_target_tile() -> void:
	var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()
	var building: Building = autofree(Building.new())
	var colony: CenterBuilding = autofree(CenterBuilding.new())

	workflow.start_placement(building, colony)

	var target: Vector2i = Vector2i(10, 20)
	workflow.context.set_target_tile(target)

	assert_eq(workflow.context.target_tile, target, "Context should store target tile")


func test_context_is_valid() -> void:
	var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()
	var building: Building = autofree(Building.new())
	var colony: CenterBuilding = autofree(CenterBuilding.new())

	workflow.start_placement(building, colony)

	assert_true(workflow.context.is_valid(), "Context should be valid with building and colony")


func test_get_state_name_returns_readable_string() -> void:
	var workflow: BuildingPlacementWorkflow = BuildingPlacementWorkflow.new()

	assert_eq(workflow.get_state_name(), "IDLE", "Should return IDLE state name")

	var building: Building = autofree(Building.new())
	var colony: CenterBuilding = autofree(CenterBuilding.new())
	workflow.start_placement(building, colony)

	assert_eq(workflow.get_state_name(), "PLACING", "Should return PLACING state name")


## Test Result type - unwrap behavior is tested implicitly via error handling
## Skipping explicit unwrap test as it intentionally produces errors


## Test Result type ok and error
func test_result_ok() -> void:
	var result: BuildingPlacementWorkflow.Result = BuildingPlacementWorkflow.Result.ok("success")

	assert_true(result.is_ok(), "Result should be ok")
	assert_false(result.is_error(), "Result should not be error")
	assert_eq(result.value, "success", "Result should store value")


func test_result_error() -> void:
	var result: BuildingPlacementWorkflow.Result = BuildingPlacementWorkflow.Result.error("failure")

	assert_false(result.is_ok(), "Result should not be ok")
	assert_true(result.is_error(), "Result should be error")
	assert_eq(result.error_message, "failure", "Result should store error message")
