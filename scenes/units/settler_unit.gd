extends Unit
class_name SettlerUnit


func _ready() -> void:
	super._ready()
	
	stat.title     = "Settler"
	stat.unit_type = Term.UnitType.SETTLER


#region SETTLER ACTIONS
func can_settle() -> bool:
	var colony_mgmt : ColonyManager = Def.get_player_manager().player.cm
	return colony_mgmt.can_settle(get_tile())


func settle() -> void:
	stat.player.found_colony(get_tile(), global_position, stat.level)
	stat.player.disband_unit(self)

	Def.get_world_selector().clear_selection()

#endregion


#region STATUS INFORMATION
func get_status_information(_tile: Vector2i) -> String:
	var text : String = super.get_status_information(_tile)

	var stats       : Dictionary = Def.get_unit_stat(Term.UnitType.SETTLER, stat.level)
	var transaction : Transaction = Def._convert_to_transaction(stats.resources)
	var carrying    : PackedStringArray	= PackedStringArray()
	carrying.append(str(stats.people) + " people")

	for i: String in Term.ResourceType:
		var resource_type  : Term.ResourceType = Term.ResourceType[i]
		var resource_name  : String = Def._convert_resource_type_to_name(resource_type)
		var resource_value : int = transaction.get_resource_amount(resource_type)
		
		if resource_value > 0:
			carrying.append(str(resource_value) + " " + resource_name)

	return text + " " + Def.STATUS_SEP + " Carrying: " + ", ".join(carrying)
#endregion
