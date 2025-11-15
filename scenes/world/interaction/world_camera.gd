extends Camera2D
class_name WorldCamera

var move_speed : float = 600.0
var zoom_val   : float = 1.00
var zoom_min   : float = 0.25
var zoom_max   : float = 1.50
var zoom_step  : float = 0.25


func reset() -> void:
	position = Vector2(0, 0)
	zoom = Vector2(zoom_val, zoom_val)


func change_zoom(_value: int) -> void:
	zoom_val = clamp(zoom_val + zoom_step * _value, zoom_min, zoom_max)
	zoom = Vector2(zoom_val, zoom_val)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("zoom_in"):
		change_zoom(1)
	elif Input.is_action_just_pressed("zoom_out"):
		change_zoom(-1)

	# --
	var x : float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y : float  = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	var movement : Vector2 = Vector2(x, y).normalized()

	position += movement * move_speed * _delta


func _unhandled_input(_event: InputEvent) -> void:
	if _event is InputEventPanGesture:
		position += _event.delta * move_speed * 0.01


#region GAME PERSISTENCE
func on_save_data() -> Dictionary:
	return {
		"position": position,
		"zoom_val": zoom_val,
	}


func on_load_data(_data: Dictionary) -> void:
	position = _data["position"]
	zoom_val = _data["zoom_val"]
	zoom = Vector2(zoom_val, zoom_val)

#endregion
