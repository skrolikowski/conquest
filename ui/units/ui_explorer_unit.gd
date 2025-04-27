extends UIUnit
class_name UIExplorerUnit

@onready var btn_explore := %BtnExplore as Button

func _ready() -> void:
	super._ready()

	btn_explore.connect("pressed", _on_explore_pressed)
	

func refresh_ui() -> void:
	super.refresh_ui()
	
	# -- Explorer Unit Data
	var explorer_unit : ExplorerUnit = unit as ExplorerUnit
	
	# --
	if explorer_unit.is_exploring:
		btn_explore.text = "Halt"
	else:
		btn_explore.text = "Explore"


func _on_explore_pressed() -> void:
	unit.is_exploring = not unit.is_exploring
	refresh_ui()
