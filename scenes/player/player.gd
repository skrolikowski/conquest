extends PlayerAgent
class_name Player

## Represents the human player in the game.
## Extends PlayerAgent base class and implements ITurnParticipant interface.

@onready var unit_list := $UnitList as Node2D
@onready var timer     := $Timer as Timer
@onready var cm        := $ColonyManager as ColonyManager

var units  : Array[Unit] = []
var trades : Array[Trade] = []


func _ready() -> void:
	is_human = true
	agent_name = "Player"
	agent_color = Color.BLUE


#region TURN MANAGEMENT (ITurnParticipant Interface)

## Begin turn processing for the player
## Part of ITurnParticipant interface
func begin_turn() -> void:
	print("[NOTE] Begin Turn - Player")

	# -- Colony management..
	begin_turn_for_colonies()

	# -- Units..
	for unit: Unit in units:
		unit.begin_turn()

	# -- Fog of War..
	FogOfWarService.reveal_around_player_units(self)


## End turn processing for the player
## Part of ITurnParticipant interface
func end_turn() -> void:
	pass


# Note: get_turn_priority() and get_participant_name() are inherited from PlayerAgent

#endregion


#region PLAYERAGENT INTERFACE IMPLEMENTATIONS

## Get all controlled units - implements PlayerAgent interface
func get_controlled_units() -> Array:
	return units


## Get all settlements - implements PlayerAgent interface
func get_settlements() -> Array:
	return cm.get_colonies()


## Check if can afford a resource cost - implements PlayerAgent interface
func can_afford(cost: Transaction) -> bool:
	# Delegate to bank if we have colonies
	if get_colonies().size() > 0:
		var colony : CenterBuilding = get_colonies()[0] as CenterBuilding
		return colony.bank.can_afford(cost)
	return false

#endregion


#region COLONIES
func begin_turn_for_colonies() -> void:
	for colony: CenterBuilding in get_colonies():
		colony.begin_turn()


func get_colonies() -> Array[CenterBuilding]:
	return cm.get_colonies()


func get_latest_colony() -> CenterBuilding:
	return cm.get_latest_colony()


func found_colony(_tile: Vector2i, _position: Vector2, _stats: UnitStats) -> ColonyFoundingWorkflow.Result:
	return cm.found_colony(_tile, _position, _stats)


func undo_found_colony(_building: CenterBuilding) -> ColonyFoundingWorkflow.Result:
	return cm.undo_create_colony(_building)

#endregion


#region UNITS
func get_military_units_by_colony(_colony : CenterBuilding) -> Array[Unit]:
	var _units : Array[Unit] = []
	# Optimized: only iterate military units
	for unit : Unit in units:
		# Early exit for non-military units
		if unit.unit_category != Term.UnitCategory.MILITARY:
			continue
		if unit.colony == _colony:
			_units.append(unit)
	return _units


# func get_units_by_colony(_colony : CenterBuilding) -> Array[Unit]:
# 	var _units : Array[Unit] = []
# 	for unit : Unit in units:
# 		if unit.colony == _colony:
# 			_units.append(unit)
# 	return _units


func get_ships() -> Array[ShipUnit]:
	var _units : Array[ShipUnit] = []
	for unit : Unit in units:
		if unit is ShipUnit:
			_units.append(unit)
	return _units


func create_unit(_unit_stat: UnitStats, _position: Vector2) -> Unit:
	var unit_scene : PackedScene = PreloadsRef.get_unit_scene(_unit_stat.unit_type)
	var unit_name  : String = PreloadsRef.TR.unit_type_to_name(_unit_stat.unit_type)
	var unit       : Unit = unit_scene.instantiate() as Unit
	
	if unit == null:
		print("[ERROR] Unit scene not found for type: " + unit_name)
		return null
	
	unit.stat        = _unit_stat
	unit.stat.player = self
	unit.position    = _position
	
	add_unit(unit)
	return unit


func add_unit(_unit : Unit) -> void:
	units.append(_unit)
	unit_list.add_child(_unit)


func disband_unit(_unit : Unit) -> void:
	var unit_index : int = units.find(_unit)
	if unit_index == -1:
		print("[ERROR] Attempted to disband unit not in units array: ", _unit)
		return

	units.remove_at(unit_index)
	_unit.disband()
	unit_list.remove_child(_unit)
	_unit.queue_free()

#endregion


#region GAME PERSISTENCE
func new_game() -> void:
	print("[Player] New Player")
	
	# debug()
	
	## new game?
	# var settler       : UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, 1)
	# var settler_unit  : Unit = create_unit(settler, Vector2.ZERO)

	# var ship       : UnitStats = UnitStats.New_Unit(Term.UnitType.SHIP, 1)
	# var shore_tile : Vector2i = Def.get_world_map().get_random_starting_tile()
	# var ship_pos   : Vector2 = Def.get_world_tile_map().map_to_local(shore_tile)
	# var ship_unit  : Unit = create_unit(ship, ship_pos)

	# ship_unit.stat.attached_units.append(settler_unit.stat)
	
	# # Set camera to player ship..
	# Def.get_world().world_camera.position = ship_unit.position


func on_save_data() -> Dictionary:
	print("[Player] Save Player")

	# Get base agent data
	var data : Dictionary = super.on_save_data()

	# -- Package units..
	var unit_data : Array[Dictionary] = []
	for unit: Unit in units:
		unit_data.append({
			"position" : unit.position,
			"stat" : unit.stat.on_save_data(),
		})

	# Add player-specific data
	data["colony_manager"] = cm.on_save_data()
	data["units"] = unit_data

	return data


func on_load_data(_data: Dictionary) -> void:
	print("[Player] Load Player")

	# Load base agent data
	super.on_load_data(_data)

	# -- Load colonies..
	cm.on_load_data(_data["colony_manager"])

	# -- Load units..
	for unit_data: Dictionary in _data["units"]:
		var stat : UnitStats = UnitStats.New_Unit(unit_data.stat.unit_type, unit_data.stat.level)
		# Set player reference BEFORE loading data to ensure attached units get the reference
		stat.player = self
		stat.on_load_data(unit_data.stat)

		var unit : Unit = create_unit(stat, unit_data.position)
		if unit == null:
			print("[ERROR] Failed to create unit during load. Type: ", stat.unit_type, " Level: ", stat.level)
			continue

#endregion


func debug() -> void:
	"""
	Create colony
	"""
	# cm.found_colony(Vector2i(27, 8), Vector2(0, 0), 1)
	# cm.create_colony()
	#Def.get_world().world_camera.position = cm.get_colonies()[0].global_position

	"""
	NOTE: this really doesn't work due to race conditions..
	"""
	# var center : CenterBuilding = cm.get_colonies()[0] as CenterBuilding
	# center.create_building(Term.BuildingType.DOCK)
	# center.bm._update_temp_building(Vector2i(5, 11))
	# center.bm._place_temp_building()

	# -- Just a Settler..
	var settler       : UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, 1)
	var settler_pos   : Vector2 = Def.get_world_tile_map().map_to_local(Vector2i(51, 32))
	var settler_unit  : Unit = create_unit(settler, settler_pos)
	# Def.get_world().world_camera.position = settler_unit.position
	
	var ship       : UnitStats = UnitStats.New_Unit(Term.UnitType.SHIP, 1)
	# var shore_tile : Vector2i = Def.get_world_map().get_random_starting_tile()
	# var ship_pos   : Vector2 = Def.get_world_tile_map().map_to_local(shore_tile)
	var ship_pos   : Vector2 = Def.get_world_tile_map().map_to_local(Vector2i(53, 32))
	var ship_unit  : Unit = create_unit(ship, ship_pos)
	
	# Set camera to player ship..
	Def.get_world().world_camera.position = ship_unit.position
	
	# var e1      : UnitStats = UnitStats.New_Unit(Term.UnitType.EXPLORER, 1)
	# var e1_pos  : Vector2 = Def.get_world_tile_map().map_to_local(Vector2i(51, 32))
	# var e1_unit : Unit = create_unit(e1, e1_pos)
	# var e2      : UnitStats = UnitStats.New_Unit(Term.UnitType.EXPLORER, 1)
	# var e2_pos  : Vector2 = Def.get_world_tile_map().map_to_local(Vector2i(52, 32))
	# var e2_unit : Unit = create_unit(e2, e2_pos)
	# var leader : UnitStats = UnitStats.New_Unit(Term.UnitType.LEADER, 1)
	# leader.attach_unit(UnitStats.New_Unit(Term.UnitType.INFANTRY, 2))
	# leader.attached_units.append(UnitStats.New_Unit(Term.UnitType.INFANTRY, 2))
	# ship_unit.stat.attached_units.append(leader)

	# -- Units attached to ship..
	# ship_unit.stat.attached_units.append(UnitStats.New_Unit(Term.UnitType.SETTLER, 1))
	# ship_unit.stat.attached_units.append(UnitStats.New_Unit(Term.UnitType.EXPLORER, 1))
	# ship_unit.stat.attached_units.append(UnitStats.New_Unit(Term.UnitType.EXPLORER, 1))

	# --
	# call_deferred("begin_turn")
