extends Node2D
class_name Player

@onready var timer := $Timer as Timer
@onready var cm    := $ColonyManager as ColonyManager

@export var is_human : bool = true
@export var is_turn  : bool = true


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
	cm.found_colony(Vector2i(8, 11), Vector2(0, 0), 1)
	cm.create_colony()


#region COLONIES
func get_colonies() -> Array[Node]:
	return cm.get_colonies()


func found_colony(_tile : Vector2i, _position: Vector2, _level:int = 1) -> void:
	cm.found_colony(_tile, _position, _level)


func undo_found_colony(_building:CenterBuilding) -> void:
	cm.undo_create_colony(_building)

#endregion


func _on_timer_timeout() -> void:
	reveal_fog_of_war_for_units()


#region TURN MANAGEMENT
func begin_turn() -> void:
	for colony:CenterBuilding in get_colonies():
		colony.begin_turn()

	is_turn = true

	# -- 
	if is_human:
		reveal_fog_of_war_for_units()


func end_turn() -> void:
	is_turn = false

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


func create_unit(_unit_stat: UnitStats, _position:Vector2) -> void:
	var unit_scene : PackedScene = Def.get_unit_scene_by_type(_unit_stat.unit_type)
	var unit       : Unit = unit_scene.instantiate() as Unit
	
	unit.stat        = _unit_stat
	unit.stat.player = self
	unit.position    = _position
	
	add_unit(unit)


func add_unit(_unit : Unit) -> void:
	$Units.add_child(_unit)


func disband_unit(_unit : Unit) -> void:
	_unit.disband()
	$Units.remove_child(_unit)

#endregion
