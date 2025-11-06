extends UIUnit
class_name UILeaderUnit

@onready var btn_units_attached    := %BtnUnitsAttached as Button
@onready var btn_assign_experience := %BtnAssignExperience as Button
@onready var btn_detach_all        := %BtnDetachAll as Button


func _ready() -> void:
	super._ready()

	btn_assign_experience.connect("pressed", _on_units_attached_pressed)
	btn_detach_all.connect("pressed", _on_detach_all_pressed)


func _set_unit(_unit: Unit) -> void:
	super._set_unit(_unit)


	# -- Leader Unit Data
	_unit = _unit as LeaderUnit

	%UnitName.text = _unit.stat.unit_name

	# -- Leadership
	var unit_count    : int = _unit.stat.attached_units.size()
	var unit_capacity : int = _unit.stat.max_attached_units
	%Leadership.text = "Leadership: " + str(unit_count) + "/" + str(unit_capacity)
	
	btn_detach_all.disabled = not _unit.can_detach_unit()


func _on_units_attached_pressed() -> void:
	WorldService.get_world_canvas().open_carrier_unit_list(unit)


func _on_detach_all_pressed() -> void:
	unit = unit as CarrierUnit
	unit.detach_all_units()
