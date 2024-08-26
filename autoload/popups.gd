extends Control
class_name PopupsRef


func ItemPopup(rect:Rect2i) -> void:
	var mouse_pos : Vector2 = get_viewport().get_mouse_position()
	var correction : Vector2i
	
	if mouse_pos.x <= get_viewport_rect().size.x / 2:
		correction.x = rect.size.x
	else:
		correction.x = %ItemPopup.size.x

	if mouse_pos.y <= get_viewport_rect().size.y / 2:
		correction.y = rect.size.y
	else:
		correction.y = %ItemPopup.size.y
	
	%ItemPopup.popup(Rect2i(rect.position + correction, %ItemPopup.size))


func HideItemPopup() -> void:
	%ItemPopup.hide()
