extends MakeBuilding
class_name MetalMineBuilding


func _ready() -> void:
	super._ready()
	
	title = "Metal Mine"
	
	building_type      = Term.BuildingType.METAL_MINE
	building_size      = Term.BuildingSize.SMALL

	# -- Make properties..
	make_resource_type = Term.ResourceType.METAL
	make_industry_type = Term.IndustryType.MINE
