extends CarrierUnit
class_name ShipUnit

@onready var explore_manager := $ExploreManager as ExploreManager

var is_exploring : bool : set = _set_is_exploring


func _ready() -> void:
	super._ready()

	explore_manager.unit = self
	
	stat.title     = "Ship"
	stat.unit_type = Term.UnitType.SHIP


func _set_is_exploring(_exploring: bool) -> void:
	is_exploring = _exploring
	explore_manager.is_exploring = is_exploring
	
	if is_exploring:
		stat.unit_state = Term.UnitState.EXPLORE
	else:
		stat.unit_state = Term.UnitState.IDLE


func _set_selected(_selected: bool) -> void:
	super._set_selected(_selected)
	is_exploring = false
