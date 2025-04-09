extends Node2D
class_name Player

@onready var unit_list := $UnitList as Node2D
@onready var timer     := $Timer as Timer
@onready var cm        := $ColonyManager as ColonyManager

var units : Array[Unit] = []


func _ready() -> void:
	if Def.FOG_OF_WAR_ENABLED:
		timer.connect("timeout", _on_timer_timeout)
		timer.wait_time = 1.0
		timer.start()


func _on_timer_timeout() -> void:
	reveal_fog_of_war_for_units()


#region TURN MANAGEMENT
func begin_turn() -> void:
	print("[NOTE] Begin Turn - Player")

	# -- Colony management..
	if Def.get_world().turn_number > 0:
		begin_turn_for_colonies()

	# -- Fog of war..
	# reveal_fog_of_war_for_units()
		

func end_turn() -> void:
	pass

#endregion


#region COLONIES
func begin_turn_for_colonies() -> void:
	for colony:CenterBuilding in get_colonies():
		if colony.building_state == Term.BuildingState.NEW:
			colony.building_state = Term.BuildingState.ACTIVE
		else:
			if colony.building_state == Term.BuildingState.UPGRADE:
				colony.upgrade_building(colony)

		colony.begin_turn()


func get_colonies() -> Array[CenterBuilding]:
	return cm.get_colonies()


func found_colony(_tile : Vector2i, _position: Vector2, _level:int = 1) -> void:
	cm.found_colony(_tile, _position, _level)


func undo_found_colony(_building:CenterBuilding) -> void:
	cm.undo_create_colony(_building)

#endregion


#region UNITS
func reveal_fog_of_war_for_units() -> void:
	if not Def.FOG_OF_WAR_ENABLED:
		return
	
	# --
	for unit in units:
		Def.get_world().world_map.reveal_fog_of_war(unit.global_position, 24)


func get_military_units_by_colony(_colony : CenterBuilding) -> Array[Unit]:
	var _units : Array[Unit] = []
	for unit : Unit in units:
		if unit.unit_category == Term.UnitCategory.MILITARY and unit.colony == _colony:
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
	var unit_scene : PackedScene = Def.get_unit_scene_by_type(_unit_stat.unit_type)
	var unit       : Unit = unit_scene.instantiate() as Unit
	
	unit.stat        = _unit_stat
	unit.stat.player = self
	unit.position    = _position
	
	add_unit(unit)
	return unit


func add_unit(_unit : Unit) -> void:
	units.append(_unit)
	unit_list.add_child(_unit)


func disband_unit(_unit : Unit) -> void:
	units.remove_at(units.find(_unit))
	_unit.disband()
	unit_list.remove_child(_unit)
	_unit.queue_free()

#endregion


#region GAME PERSISTENCE
func new_game() -> void:
	print("[Player] New Player")
	
	debug()


func on_save_data() -> Dictionary:
	print("[Player] Save Player")

	# -- Package units..
	var unit_data : Array[Dictionary] = []
	for unit: Unit in units:
		unit_data.append({
			"position" : unit.position,
			"is_persistent" : unit.is_persistent,
			"move_points" : unit.move_points,
			"stat" : unit.stat.on_save_data(),
		})

	return {
		"colony_manager" : cm.on_save_data(),
		"units": unit_data,
	}


func on_load_data(_data: Dictionary) -> void:
	print("[Player] Load Player")

	# -- Load colonies..
	cm.on_load_data(_data["colony_manager"])

	# -- Load units..
	for unit_data: Dictionary in _data["units"]:
		var stat : UnitStats = UnitStats.New_Unit(unit_data.stat.unit_type, unit_data.stat.level)
		stat.on_load_data(unit_data.stat)
		
		var unit : Unit = create_unit(stat, unit_data.position)
		unit.is_persistent = unit_data.is_persistent
		unit.move_points   = unit_data.move_points

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
	#var settler       : UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, 1)
	#var settler_pos   : Vector2 = Def.get_world_tile_map().map_to_local(Vector2i(26, 8))
	#var settler_unit  : Unit = create_unit(settler, settler_pos)
	#Def.get_world().world_camera.position = settler_unit.position
	
	var ship       : UnitStats = UnitStats.New_Unit(Term.UnitType.SHIP, 1)
	var shore_tile : Vector2i = Def.get_world_map().get_random_shore_tile()
	# var ship_pos   : Vector2 = Def.get_world_tile_map().map_to_local(shore_tile)
	var ship_pos   : Vector2 = Def.get_world_tile_map().map_to_local(Vector2i(43, 32))
	var ship_unit  : Unit = create_unit(ship, ship_pos)
	Def.get_world().world_camera.position = ship_unit.position
	
	# var leader : UnitStats = UnitStats.New_Unit(Term.UnitType.LEADER, 1)
	# leader.attach_unit(UnitStats.New_Unit(Term.UnitType.INFANTRY, 2))
	# leader.attached_units.append(UnitStats.New_Unit(Term.UnitType.INFANTRY, 2))
	# ship_unit.stat.attached_units.append(leader)

	ship_unit.stat.attached_units.append(UnitStats.New_Unit(Term.UnitType.SETTLER, 1))
	# ship_unit.stat.attached_units.append(UnitStats.New_Unit(Term.UnitType.EXPLORER, 1))
	# ship_unit.stat.attached_units.append(UnitStats.New_Unit(Term.UnitType.EXPLORER, 1))

	# --
	# call_deferred("begin_turn")
