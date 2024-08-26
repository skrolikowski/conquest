extends UIMakeBuilding
class_name UIMineBuilding

#override..
func _set_building(_building: Building) -> void:
	super._set_building(_building)


	# -- Make Building Data
	_building = _building as MakeBuilding

	if _building as MetalMineBuilding:
		%ThisMetalValue.text = str(_building.get_expected_produce_value())
		%ThisGoldValue.text  = str(0.0)
	else:
		%ThisMetalValue.text = str(0.0)
		%ThisGoldValue.text  = str(_building.get_expected_produce_value())
		
	%AllMetalValue.text = str(_building.colony.get_expected_produce_value_by_building_type(Term.BuildingType.METAL_MINE))
	%AllGoldValue.text  = str(_building.colony.get_expected_produce_value_by_building_type(Term.BuildingType.GOLD_MINE))

	%StockpileMetalValue.text = str(_building.colony.bank.get_resource_value(Term.ResourceType.METAL))
	%StockpileGoldValue.text  = str(_building.colony.bank.get_resource_value(Term.ResourceType.GOLD))


	# Modifier
	refresh_modifier()
