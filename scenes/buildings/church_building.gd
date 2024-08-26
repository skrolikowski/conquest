extends Building
class_name ChurchBuilding


func _ready() -> void:
	super._ready()
	
	title = "Church"
	
	building_type = Term.BuildingType.CHURCH
	building_size = Term.BuildingSize.SMALL


func get_immigration_bonus() -> int:
	return Def.get_building_stat(building_type, level).immigration
