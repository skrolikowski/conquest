extends Node2D
class_name WorldGen

signal map_loaded

#enum Layer
#{
	#WATER,
	#LAND,
	#CURSOR,
	#FOGOFWAR
#}

var is_map_loaded : bool


func _ready() -> void:
	is_map_loaded = false
	#noise_gen.connect("generation_finished", _on_noise_generation_finished)


func _on_noise_generation_finished() -> void:
	print("Noise Generation Finished")

	# --
	is_map_loaded = true
	map_loaded.emit()
