extends MakeBuilding
class_name FarmBuilding


func _ready() -> void:
	super._ready()
	
	title = "Farm"
	
	building_type      = Term.BuildingType.FARM
	building_size      = Term.BuildingSize.SMALL

	# -- Make properties..
	make_resource_type = Term.ResourceType.CROPS
	make_industry_type = Term.IndustryType.FARM
