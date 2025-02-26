extends CarrierUnit
class_name LeaderUnit


func _ready() -> void:
	super._ready()
	
	stat.title      = "Leader"
	stat.unit_name  = "John Doe"
	stat.unit_type  = Term.UnitType.LEADER
	stat.unit_state = Term.UnitState.IDLE
	stat.stat_props = {
		"attacks_in_combat": 0,
		"move_bonus": 0,
		"charisma": 0,
		"reputation": 0
	}


#region STATUS INFORMATION
func get_status_information(_tile: Vector2i) -> String:
	var text : String = super.get_status_information(_tile)

	text += " " + Def.STATUS_SEP + " Charisma: " + str(stat.stat_props["charisma"])
	text += " " + Def.STATUS_SEP + " Reputation: " + str(stat.stat_props["reputation"])
	text += " " + Def.STATUS_SEP + " Units: " + str(stat.attached_units.size())

	return text

#endregion
