extends PanelContainer
class_name UIUnit

@onready var unit_title     : Label = %UnitTitle as Label
@onready var unit_level     : Label = %UnitLevel as Label
@onready var unit_movement  : ProgressBar = %MovementValue as ProgressBar
@onready var btn_close      : Button = %BtnClose as Button
@onready var btn_disband    : Button = %BtnDisband as Button
@onready var btn_persistent : Button = %BtnPersistent as Button

var unit       : Unit : set = _set_unit
var unit_state : Term.UnitState


func _ready() -> void:
	btn_close.connect("pressed", _on_close_pressed)
	btn_disband.connect("toggled", _on_unit_disband_toggled)
	btn_persistent.connect("toggled", _on_unit_persistent_toggled)


func _process(_delta:float) -> void:
	if unit == null:
		#TODO: is this okay?
		queue_free()
	else:
		if unit.is_moving:
			refresh_ui()


func refresh_ui() -> void:
	btn_disband.set_pressed_no_signal(unit.stat.unit_state == Term.UnitState.DISBAND)
	btn_disband.disabled = not unit.can_disband()

	btn_persistent.set_pressed_no_signal(unit.stat.is_persistent)
	btn_persistent.disabled  = not unit.can_persist()

	#TODO: get max move points
	var move_points     : float = unit.stat.move_points
	var max_move_points : float = unit.stat.get_stat().move_points
	unit_movement.value = snapped(move_points / max_move_points, 0.01)


func _set_unit(_unit: Unit) -> void:
	unit = _unit
	unit_state = unit.stat.unit_state
	
	unit_title.text = unit.stat.title
	unit_level.text = "Level: " + str(unit.stat.level)

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


func _on_close_pressed() -> void:
	Def.get_world_canvas().close_all_ui()
