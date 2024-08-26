extends MakeBuilding
class_name MillBuilding


func _ready() -> void:
	super._ready()
	
	title = "Mill"
	
	building_type      = Term.BuildingType.MILL
	building_size      = Term.BuildingSize.SMALL

	# -- Make properties..
	make_resource_type = Term.ResourceType.WOOD
	make_industry_type = Term.IndustryType.MILL
	
