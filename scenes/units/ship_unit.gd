extends CarrierUnit
class_name ShipUnit


func _ready() -> void:
	super._ready()
	
	stat.title     = "Ship"
	stat.unit_type = Term.UnitType.SHIP

