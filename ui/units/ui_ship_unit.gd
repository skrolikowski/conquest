extends UIUnit
class_name UIShipUnit


func _ready() -> void:
	super._ready()

	%UnitsAttached.connect("pressed", _on_units_attached_pressed)
	%Explore.connect("pressed", _on_explore_pressed)
	%DetachAll.connect("pressed", _on_detach_all_pressed)


func refresh_ui() -> void:
	super.refresh_ui()
	
	# --
	var can_detach_unit : bool = unit.can_detach_unit()
	
	%UnitsAttached.disabled = not can_detach_unit
	%Explore.disabled       = not unit.can_explore()
	%DetachAll.disabled     = not can_detach_unit
	
	# -- Explort button
	if unit.is_exploring:
		%Explore.text = "Halt"
	else:
		%Explore.text = "Explore"
	
	# -- Unit name
	%UnitName.text = unit.stat.unit_name
	
	# -- Cargo Hold
	var unit_count    : int = unit.stat.attached_units.size()
	var unit_capacity : int = unit.stat.max_attached_units
	%CargoHold.text = "Cargo Hold: " + str(unit_count) + "/" + str(unit_capacity)


func _on_units_attached_pressed() -> void:
	Def.get_world_canvas().open_carrier_unit_list(unit)


func _on_explore_pressed() -> void:
	#TODO: mark as exploring (e.g. desire to uncover "fog of war")
	#TODO: w/ persistent behavior, unit will explore on begin turn
	pass


func _on_detach_all_pressed() -> void:
	unit = unit as CarrierUnit
	unit.detach_all_units()
	
	# -- close "unit list" if applicable..
	var world_canvas:WorldCanvas = Def.get_world_canvas()
	world_canvas.close_ui(world_canvas.current_unit_list_ui)
