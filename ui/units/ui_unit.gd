extends PanelContainer
class_name UIUnit

var unit       : Unit : set = _set_unit
var unit_state : Term.UnitState


func _ready() -> void:
	%UnitDisband.connect("toggled", _on_unit_disband_toggled)
	%UnitPersistent.connect("toggled", _on_unit_persistent_toggled)


func _process(_delta:float) -> void:
	if unit == null:
		#TODO: is this okay?
		queue_free()
	else:
		if unit.is_moving:
			refresh_ui()


func refresh_ui() -> void:
	%UnitDisband.set_pressed_no_signal(unit.stat.unit_state == Term.UnitState.DISBAND)
	%UnitDisband.disabled = not unit.can_disband()

	%UnitPersistent.set_pressed_no_signal(unit.is_persistent)
	%UnitPersistent.disabled  = not unit.can_persist()

	#TODO: get max move points
	%MovementValue.value = unit.move_points / 64


func _set_unit(_unit: Unit) -> void:
	unit = _unit
	unit_state = unit.stat.unit_state
	
	%UnitTitle.text = unit.stat.title
	%UnitLevel.text = "Level: " + str(unit.stat.level)

	# --
	refresh_ui()
	
	
func _on_unit_disband_toggled(_toggled_on: bool) -> void:
	if _toggled_on:
		unit.stat.unit_state = Term.UnitState.DISBAND
	else:
		if unit_state == Term.UnitState.DISBAND:
			unit.stat.unit_state = Term.UnitState.IDLE
		else:
			unit.stat.unit_state = unit_state
	
	refresh_ui()


func _on_unit_persistent_toggled(_toggled_on: bool) -> void:
	unit.is_persistent = _toggled_on
		
	refresh_ui()
