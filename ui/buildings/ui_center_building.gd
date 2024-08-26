extends PanelContainer
class_name UICenterBuilding

var building       : CenterBuilding : set = _set_building
var building_state : Term.BuildingState


func _ready() -> void:
	%ExitMenu.connect("pressed", _on_exit_menu_pressed)
	%BuildBuilding.connect("pressed", _on_build_building_pressed)
	%PopulationDetails.connect("pressed", _on_population_details_pressed)
	%CommodityDetails.connect("pressed", _on_commodity_details_pressed)
	%BuildingList.connect("pressed", _on_building_list_pressed)
	%UndoFoundColony.connect("pressed", _on_undo_found_colony_pressed)
	%ColonyContents.connect("pressed", _on_colony_contents_pressed)
	
	%ColonyUpgrade.connect("toggled", _on_building_upgrade_toggled)
	%LeaderCheckBox.connect("toggled", _on_leader_commission_toggled)


func _set_building(_building: CenterBuilding) -> void:
	building = _building
	building_state = building.building_state
	
	%ColonyTitle.text        = building.title
	%ColonyLevel.text        = "Level: " + str(building.level)
	
	%ColonyUpgrade.disabled  = not building.can_upgrade()
	%LeaderCheckBox.disabled = not building.can_commission_leader()
	
	# -- Undo Found Colony..
	if _building.building_state == Term.BuildingState.NEW:
		%UndoFoundColony.show()
	else:
		%UndoFoundColony.hide()
	
	# -- Colony Resource/Supplies
	var gold_supply       : int = building.bank.get_resource_value(Term.ResourceType.GOLD)
	var next_gold_supply  : int = building.bank.get_next_resource_value(Term.ResourceType.GOLD)
	var metal_supply      : int = building.bank.get_resource_value(Term.ResourceType.METAL)
	var next_metal_supply : int = building.bank.get_next_resource_value(Term.ResourceType.METAL)
	var wood_supply       : int = building.bank.get_resource_value(Term.ResourceType.WOOD)
	var next_wood_supply  : int = building.bank.get_next_resource_value(Term.ResourceType.WOOD)
	var goods_supply      : int = building.bank.get_resource_value(Term.ResourceType.GOODS)
	var next_goods_supply : int = building.bank.get_next_resource_value(Term.ResourceType.GOODS)
	var crops_supply      : int = building.bank.get_resource_value(Term.ResourceType.CROPS)
	var next_crops_supply : int = building.bank.get_next_resource_value(Term.ResourceType.CROPS)
	
	%GoldSupplyValue.text  = str(gold_supply)
	%MetalSupplyValue.text = str(metal_supply)
	%WoodSupplyValue.text  = str(wood_supply)
	%GoodSupplyValue.text  = str(goods_supply)
	%FoodSupplyValue.text  = str(crops_supply)

	if next_gold_supply >= 0:
		%GoldNextValue.text    = "(+" + str(next_gold_supply) + ")"
	else:
		%GoldNextValue.text    = "(" + str(next_gold_supply) + ")"

	if next_metal_supply >= 0:
		%MetalNextValue.text   = "(+" + str(next_metal_supply) + ")"
	else:
		%MetalNextValue.text   = "(-" + str(next_metal_supply) + ")"

	if next_wood_supply >= 0:
		%WoodNextValue.text    = "(+" + str(next_wood_supply) + ")"
	else:
		%WoodNextValue.text    = "(-" + str(next_wood_supply) + ")"

	if next_goods_supply >= 0:
		%GoodNextValue.text    = "(+" + str(next_goods_supply) + ")"
	else:
		%GoodNextValue.text    = "(-" + str(next_goods_supply) + ")"

	if next_crops_supply >= 0:
		%FoodNextValue.text    = "(+" + str(next_crops_supply) + ")"
	else:
		%FoodNextValue.text    = "(" + str(next_crops_supply) + ")"
	

func _on_building_upgrade_toggled(toggled_on:bool) -> void:
	if toggled_on:
		building.state = Term.BuildingState.UPGRADE
	else:
		building.state = building_state


func _on_build_building_pressed() -> void:
	Def.get_world_canvas().open_colony_build_building_menu(building)


func _on_population_details_pressed() -> void:
	Def.get_world_canvas().open_colony_population_detail(building)


func _on_commodity_details_pressed() -> void:
	Def.get_world_canvas().open_colony_commodity_detail(building)


func _on_leader_commission_toggled(toggled_on:bool) -> void:
	if toggled_on:
		building.commission_leader = true
	else:
		building.commission_leader = false


func _on_building_list_pressed() -> void:
	Def.get_world_canvas().open_colony_building_list(building)


func _on_undo_found_colony_pressed() -> void:
	Def.get_world().player.undo_found_colony(building)
	Def.get_world().unselect_all()
	
	queue_free()


func _on_colony_contents_pressed() -> void:
	Def.get_world_canvas().open_building_unit_list(building)


func _on_exit_menu_pressed() -> void:
	Def.get_world_canvas().close_ui(self)
