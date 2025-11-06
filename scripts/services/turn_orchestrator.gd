extends Node
class_name TurnOrchestrator

## Centralized turn management service for all turn participants.
## Replaces PlayerManager with proper orchestration of turn phases.
##
## Responsibilities:
## - Register and manage turn participants (Player, NPCs, etc.)
## - Execute turn phases in priority order
## - Coordinate diplomacy system
## - Handle save/load for all participants

signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal participant_turn_started(participant_name: String)
signal participant_turn_ended(participant_name: String)

var current_turn: int = 0
var player: Player = null
var npcs: Array[NPC] = []
var diplomacy: Diplomacy = null

func _ready() -> void:
	player = Preload.player_scene.instantiate() as Player
	add_child(player)


#region REGISTRATION MANAGEMENT

## Register an NPC participant
func register_npc(_npc: NPC) -> void:
	if not npcs.has(_npc):
		npcs.append(_npc)
		print("[TurnOrchestrator] NPC registered: ", _npc.get_participant_name())


## Unregister an NPC participant
func unregister_npc(_npc: NPC) -> void:
	npcs.erase(_npc)
	print("[TurnOrchestrator] NPC unregistered: ", _npc.get_participant_name())

#endregion


## Begin a new turn for all participants
func begin_turn() -> void:
	print("[TurnOrchestrator] === Begin Turn ", current_turn, " ===")
	turn_started.emit(current_turn)

	# Player turn (priority 10)
	if player != null:
		participant_turn_started.emit(player.get_participant_name())
		player.begin_turn()
		participant_turn_ended.emit(player.get_participant_name())

	# NPC turns (priority 20)
	for npc in npcs:
		if npc != null:
			participant_turn_started.emit(npc.get_participant_name())
			npc.begin_turn()
			participant_turn_ended.emit(npc.get_participant_name())


## End the current turn and advance to next
func end_turn() -> void:
	print("[TurnOrchestrator] === End Turn ", current_turn, " ===")

	# Call end_turn on all participants
	if player != null:
		player.end_turn()

	for npc in npcs:
		if npc != null:
			npc.end_turn()

	turn_ended.emit(current_turn)
	current_turn += 1

	# Automatically begin next turn
	begin_turn()


#region GAME PERSISTENCE

func new_game() -> void:
	print("[TurnOrchestrator] New Game")
	current_turn = 0

	# Initialize diplomacy
	diplomacy = Diplomacy.new()
	diplomacy.new_game()

	# Initialize player
	if player != null:
		player.new_game()


func on_save_data() -> Dictionary:
	print("[TurnOrchestrator] Save Data")

	# Package NPCs
	var npc_data: Array[Dictionary] = []
	for npc in npcs:
		npc_data.append(npc.on_save_data())

	# Package diplomacy (with null safety)
	var diplomacy_data: Dictionary = {}
	if diplomacy != null:
		diplomacy_data = diplomacy.on_save_data()

	# Package player
	var player_data: Dictionary = {}
	if player != null:
		player_data = player.on_save_data()

	return {
		"turn_number": current_turn,
		"diplomacy": diplomacy_data,
		"player": player_data,
		"npcs": npc_data,
	}


func on_load_data(_data: Dictionary) -> void:
	print("[TurnOrchestrator] Load Data")

	# Load turn number
	current_turn = _data.get("turn_number", 0)

	# Load player
	if player != null and _data.has("player"):
		player.on_load_data(_data["player"])

	# Load diplomacy (with null safety)
	diplomacy = Diplomacy.new()
	if _data.has("diplomacy") and not _data["diplomacy"].is_empty():
		diplomacy.on_load_data(_data["diplomacy"])
	else:
		diplomacy.new_game()

	# Load NPCs
	if _data.has("npcs"):
		for npc_data : Dictionary in _data["npcs"]:
			var npc_scene: PackedScene = Preload.npc_scene as PackedScene
			var npc: NPC = npc_scene.instantiate() as NPC
			add_child(npc)

			npc.on_load_data(npc_data)
			register_npc(npc)

#endregion


## Get diplomacy level with a specific NPC
func get_diplomacy_with_player(_agent: PlayerAgent) -> int:
	# Placeholder - return neutral diplomacy
	return 5
