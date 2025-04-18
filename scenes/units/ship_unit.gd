extends CarrierUnit
class_name ShipUnit

var is_exploring : bool : set = _set_is_exploring


func _ready() -> void:
	super._ready()
	
	stat.title     = "Ship"
	stat.unit_type = Term.UnitType.SHIP


func _set_is_exploring(_exploring: bool) -> void:
	is_exploring = _exploring
	
	if is_exploring:
		stat.unit_state = Term.UnitState.EXPLORE
	else:
		stat.unit_state = Term.UnitState.IDLE

	#TODO: mark as exploring (e.g. desire to uncover "fog of war")
	#TODO: w/ persistent behavior, unit will explore on begin turn
