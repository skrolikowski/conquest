extends PanelContainer
class_name UICenterBuilding

@onready var btn_exit : Button = %ExitMenu as Button
@onready var btn_build : Button = %BuildBuilding as Button
@onready var btn_pop_details : Button = %PopulationDetails as Button
@onready var btn_com_details : Button = %CommodityDetails as Button
@onready var btn_build_list : Button = %BuildingList as Button
@onready var btn_undo_colony : Button = %UndoFoundColony as Button
@onready var btn_colony_contents : Button = %ColonyContents as Button
@onready var btn_upgrade : Button = %ColonyUpgrade as Button
@onready var btn_leader : Button = %LeaderCheckBox as Button


var building       : CenterBuilding : set = _set_building
var building_state : Term.BuildingState


func _ready() -> void:
	btn_exit.connect("pressed", _on_exit_menu_pressed)
	btn_build.connect("pressed", _on_build_building_pressed)
	btn_pop_details.connect("pressed", _on_population_details_pressed)
	btn_com_details.connect("pressed", _on_commodity_details_pressed)
	btn_build_list.connect("pressed", _on_building_list_pressed)
	btn_undo_colony.connect("pressed", _on_undo_found_colony_pressed)
	btn_colony_contents.connect("pressed", _on_colony_contents_pressed)
	
	btn_upgrade.connect("toggled", _on_building_upgrade_toggled)
	
	btn_leader.connect("toggled", _on_leader_commission_toggled)
	btn_leader.connect("mouse_entered", _on_leader_commission_entered)
	btn_leader.connect("mouse_exited", _on_leader_commission_exited)


func _set_building(_building: CenterBuilding) -> void:
	building = _building
	building_state = building.building_state
	
	%ColonyTitle.text        = building.title
	%ColonyLevel.text        = "Level: " + str(building.level)
	
	btn_upgrade.disabled  = not building.can_upgrade()
	btn_leader.disabled = not building.can_commission_leader()
	btn_leader.button_pressed  = building.commission_leader
	
	# -- Undo Found Colony..
	if _building.building_state == Term.BuildingState.NEW:
		btn_undo_colony.show()
	else:
		btn_undo_colony.hide()
	
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
		building.building_state = Term.BuildingState.UPGRADE
	else:
		building.building_state = building_state


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


func _on_leader_commission_entered() -> void:
	Def.get_world_canvas().update_status(Print.buy_unit_type(Term.UnitType.LEADER))


func _on_leader_commission_exited() -> void:
	Def.get_world_canvas().clear_status()


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
