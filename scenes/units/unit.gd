extends Area2D
class_name Unit


@onready var sprite    := $Sprite2D as Sprite2D
@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var shape     := $CollisionShape2D as CollisionShape2D

@export var stat : UnitStats

var selected : bool : set = _set_selected
var selection_tween : Tween

# -- Movement..
var is_moving  : bool = false
var move_delta : Vector2


func _ready() -> void:
	if Preload.C.FOG_OF_WAR_ENABLED:
		nav_agent.connect("target_reached", _on_target_reached)
		nav_agent.connect("waypoint_reached", _on_waypoint_reached)


func _on_target_reached() -> void:
	pass


func _on_waypoint_reached(_details: Dictionary) -> void:
	# Real-time fog reveal during movement
	FogOfWarService.reveal_around_unit(self)


func _process(_delta: float) -> void:
	if is_moving and stat.move_points > 0:
		if not nav_agent.is_target_reached():
			
			# -- Get TileCustomData or current position..
			var world_map         : WorldGen = Def.get_world_map()
			var unit_tile         : Vector2i = get_tile()
			var tile_custom_data  : TileCustomData = world_map.get_tile_custom_data(unit_tile)
			var movement_modifier : float = 30.0
			
			if not self is ShipUnit:
				movement_modifier = tile_custom_data.get_movement_modifier_by_unit_type(stat.unit_type)
			
			# -- Movement..
			var base_move_speed : float = 48.0
			var move_speed      : float = base_move_speed * (movement_modifier / 30.0) * _delta
			var move_target     : Vector2 = nav_agent.get_next_path_position()
			var move_direction  : Vector2 = (move_target - global_position).normalized()
			global_position += move_direction * move_speed

			# -- Reduce move points..
			# stat.move_points -= base_move_speed * 0.1 * _delta
			# stat.move_points = max(0, stat.move_points)
		else:
			is_moving = false


func _draw() -> void:
	draw_line(Vector2.ZERO, move_delta, Color.LIGHT_GRAY, 2)


func get_tile() -> Vector2i:
	# return Def.get_world_map().get_water_layer().local_to_map(global_position) - shape.shape.size * 0.5)
	return Def.get_world_map().get_water_layer().local_to_map(global_position)


func get_tile_position() -> Vector2:
	var tile_map  : TileMap = Def.get_world().world_map.tile_map
	return tile_map.map_to_local(get_tile()) + shape.shape.size * 0.5


func can_attack() -> bool:
	# -- Allow for unchecking..
	if stat.unit_state == Term.UnitState.ATTACK:
		return true

	return stat.unit_type == Term.UnitType.LEADER and stat.unit_state == Term.UnitState.IDLE




#region PERSISTENT MOVEMENT
func can_persist() -> bool:
	return true

#endregion


#region DISBANDING UNIT
func can_disband() -> bool:
	# -- Allow for unchecking..
	if stat.unit_state == Term.UnitState.DISBAND:
		return true

	return stat.unit_state == Term.UnitState.IDLE or stat.unit_state == Term.UnitState.EXPLORE


func disband() -> void:
	#TODO: what about attached_units?
	queue_free()

#endregion


#region SELECTION
func _set_selected(_selected: bool) -> void:
	if selected != _selected:
		selected = _selected

		if selected:
			_start_pulse_effect()
			is_moving = false
		else:
			_stop_pulse_effect()


func _start_pulse_effect() -> void:
	selection_tween = create_tween()
	selection_tween.set_ease(Tween.EASE_IN_OUT)
	selection_tween.set_trans(Tween.TRANS_SINE)
	selection_tween.set_loops(-1)

	# -- Set highlight effect..
	selection_tween.tween_property(sprite, "modulate", Color.LIGHT_GRAY, 0.5)
	selection_tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)


func _stop_pulse_effect() -> void:
	selection_tween.stop()

	sprite.modulate = Color.WHITE

#endregion


#region INPUT
func on_drag_release(_position: Vector2) -> void:
	nav_agent.target_position = _position
	nav_agent.target_position = nav_agent.get_final_position()
	
	is_moving = nav_agent.is_target_reachable()

	# --
	if is_moving:
		#TODO: detect collision with a "Carrier Node"..
		var collision : Node = Def.get_world_selector().point_collision(_position, Term.CollisionMask.CARRIER)
		if collision:
			if collision is CarrierManager:
				var carrier : CarrierManager = collision as CarrierManager
				carrier.add_unit_entering(self)
			elif collision is CenterBuilding:
				# var center : CenterBuilding = collision as CenterBuilding
				# center.entering_node = self
				#TODO: add to center building
				pass

#endregion


#region STATUS INFORMATION
func get_status_information(_tile: Vector2i) -> String:
	var text : PackedStringArray = PackedStringArray()
	
	# -- unit name/level
	var unit_name : String = PreloadsRef.TR.unit_type_to_name(stat.unit_type)
	unit_name = "Lv. " + str(stat.level) + " " + unit_name
	text.append(unit_name)

	# -- movement
	# var movement : float = move_points / 64
	# text.append("Movement: " + str(movement) + "%")


	return (" " + Preload.C.STATUS_SEP + " ").join(text)
#endregion


#region TURN MANAGEMENT
func begin_turn() -> void:

	# -- Reset move points..
	stat.move_points = stat.get_stat().move_points

	# -- Reset unit state..
	stat.unit_state = Term.UnitState.IDLE

	# Note: Fog of war is now handled by Player via FogOfWarService


func end_turn() -> void:
	pass

#endregion
