extends PanelContainer
class_name UIFoundColony

var colony_manager : ColonyManager


func _ready() -> void:
	%FoundColony.connect("pressed", _on_found_colony_pressed)
	%CancelFound.connect("pressed", _on_cancel_found_pressed)

	WorldService.get_world_canvas().btn_close.connect("pressed", _on_cancel_found_pressed)


func _on_found_colony_pressed() -> void:
	colony_manager.create_colony()
	

func _on_cancel_found_pressed() -> void:
	colony_manager.cancel_found_colony()
