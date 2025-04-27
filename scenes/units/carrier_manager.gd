extends Area2D
class_name CarrierManager

@export var unit : CarrierUnit

var units_entering : Array[Unit] = []
var units_over     : Array[Unit] = []


func _ready() -> void:
	connect("area_entered", _on_area_entered)
	connect("area_exited", _on_area_exited)


func add_unit_entering(_unit: Unit) -> void:
	units_entering.append(_unit)
	_make_attachments()


func _make_attachments() -> void:
	for unit_over : Unit in units_over:
		if unit_over in units_entering:
			# -- Attach unit to carrier..
			unit.stat.attach_unit(unit_over.stat)
			units_entering.erase(unit_over)
			unit_over.queue_free()

		Def.get_world().world_selector.clear_selection()

#region EVENT HANDLERS
func _on_area_entered(_area: Area2D) -> void:
	if _area is Unit and not _area is CarrierUnit:
		units_over.append(_area as Unit)
		_make_attachments()


func _on_area_exited(_area: Area2D) -> void:
	if _area in units_over:
		units_over.erase(_area)

#endregion
