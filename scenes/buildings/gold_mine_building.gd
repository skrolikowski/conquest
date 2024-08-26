extends MakeBuilding
class_name GoldMineBuilding


func _ready() -> void:
	super._ready()
	
	title = "Gold Mine"
	
	building_type      = Term.BuildingType.GOLD_MINE
	building_size      = Term.BuildingSize.SMALL

	# -- Make properties..
	make_resource_type = Term.ResourceType.GOLD
	make_industry_type = Term.IndustryType.MINE
	
