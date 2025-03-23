extends Area2D
class_name Unit

# signal move_points_changed(_move_points:float, _max_move_points:float)

@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var shape     := $CollisionShape2D as CollisionShape2D

@export var stat : UnitStats

# -- Movement..
var is_moving       : bool = false
var move_delta      : Vector2
var move_points     : float = 64.0
var max_move_points : float = 64.0
var move_speed      : float = 48.0 * 0.8

# -- Entering a "carrier node"..
var entering_node : Node : set = _set_entering_node
var over_node     : Node : set = _set_over_node


func _ready() -> void:
	connect("area_entered", _on_area_entered)
	connect("area_exited", _on_area_exited)


func _process(_delta: float) -> void:
	if is_moving and move_points > 0:
		if not nav_agent.is_target_reached():
			
			# -- Get current tile data..
			var tile_map_layer : TileMapLayer = Def.get_world_map().tilemap_layers[WorldGen.MapLayer.LAND]
			var map_position   : Vector2 = tile_map_layer.local_to_map(global_position)
			var tile_data      : TileData = tile_map_layer.get_cell_tile_data(map_position)
			#TODO: set this, see: `world_map`
			#var terrain_weight : float = tile_data.get_custom_data("weight")
			var terrain_weight : float = 1
			
			# -- Movement..
			var move_target    : Vector2 = nav_agent.get_next_path_position()
			var move_direction : Vector2 = (move_target - global_position).normalized()
			var move_gain      : float = move_speed * terrain_weight * _delta
			global_position += move_direction * move_gain

			# -- move cost..
			#move_points -= move_speed * _delta

			# -- signal..
			# move_points_changed.emit(move_points, max_move_points)s
				
		else:
			is_moving = false


func _draw() -> void:
	draw_line(Vector2.ZERO, move_delta, Color.LIGHT_GRAY, 2)


func get_tile() -> Vector2i:
	return Def.get_world_map().get_water_layer().local_to_map(global_position - shape.shape.size * 0.5)


func get_tile_position() -> Vector2:
	var tile_map  : TileMap = Def.get_world().world_map.tile_map
	return tile_map.map_to_local(get_tile()) + shape.shape.size * 0.5


func can_attack() -> bool:
	# -- Allow for unchecking..
	if stat.unit_state == Term.UnitState.ATTACK:
		return true

	return stat.unit_type == Term.UnitType.LEADER and stat.unit_state == Term.UnitState.IDLE


func can_persist() -> bool:
	return true


#region DISBANDING UNIT
func can_disband() -> bool:
	# -- Allow for unchecking..
	if stat.unit_state == Term.UnitState.DISBAND:
		return true

	return stat.unit_state == Term.UnitState.IDLE or stat.unit_state == Term.UnitState.EXPLORE


func disband() -> void:
	queue_free()

#endregion


#region EXPLORING UNIT
var is_exploring : bool = false

func can_explore() -> bool:
	return stat.unit_type == Term.UnitType.EXPLORER or stat.unit_type == Term.UnitType.SHIP

#endregion


#region SELECTION/MOVEMENT
func on_selected() -> void:
	is_moving     = false
	entering_node = null


func on_drag_release(_position: Vector2) -> void:
	nav_agent.target_position = _position
	
	if nav_agent.is_target_reachable():
		is_moving = true
		
		var collision : Node = Def.get_world().detect_collision(_position)
		if collision:
			if collision is CenterBuilding:
				entering_node = collision as CenterBuilding
			elif collision is CarrierUnit:
				entering_node = collision as CarrierUnit
			
			# # -- Are we on top of the `entering_node`..?
			# if entering_node != null and over_node == entering_node:
			# 	on_enter_node(over_node)
		
	
func on_enter_node(_node: Node) -> void:
	"""
	Unit enters a "Carrier Node".. (e.g. CenterBuilding, CarrierUnit)
	"""
	var _stat : UnitStats = stat.duplicate()
	_node.stat.attached_units.append(_stat)

	Def.get_world().unselect_all()

	queue_free()


func _set_entering_node(_node: Node) -> void:
	"""
	[SET] Entering a "Carrier Node"..
	"""
	entering_node = _node

	# -- Are we entering the expected ..?
	if entering_node != null and over_node == entering_node:
		on_enter_node(over_node)


func _set_over_node(_over_node: Node) -> void:
	"""
	[SET] Over a "Carrier Node"..
	"""
	over_node = _over_node

	# -- Are we entering the expected ..?
	if over_node != null and entering_node == over_node:
		on_enter_node(over_node)

#endregion


#region EVENT HANDLERS
func _on_area_entered(_area: Area2D) -> void:
	"""
	Unit enters an Area2D..
	"""
	if _area is CenterBuilding:
		over_node = _area as CenterBuilding
	elif _area is Carrier:
		over_node = _area.unit as CarrierUnit
		
	# # -- Are we entering the expected ..?
	# if over_node != null and entering_node == over_node:
	# 	on_enter_node(over_node)
			
		
func _on_area_exited(_area: Area2D) -> void:
	"""
	Unit exits an Area2D..
	"""
	if over_node == _area:
		over_node = null

#endregion


#region STATUS INFORMATION
func get_status_information(_tile: Vector2i) -> String:
	var text : PackedStringArray = PackedStringArray()
	
	# -- unit name/level
	var unit_name : String = Def._convert_unit_type_to_name(stat.unit_type)
	unit_name = "Lv. " + str(stat.level) + " " + unit_name
	text.append(unit_name)

	# -- movement
	# var movement : float = move_points / 64
	# text.append("Movement: " + str(movement) + "%")


	return (" " + Def.STATUS_SEP + " ").join(text)
#endregion
