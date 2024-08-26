extends UIUnit
class_name UIExplorerUnit

func _ready() -> void:
	super._ready()

	%Explore.connect("pressed", _on_explore_pressed)
	

func refresh_ui() -> void:
	super.refresh_ui()
	
	# --
	if unit.is_exploring:
		%Explore.text = "Halt"
	else:
		%Explore.text = "Explore"
		
	%Explore.disabled  = not unit.can_explore()


func _on_explore_pressed() -> void:
	unit.is_exploring = not unit.is_exploring
	#TODO: mark as exploring (e.g. desire to uncover "fog of war")
	#TODO: w/ persistent behavior, unit will explore on begin turn
	pass
