extends UIUnit
class_name UIShipUnit

@onready var unit_name	    : Label = %UnitName as Label
@onready var cargo_hold	    : Label = %CargoHold as Label
@onready var btn_close      : Button = %BtnClose as Button
@onready var btn_cargo      : Button = %BtnCargo as Button
@onready var btn_explore    : Button = %BtnExplore as Button
@onready var btn_detach_all : Button = %BtnDetachAll as Button


func _ready() -> void:
	super._ready()

	btn_close.connect("pressed", _on_close_pressed)
	btn_cargo.connect("pressed", _on_cargo_pressed)
	btn_explore.connect("pressed", _on_explore_pressed)
	btn_detach_all.connect("pressed", _on_detach_all_pressed)


func refresh_ui() -> void:
	super.refresh_ui()
	
	# --
	btn_explore.disabled    = not unit.can_explore()
	btn_detach_all.disabled = not unit.can_detach_unit()
	
	# -- Explort button
	if unit.is_exploring:
		btn_explore.text = "Halt"
	else:
		btn_explore.text = "Explore"
	
	# -- Unit name
	unit_name.text = "Name: " + unit.stat.unit_name
	
	# -- Cargo Hold
	var unit_count    : int = unit.stat.attached_units.size()
	var unit_capacity : int = unit.stat.max_attached_units
	cargo_hold.text = "Cargo Hold: " + str(unit_count) + "/" + str(unit_capacity)


func _on_cargo_pressed() -> void:
	Def.get_world_canvas().open_carrier_unit_list(unit)


func _on_explore_pressed() -> void:
	#TODO: mark as exploring (e.g. desire to uncover "fog of war")
	#TODO: w/ persistent behavior, unit will explore on begin turn
	pass


func _on_detach_all_pressed() -> void:
	unit = unit as CarrierUnit
	unit.detach_all_units()
	
	# -- close "unit list" if applicable..
	# var world_canvas:WorldCanvas = Def.get_world_canvas()
	# world_canvas.close_ui(world_canvas.current_unit_list_ui)


func _on_close_pressed() -> void:
	Def.get_world_canvas().close_all_ui()
