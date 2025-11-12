## State machine for colony founding workflow
## Manages the lifecycle: IDLE → FOUNDING → CONFIRMING → FOUNDED/CANCELLED
class_name ColonyFoundingWorkflow
extends RefCounted

## States of the colony founding process
enum State {
	IDLE,       ## No active founding process
	FOUNDING,   ## Colony placement initiated, waiting for confirmation
	CONFIRMING, ## UI open, player reviewing
	FOUNDED,    ## Colony created successfully
	CANCELLED   ## Founding cancelled, settler restored
}

## Current state of the workflow
var current_state: State = State.IDLE

## Context holding all data for the current founding process
var context: ColonyFoundingContext = null


## Start a new colony founding process
func start_founding(tile: Vector2i, settler: UnitStats, settler_pos: Vector2) -> Result:
	if current_state != State.IDLE:
		return Result.error("Cannot start founding: already in state %s" % State.keys()[current_state])

	context = ColonyFoundingContext.new(tile, settler, settler_pos)
	current_state = State.FOUNDING
	return Result.ok(context)


## Transition to confirming state (UI opened)
func begin_confirming() -> Result:
	if current_state != State.FOUNDING:
		return Result.error("Cannot confirm: not in FOUNDING state (current: %s)" % State.keys()[current_state])

	current_state = State.CONFIRMING
	return Result.ok()


## Complete the founding process successfully
func complete_founding(colony: CenterBuilding) -> Result:
	if current_state != State.CONFIRMING and current_state != State.FOUNDING:
		return Result.error("Cannot complete: not in CONFIRMING/FOUNDING state (current: %s)" % State.keys()[current_state])

	if context == null:
		return Result.error("Cannot complete: context is null")

	context.colony = colony
	current_state = State.FOUNDED
	return Result.ok()


## Cancel the founding process
func cancel_founding() -> Result:
	if current_state != State.CONFIRMING and current_state != State.FOUNDING:
		return Result.error("Cannot cancel: not in CONFIRMING/FOUNDING state (current: %s)" % State.keys()[current_state])

	if context == null:
		return Result.error("Cannot cancel: context is null")

	current_state = State.CANCELLED
	return Result.ok()


## Reset to idle state (call after completing founding lifecycle)
func reset() -> void:
	current_state = State.IDLE
	context = null


## Check if currently in founding process
func is_founding() -> bool:
	return current_state in [State.FOUNDING, State.CONFIRMING]


## Check if can accept new founding request
func can_start_founding() -> bool:
	return current_state == State.IDLE


## Get human-readable state name
func get_state_name() -> String:
	return State.keys()[current_state]


## Value object holding all context for colony founding
class ColonyFoundingContext extends RefCounted:
	var target_tile      : Vector2i   # Target tile for colony placement
	var settler_stats    : UnitStats  # Original settler stats (for restoration on cancel)
	var settler_position : Vector2    # Original settler position (for restoration on cancel)
	var colony           : CenterBuilding = null  # Colony being founded (null until created)

	func _init(tile: Vector2i, settler: UnitStats, pos: Vector2) -> void:
		target_tile = tile
		settler_stats = settler
		settler_position = pos

	## Create a new settler with the original stats
	## Uses save/load round-trip to deep clone the stats
	func restore_settler() -> UnitStats:
		var restored: UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, settler_stats.level)
		restored.on_load_data(settler_stats.on_save_data())
		return restored

	## Validate that context is in valid state
	func is_valid() -> bool:
		return settler_stats != null and target_tile != null


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
