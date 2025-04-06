extends UIMakeBuilding
class_name UIMineBuilding


#override..
func refresh_ui() -> void:
	var make_building : MakeBuilding = building as MakeBuilding

	if make_building as MetalMineBuilding:
		%ThisMetalValue.text = str(make_building.get_expected_produce_value())
		%ThisGoldValue.text  = str(0.0)
	else:
		%ThisMetalValue.text = str(0.0)
		%ThisGoldValue.text  = str(make_building.get_expected_produce_value())
		
	%AllMetalValue.text = str(make_building.colony.get_expected_produce_value_by_building_type(Term.BuildingType.METAL_MINE))
	%AllGoldValue.text  = str(make_building.colony.get_expected_produce_value_by_building_type(Term.BuildingType.GOLD_MINE))

	%StockpileMetalValue.text = str(make_building.colony.bank.get_resource_value(Term.ResourceType.METAL))
	%StockpileGoldValue.text  = str(make_building.colony.bank.get_resource_value(Term.ResourceType.GOLD))

	# Modifier
	refresh_modifier()
