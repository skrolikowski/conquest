extends RefCounted
class_name Diplomacy

var data : Dictionary = {}


#region GAME PERSISTENCE
func new_game() -> void:
    pass


func on_save_data() -> Dictionary:
    return {
        "data": data,
    }


func on_load_data(_data: Dictionary) -> void:
    data = _data["data"]

#endregion