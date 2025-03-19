extends Node2D
class_name Player

@onready var timer := $Timer as Timer
@onready var cm    := $ColonyManager as ColonyManager

@export var is_human : bool = true
@export var is_turn  : bool = true

var turn_number : int = 0


func _ready() -> void:
	if Def.FOG_OF_WAR_ENABLED and is_human:
		timer.connect("timeout", _on_timer_timeout)
		timer.wait_time = 1.0
		timer.start()

	# -- Assure correct Player..
	for unit : Unit in get_units():
		unit.stat.player = self

	# --
	call_deferred("debug")


func debug() -> void:
	"""
	Create colony
	"""
	cm.found_colony(Vector2i(8, 11), Vector2(0, 0), 1)
	cm.create_colony()

	"""
	NOTE: this really doesn't work due to race conditions..
	"""
	# var center : CenterBuilding = cm.get_colonies()[0] as CenterBuilding
	# center.create_building(Term.BuildingType.DOCK)
	# center.bm._update_temp_building(Vector2i(5, 11))
	# center.bm._place_temp_building()

	# -- Starting Ship
	# var coast_tiles : Array[Vector2i] = Def.get_world_map().get_coast_tiles()
	# var start_tile  : Vector2i = coast_tiles.pick_random()
	
	var ship     : UnitStats = UnitStats.New_Unit(Term.UnitType.SHIP, 1)
	var ship_pos : Vector2 = Def.get_world_tile_map().map_to_local(Vector2i(2, 4))
	var ship_unit : Unit = create_unit(ship, ship_pos)
	
	var leader : UnitStats = UnitStats.New_Unit(Term.UnitType.LEADER, 1)
	leader.attach_unit(UnitStats.New_Unit(Term.UnitType.INFANTRY, 2))
	leader.attached_units.append(UnitStats.New_Unit(Term.UnitType.INFANTRY, 2))
	ship_unit.stat.attached_units.append(leader)

	ship_unit.stat.attached_units.append(UnitStats.New_Unit(Term.UnitType.SETTLER, 1))
	ship_unit.stat.attached_units.append(UnitStats.New_Unit(Term.UnitType.EXPLORER, 1))
	ship_unit.stat.attached_units.append(UnitStats.New_Unit(Term.UnitType.EXPLORER, 1))

	# --
	call_deferred("begin_turn")



func _on_timer_timeout() -> void:
	reveal_fog_of_war_for_units()


#region TURN MANAGEMENT
func begin_turn() -> void:
	print("[NOTE] Begin Turn - Player")

	is_turn = true

	# -- Canvas updates..
	var wc : WorldCanvas = Def.get_world_canvas()
	wc.turn_number = turn_number
	wc.refresh_current_ui()

	# -- Colony management..
	if turn_number > 0:
		begin_turn_for_colonies()

	# -- 
	if is_human:
		reveal_fog_of_war_for_units()

	turn_number += 1
		

func end_turn() -> void:
	is_turn = false

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


func get_colonies() -> Array[Node]:
	return cm.get_colonies()


func found_colony(_tile : Vector2i, _position: Vector2, _level:int = 1) -> void:
	cm.found_colony(_tile, _position, _level)


func undo_found_colony(_building:CenterBuilding) -> void:
	cm.undo_create_colony(_building)

#endregion


#region UNITS
func get_units() -> Array[Node]:
	return %Units.get_children() as Array[Node]


func reveal_fog_of_war_for_units() -> void:
	if not Def.FOG_OF_WAR_ENABLED:
		return
		
	for unit in get_units():
		Def.get_world().world_map.reveal_fog_of_war(unit.global_position, 24)


func get_military_units_by_colony(_colony : CenterBuilding) -> Array[Node]:
	var _units : Array[Node] = []
	for unit in get_units():
		if unit.unit_category == Term.UnitCategory.MILITARY and unit.colony == _colony:
			_units.append(unit)
	return _units


#func get_units_by_colony(_colony : CenterBuilding) -> Array[Node]:
	#var _units : Array[Node] = []
	#for unit in units:
		#if unit.colony == _colony:
			#_units.append(unit)
	#return _units


func get_ships() -> Array[Node]:
	var _units : Array[Node] = []
	for unit in get_units():
		if unit is ShipUnit:
			_units.append(unit)
	return _units


func create_unit(_unit_stat: UnitStats, _position:Vector2) -> Unit:
	var unit_scene : PackedScene = Def.get_unit_scene_by_type(_unit_stat.unit_type)
	var unit       : Unit = unit_scene.instantiate() as Unit
	
	unit.stat        = _unit_stat
	unit.stat.player = self
	unit.position    = _position
	
	add_unit(unit)
	return unit


func add_unit(_unit : Unit) -> void:
	$Units.add_child(_unit)


func disband_unit(_unit : Unit) -> void:
	_unit.disband()
	$Units.remove_child(_unit)

#endregion
