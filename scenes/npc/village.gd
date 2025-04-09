extends Node2D
class_name Village

enum ArmySize
{
	NONE,
	SM,
	MD,
	LG,
}

var title      : String
var npc        : NPC
var population : int = 100     # 0-1000
var health     : float = 1.0   # 0-1
var resources  : float = 1.0   # 0-1
var army_size  : ArmySize
var is_hostile_nearby : bool = false

const MAX_POPULATION : int = 1000
const MAX_HEALTH     : float = 1.0
const MAX_RESOURCES  : float = 1.0
const GROWTH_RATE    : float = 0.05
const DECAY_RATE     : float = 0.1


func _ready() -> void:
	title = "Center"


func get_size() -> Vector2:
	return ($CollisionShape2D as CollisionShape2D).shape.size


func get_tile() -> Vector2i:
	return Def.get_world_map().get_land_layer().local_to_map(global_position - get_size() * 0.5)


func get_tile_end() -> Vector2i:
	return get_tile() + Vector2i(1, 1)


func get_tiles() -> Array[Vector2i]:
	var tiles : Array[Vector2i] = []
	for x: int in range(get_tile().x, get_tile_end().x + 1):
		for y: int in range(get_tile().y, get_tile_end().y + 1):
			tiles.append(Vector2i(x, y))
	return tiles


func update_resources() -> void:
	var change_value : float = randf_range(-0.005, 0.005)
	
	if is_hostile_nearby:
		change_value += randf_range(-0.01, 0.01)

	if population > MAX_POPULATION * 0.9:
		change_value -= -0.01

	resources += change_value
	resources = clampf(resources, 0.0, MAX_RESOURCES)


func update_population() -> void:
	var change_rate : float = 0.0

	if health >= 0.8:
		change_rate = GROWTH_RATE * 0.5
	elif health >= 0.6:
		change_rate = GROWTH_RATE
	elif health >= 0.2:
		change_rate = -DECAY_RATE
	else:
		change_rate = -DECAY_RATE * 0.5
	
	population += floor(population * change_rate)
	population = clamp(population, 0, MAX_POPULATION)


func update_health() -> void:
	var change_value: float = 0.005

	# Apply penalty if hostile villages are nearby..
	if is_hostile_nearby:
		change_value -= -0.01

	# -- Apply penalty for overpopulation..
	if population > MAX_POPULATION * 0.9:
		change_value -= -0.005

	# -- Apply penalty for low resources..
	if resources < MAX_RESOURCES * 0.25:
		change_value -= -0.01
	elif resources > MAX_RESOURCES * 0.75:
		change_value += 0.005

	# -- Randomness..
	change_value += randf_range(-0.005, 0.005)

	health += change_value
	health = clampf(health, 0.0, MAX_HEALTH)


func update_army_size() -> void:
	var score : float = (float(population) / MAX_POPULATION) * 0.6 + (health / MAX_HEALTH) * 0.4

	if score >= 0.8:
		army_size = ArmySize.LG
	elif score >= 0.6:
		army_size = ArmySize.MD
	elif score >= 0.4:
		army_size = ArmySize.SM
	else:
		army_size = ArmySize.NONE


#region TURN MANAGEMENT
func begin_turn() -> void:
	#TODO: Create army and send to enemy if:
	# + army large enough
	# + population > 100 enough
	# + health good enough
	# - decrease population

	#TODO: update `is_hostile_nearby`

	update_resources()
	update_population()
	update_health()
	update_army_size()


func end_turn() -> void:
	pass

#endregion


#region GAME PERSISTENCE
func on_save_data() -> Dictionary:
	return {
		"title"      : title,
		"population" : population,
		"health"     : health,
		"resources"  : resources,
		"army_size"  : army_size,
		"position"   : global_position,
		"is_hostile_nearby" : is_hostile_nearby,
	}


func on_load_data(_data: Dictionary) -> void:
	title      = _data["title"]
	population = _data["population"]
	health     = _data["health"]
	resources  = _data["resources"]
	army_size  = _data["army_size"]
	is_hostile_nearby = _data["is_hostile_nearby"]
	global_position = _data["position"]

#endregion
