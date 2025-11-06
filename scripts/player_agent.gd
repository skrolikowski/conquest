extends Node2D
class_name PlayerAgent

## Abstract base class for all player-like entities (human player, AI, NPCs).
## Implements ITurnParticipant interface and provides shared functionality.
##
## Subclass this for:
## - HumanPlayer (current Player class)
## - AIPlayer (current NPC class)
## - NetworkPlayer (future multiplayer support)

# Core properties shared by all player types
var is_human: bool = false
var agent_name: String = ""
var agent_color: Color = Color.WHITE


#region TURN MANAGEMENT (ITurnParticipant Interface)

## Begin turn processing - must be implemented by subclasses
## Part of ITurnParticipant interface
func begin_turn() -> void:
	assert(false, "PlayerAgent.begin_turn() must be implemented by subclass")


## End turn processing - must be implemented by subclasses
## Part of ITurnParticipant interface
func end_turn() -> void:
	assert(false, "PlayerAgent.end_turn() must be implemented by subclass")


## Get turn priority for this participant
## Part of ITurnParticipant interface
func get_turn_priority() -> int:
	if is_human:
		return Term.TurnPriority.PLAYER
	else:
		return Term.TurnPriority.NPC


## Get participant name for logging/debugging
## Part of ITurnParticipant interface
func get_participant_name() -> String:
	return agent_name if agent_name != "" else "Unknown Agent"

#endregion


#region ABSTRACT METHODS (Subclasses should implement)

## Get all controlled units - override in subclasses
func get_controlled_units() -> Array:
	return []


## Get all settlements/colonies - override in subclasses
func get_settlements() -> Array:
	return []


## Check if can afford a resource cost - override in subclasses
func can_afford(_cost: Transaction) -> bool:
	return false

#endregion


#region GAME PERSISTENCE

## Base save data - subclasses should call super and extend
func on_save_data() -> Dictionary:
	return {
		"is_human": is_human,
		"agent_name": agent_name,
		"agent_color": agent_color,
	}


## Base load data - subclasses should call super and extend
func on_load_data(_data: Dictionary) -> void:
	is_human = _data.get("is_human", false)
	agent_name = _data.get("agent_name", "")

	# Load color if it exists
	if _data.has("agent_color"):
		agent_color = _data["agent_color"]

#endregion
