class_name ITurnParticipant

## Interface for entities that participate in turn-based gameplay.
##
## GDScript doesn't have formal interfaces, so this serves as documentation
## and provides default implementations that assert if not overridden.
##
## Classes implementing this interface: Player, NPC, CenterBuilding, Unit, Village
##
## Usage:
##   - Inherit or reference this class in implementing classes
##   - Override all methods with actual implementations
##   - Use get_turn_priority() to control turn order (lower = earlier)

## Called at the beginning of each turn for this participant
func begin_turn() -> void:
	assert(false, "ITurnParticipant.begin_turn() must be implemented by subclass")


## Called at the end of each turn for this participant
func end_turn() -> void:
	assert(false, "ITurnParticipant.end_turn() must be implemented by subclass")


## Returns the priority for turn processing
## Lower numbers execute first (e.g., 10 = player, 20 = NPCs, 30 = environment)
func get_turn_priority() -> int:
	assert(false, "ITurnParticipant.get_turn_priority() must be implemented by subclass")
	return 999


## Returns a human-readable name for this participant (for debugging/logging)
func get_participant_name() -> String:
	assert(false, "ITurnParticipant.get_participant_name() must be implemented by subclass")
	return "Unknown Participant"
