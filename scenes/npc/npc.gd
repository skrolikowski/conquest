extends PlayerAgent
class_name NPC

## Represents an AI-controlled NPC faction in the game.
## Extends PlayerAgent base class and implements ITurnParticipant interface.

enum Tribe
{
	ELVES,
	DWARVES,
}

@onready var village_list := $VillageList as Node2D

var title  : String
var sprite : Node2D
var village_range : Array[float] = []
var tribe  : Tribe : set = _set_tribe


func _ready() -> void:
	is_human = false


func _set_tribe(_tribe: Tribe) -> void:
	tribe = _tribe

	if tribe == Tribe.ELVES:
		title  = "Elf"
		agent_name = "Elf Tribe"
		agent_color = Color.GREEN
		sprite = Preload.elven_village_scene.instantiate() as Node2D
		village_range = [0.4, 0.5]
	elif tribe == Tribe.DWARVES:
		title = "Dwarf"
		agent_name = "Dwarf Tribe"
		agent_color = Color.BROWN
		sprite = Preload.dwarven_village_scene.instantiate() as Node2D
		village_range = [0.6, 0.7]


#region VILLAGE MANAGEMENT
func get_villages() -> Array[Node]:
	return village_list.get_children() as Array[Node]


func get_village_count() -> int:
	return village_list.get_child_count()


func create_village(_tile: Vector2i) -> void:
	var village_scene : PackedScene = Preload.village_scene
	var village       : Village = village_scene.instantiate() as Village
	village_list.add_child(village)

	village.npc = self
	village.add_child(sprite)

	# -- set village position..
	var tile_map_layer : TileMapLayer = Def.get_world_map().get_land_layer()
	var map_pos        : Vector2 = tile_map_layer.map_to_local(_tile)
	village.global_position = map_pos + Vector2(Preload.C.TILE_SIZE.x * 0.5, Preload.C.TILE_SIZE.y * 0.5)

	# -- TERRAFORM: Remove forest..
	var tiles : Array[Vector2i] = village.get_tiles()
	Def.get_world_map().terraform_biome_tiles(tiles, WorldGen.BiomeTerrain.FOREST, WorldGen.BiomeTerrain.UNFOREST)
	Def.get_world_map().terraform_biome_tiles(tiles, WorldGen.BiomeTerrain.MOUNTAINS, WorldGen.BiomeTerrain.UNMOUNTAIN)


func remove_village(_village: Village) -> void:
	
	# -- TERRAFORM: Restore forest..
	var tiles : Array[Vector2i] = _village.get_tiles()
	Def.get_world_map().terraform_biome_tiles(tiles, WorldGen.BiomeTerrain.UNFOREST, WorldGen.BiomeTerrain.FOREST)
	Def.get_world_map().terraform_biome_tiles(tiles, WorldGen.BiomeTerrain.UNMOUNTAIN, WorldGen.BiomeTerrain.MOUNTAINS)

	village_list.remove_child(_village)
	_village.queue_free()

#endregion


#region DIPLOMACY
func get_diplomacy_with_player() -> int:
	return Def.get_world().turn_orchestrator.get_diplomacy_with_player(self)

#endregion


#region PLAYERAGENT INTERFACE IMPLEMENTATIONS

## Get all controlled units - implements PlayerAgent interface
func get_controlled_units() -> Array:
	return []  # NPCs don't have units currently


## Get all settlements - implements PlayerAgent interface
func get_settlements() -> Array:
	return get_villages()


## Check if can afford a resource cost - implements PlayerAgent interface
func can_afford(_cost: Transaction) -> bool:
	return false  # TODO: implement when NPC economy is added

#endregion


#region TURN MANAGEMENT (ITurnParticipant Interface)

## Begin turn processing for the NPC
## Part of ITurnParticipant interface
func begin_turn() -> void:

	# -- update villages
	for village: Village in get_villages():
		village.begin_turn()

	#TODO: Diplomacy
	# - cycle through discovered players and update diplomacy
	#TODO: Trade
	# - Fulfill trade requests
	# - Send trade requests
	pass


## End turn processing for the NPC
## Part of ITurnParticipant interface
func end_turn() -> void:
	pass


# Note: get_turn_priority() and get_participant_name() are inherited from PlayerAgent

#endregion


#region GAME PERSISTENCE
func new_game() -> void:
	var rand_tile : Vector2i = Def.get_world_map().get_random_height_range_tile(village_range[0], village_range[1])
	# var rand_tile : Vector2i = Vector2i(46, 32)
	create_village(rand_tile)


func on_save_data() -> Dictionary:

	# -- Package villages..
	var village_data : Array[Dictionary] = []
	for village: Village in get_villages():
		village_data.append(village.on_save_data())

	return {
		"title"    : title,
		"tribe"	   : tribe,
		"villages" : village_data,
	}


func on_load_data(_data: Dictionary) -> void:
	title = _data["title"]
	tribe = _data["tribe"]

	# -- Load villages..
	for village_data: Dictionary in _data["villages"]:
		var village_scene : PackedScene = Preload.village_scene
		var village       : Village = village_scene.instantiate() as Village
		village_list.add_child(village)

		village.on_load_data(village_data)
		village.npc = self

		# -- TERRAFORM: Remove forest..
		var tiles : Array[Vector2i] = village.get_tiles()
		Def.get_world_map().terraform_biome_tiles(tiles, WorldGen.BiomeTerrain.FOREST, WorldGen.BiomeTerrain.UNFOREST)
		Def.get_world_map().terraform_biome_tiles(tiles, WorldGen.BiomeTerrain.MOUNTAINS, WorldGen.BiomeTerrain.UNMOUNTAIN)



#endregion
