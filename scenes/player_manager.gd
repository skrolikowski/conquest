extends Node2D
class_name PlayerManager

@onready var player := $Player as Player

@export var npc_count : int = 1

var diplomacy  : Diplomacy
var npcs       : Array[NPC] = []


func get_diplomacy_with_player(_npc: NPC) -> int:
	return 5


#region TURN MANAGEMENT
func begin_turn() -> void:
	player.begin_turn()
		

func end_turn() -> void:
	for npc: NPC in npcs:
		npc.begin_turn()

#endregion


#region GAME PERSISTENCE
func new_game() -> void:
	player.new_game()

	diplomacy = Diplomacy.new()
	diplomacy.new_game()

	# -- Generate NPCS..
	# for i in range(npc_count):
	# 	var npc_scene : PackedScene = Preload.npc_scene
	# 	var npc       : NPC = npc_scene.instantiate() as NPC
	# 	add_child(npc)

	# 	#TODO: randomize this..
	# 	npc.tribe = NPC.Tribe.DWARVES

	# 	npc.new_game()
	# 	npcs.append(npc)

	# --
	begin_turn()


func on_save_data() -> Dictionary:

	# -- Package NPCs..
	var npc_data : Array[Dictionary] = []
	for npc: NPC in npcs:
		npc_data.append(npc.on_save_data())

	# -- Package diplomacy (with null safety)..
	var diplomacy_data : Dictionary = {}
	if diplomacy != null:
		diplomacy_data = diplomacy.on_save_data()

	return {
		"diplomacy" : diplomacy_data,
		"player"    : player.on_save_data(),
		"npcs"      : npc_data,
	}


func on_load_data(_data: Dictionary) -> void:

	# -- Load player..
	player.on_load_data(_data["player"])

	# -- Load diplomacy (with null safety)..
	diplomacy = Diplomacy.new()
	if not _data["diplomacy"].is_empty():
		diplomacy.on_load_data(_data["diplomacy"])
	else:
		diplomacy.new_game()

	# -- Load NPCs..
	for npc_data: Dictionary in _data["npcs"]:
		var npc_scene : PackedScene = Preload.npc_scene as PackedScene
		var npc       : NPC = npc_scene.instantiate() as NPC
		add_child(npc)

		npc.on_load_data(npc_data)
		npcs.append(npc)

#endregion
