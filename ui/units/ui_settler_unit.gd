extends UIUnit
class_name UISettlerUnit


func _ready() -> void:
	super._ready()

	%FoundColony.connect("pressed", _on_found_colony_pressed)
	

func refresh_ui() -> void:
	super.refresh_ui()
	
	# --
	%FoundColony.disabled  = not unit.can_settle()


func _on_found_colony_pressed() -> void:
	unit.settle()
