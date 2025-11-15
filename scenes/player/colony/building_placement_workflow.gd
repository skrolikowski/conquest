## State machine for building placement workflow
## Manages the lifecycle: IDLE → PLACING → CONFIRMING → PLACED/CANCELLED
extends RefCounted
class_name BuildingPlacementWorkflow

## States of the building placement process
enum State {
	IDLE,       ## No active placement process
	PLACING,    ## Building placement initiated, waiting for position selection
	CONFIRMING, ## Position selected, waiting for confirmation
	PLACED,     ## Building placed successfully
	CANCELLED   ## Placement cancelled
}

## Current state of the workflow
var current_state: State = State.IDLE

## Context holding all data for the current placement process
var context: BuildingPlacementContext = null


## Start a new building placement process
func start_placement(building: Building, colony: CenterBuilding) -> Result:
	if current_state != State.IDLE:
		return Result.error("Cannot start placement: already in state %s" % State.keys()[current_state])

	context = BuildingPlacementContext.new(building, colony)
	current_state = State.PLACING
	return Result.ok(context)


## Transition to confirming state (valid position selected)
func begin_confirming() -> Result:
	if current_state != State.PLACING:
		return Result.error("Cannot confirm: not in PLACING state (current: %s)" % State.keys()[current_state])

	current_state = State.CONFIRMING
	return Result.ok()


## Complete the placement process successfully
func complete_placement() -> Result:
	if current_state != State.CONFIRMING and current_state != State.PLACING:
		return Result.error("Cannot complete: not in CONFIRMING/PLACING state (current: %s)" % State.keys()[current_state])

	if context == null:
		return Result.error("Cannot complete: context is null")

	current_state = State.PLACED
	return Result.ok()


## Cancel the placement process
func cancel_placement() -> Result:
	if current_state != State.CONFIRMING and current_state != State.PLACING:
		return Result.error("Cannot cancel: not in CONFIRMING/PLACING state (current: %s)" % State.keys()[current_state])

	if context == null:
		return Result.error("Cannot cancel: context is null")

	current_state = State.CANCELLED
	return Result.ok()


## Reset to idle state (call after completing placement lifecycle)
func reset() -> void:
	current_state = State.IDLE
	context = null


## Check if currently in placement process
func is_placing() -> bool:
	return current_state in [State.PLACING, State.CONFIRMING]


## Check if can accept new placement request
func can_start_placement() -> bool:
	return current_state == State.IDLE


## Get human-readable state name
func get_state_name() -> String:
	return State.keys()[current_state]


## Value object holding all context for building placement
class BuildingPlacementContext extends RefCounted:
	var building: Building           # Building being placed
	var colony: CenterBuilding       # Colony that owns the building
	var target_tile: Vector2i        # Target tile for placement

	func _init(_building: Building, _colony: CenterBuilding) -> void:
		building = _building
		colony = _colony
		target_tile = Vector2i.ZERO

	## Update the target tile
	func set_target_tile(tile: Vector2i) -> void:
		target_tile = tile

	## Validate that context is in valid state
	func is_valid() -> bool:
		return building != null and colony != null


## Simple Result type for error handling
class Result extends RefCounted:
	var success: bool
	var value: Variant = null
	var error_message: String = ""

	static func ok(val: Variant = null) -> Result:
		var r: Result = Result.new()
		r.success = true
		r.value = val
		return r

	static func error(msg: String) -> Result:
		var r: Result = Result.new()
		r.success = false
		r.error_message = msg
		return r

	func is_ok() -> bool:
		return success

	func is_error() -> bool:
		return not success

	func unwrap() -> Variant:
		if not success:
			push_error("Called unwrap() on error result: %s" % error_message)
		return value

	func expect(msg: String) -> Variant:
		if not success:
			push_error("%s: %s" % [msg, error_message])
		return value
