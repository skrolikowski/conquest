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
	%UnitDisband.disabled = not unit.can_disband()
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
	
	
func _on_unit_disband_toggled(toggled_on:bool) -> void:
	if toggled_on:
		unit.stat.unit_state = Term.UnitState.DISBAND
	else:
		unit.stat.unit_state = unit_state
	
	refresh_ui()


func _on_unit_persistent_toggled(toggled_on:bool) -> void:
	if toggled_on:
		unit.stat.unit_state = Term.UnitState.EXPLORE
	else:
		unit.stat.unit_state = unit_state
		
	refresh_ui()
