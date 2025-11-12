extends Unit
class_name SettlerUnit


func _ready() -> void:
	super._ready()
	
	stat.title     = "Settler"
	stat.unit_type = Term.UnitType.SETTLER


#region SETTLER ACTIONS

func can_settle() -> bool:
	if stat.player == null:
		push_error("Settler unit has no player assigned.")
		return false
	return stat.player.cm.can_settle(get_tile())


func settle() -> void:
	if stat.player == null:
		push_error("Settler unit has no player assigned.")
		return

	var result : ColonyFoundingWorkflow.Result = stat.player.found_colony(get_tile(), global_position, stat)
	if result.is_error():
		push_error("Failed to found colony: %s" % result.error_message)
		return

	# Success! Settler unit disappears (into the colony)
	stat.player.disband_unit(self)

	Def.get_world_selector().clear_selection()

#endregion


#region STATUS INFORMATION
func get_status_information(_tile: Vector2i) -> String:
	var text : String = super.get_status_information(_tile)

	var stats       : Dictionary = GameData.get_unit_stat(Term.UnitType.SETTLER, stat.level)
	var transaction : Transaction = Def._convert_to_transaction(stats.resources)
	var carrying    : PackedStringArray	= PackedStringArray()
	carrying.append(str(stats.people) + " people")

	for i: String in Term.ResourceType:
		var resource_type  : Term.ResourceType = Term.ResourceType[i]
		var resource_name  : String = Preload.TR.resource_type_to_name(resource_type)
		var resource_value : int = transaction.get_resource_amount(resource_type)
		
		if resource_value > 0:
			carrying.append(str(resource_value) + " " + resource_name)

	return text + " " + Preload.C.STATUS_SEP + " Carrying: " + ", ".join(carrying)
#endregion
