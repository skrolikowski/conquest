extends PanelContainer
class_name GameMenu

@onready var btn_save_exit : Button = %BtnSaveExit as Button
@onready var btn_save_game : Button = %BtnSaveGame as Button
@onready var btn_exit_game : Button = %BtnExitGame as Button


func _ready() -> void:
	btn_save_exit.connect("pressed", _on_save_exit)
	btn_save_game.connect("pressed", _on_save_game)
	btn_exit_game.connect("pressed", _on_exit_game)


func _on_new_game() -> void:
	Persistence.new_game()


func _on_save_exit() -> void:
	if Persistence.save_game():
		#TODO: Show "Game Saved!" notification
		get_tree().quit()
		pass
	else:
		#TODO: Show "Save Failed!" error
		pass


func _on_save_game() -> void:
	if Persistence.save_game():
		# Show "Game Saved!" notification
		pass
	else:
		# Show "Save Failed!" error
		pass


func _on_exit_game() -> void:
	get_tree().quit()
