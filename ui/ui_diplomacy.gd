extends PanelContainer
class_name UIDiplomacy

@onready var btn_close : Button = %BtnClose as Button

func _ready() -> void:
	btn_close.connect("pressed", _on_close_pressed)


func _on_close_pressed() -> void:
	WorldService.get_world_canvas().close_all_ui()
