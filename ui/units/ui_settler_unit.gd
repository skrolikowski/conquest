extends UIUnit
class_name UISettlerUnit

@onready var btn_found_colony := %BtnFoundColony as Button

func _ready() -> void:
	super._ready()

	btn_found_colony.connect("pressed", _on_found_colony_pressed)
	

func refresh_ui() -> void:
	super.refresh_ui()
	
	# --
	btn_found_colony.disabled  = not unit.can_settle()


func _on_found_colony_pressed() -> void:
	unit.settle()
