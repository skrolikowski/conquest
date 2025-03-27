extends PanelContainer
class_name GameMenu

@onready var btn_save_exit : Button = %BtnSaveExit as Button
@onready var btn_save_game : Button = %BtnSaveGame as Button


func _ready() -> void:
	btn_save_exit.connect("pressed", _on_save_exit)
	btn_save_game.connect("pressed", _on_save_game)


func _on_save_exit() -> void:
	pass


func _on_save_game() -> void:
	pass
