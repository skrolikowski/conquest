extends Area2D
class_name Building

@export var title          : String
@export var level          : int = 1
@export var building_state : Term.BuildingState = Term.BuildingState.ACTIVE
@export var colony         : CenterBuilding
@export var player         : Player

var max_level     : int = 4
var building_type : Term.BuildingType
var building_size : Term.BuildingSize


func _ready() -> void:
	building_state = Term.BuildingState.NEW


func get_size() -> Vector2:
	return ($CollisionShape2D as CollisionShape2D).shape.size


func is_water_building() -> bool:
	return building_type == Term.BuildingType.DOCK
	

func get_tile() -> Vector2i:
	var tile_map : TileMap = Def.get_world().world_map.tile_map
	return tile_map.local_to_map(global_position - get_size() * 0.5)


func get_tile_end() -> Vector2i:
	if building_size == Term.BuildingSize.LARGE:
		return get_tile() + Vector2i(1, 1)
	else:
		return get_tile()


# func get_center() -> Vector2:
# 	var offset : Vector2 = Vector2.ZERO
# 	if building_size == Term.BuildingSize.LARGE:
# 		offset = get_size() * 0.5

# 	var tile_map : TileMap = Def.get_world().world_map.tile_map
# 	return tile_map.map_to_local(get_tile()) + offset


func get_stat() -> Dictionary:
	return Def.get_building_stat(building_type, level)


func get_need() -> Transaction:
	return Def.get_building_need(building_type, level)


func get_labor_demand() -> int:
	return Def.get_building_labor_demand(building_type, level)


func get_make() -> Transaction:
	return Def.get_building_make(building_type, level)


func get_upgrade_cost() -> Transaction:
	return Def.get_building_cost(building_type, level + 1)


func get_buy_value() -> Transaction:
	return Def.get_building_cost(building_type, 1)


func get_sell_value() -> Transaction:
	var transaction : Transaction = Def.get_building_cost(building_type, level)

	if building_state == Term.BuildingState.NEW:
		return transaction
		
	# reduce original cost by half..
	for i:Term.ResourceType in transaction.resources:
		transaction.resources[i] = ceil(transaction.resources[i] * 0.5)
		
	return transaction


func can_upgrade() -> bool:
	# -- Allow for unchecking..
	if building_state == Term.BuildingState.UPGRADE:
		return true
	
	# -- Max upgrade level check..
	if level == 4:
		return false
		
	# -- Building occupied check..
	if building_state != Term.BuildingState.ACTIVE:
		return false
	
	# -- Resource availability check..
	var upgrade_cost : Transaction = get_upgrade_cost()
	if not colony.bank.can_afford_this_turn(upgrade_cost):
		return false
	
	return true
	
func can_demolish() -> bool:
	# -- Allow for unchecking..
	if building_state == Term.BuildingState.SELL:
		return true
		
	return building_state == Term.BuildingState.ACTIVE



#region STATUS INFORMATION
func get_status_information(_tile: Vector2i) -> String:
	var text : PackedStringArray = PackedStringArray()

	# -- unit name/level
	var building_name : String = Def._convert_building_type_to_name(building_type)
	building_name = "Lv. " + str(level) + " " + building_name
	text.append(building_name)

	# -- Building cost..
	if building_state == Term.BuildingState.NEW:
		var cost : String = get_status_information_cost(get_buy_value())
		text.append(cost)
	elif building_state == Term.BuildingState.UPGRADE:
		var cost : String = get_status_information_cost(get_upgrade_cost())
		if cost != "":
			text.append(cost)

	# -- Labor demand..
	var labor_demand : int = get_labor_demand()
	if labor_demand > 0:
		var colony_labor_demand : int = colony.get_labor_demand()
		var labor_demand_text   : String = "Labor +" + str(labor_demand) + " of (" + str(colony_labor_demand) + ")"
		text.append(labor_demand_text)

	# # -- Production..
	# var production : String = get_status_information_production(_tile)
	# if production != "":
	# 	text.append(production)

	return (" " + Def.STATUS_SEP + " ").join(text)


func get_status_information_cost(_transaction:Transaction) -> String:
	var cost : Transaction = get_buy_value()
	var text : PackedStringArray = PackedStringArray()
	
	for i: String in Term.ResourceType:
		var resource_type  : Term.ResourceType = Term.ResourceType[i]
		var resource_name  : String = Def._convert_resource_type_to_name(resource_type)
		var resource_value : int = cost.get_resource_amount(resource_type)
		
		if resource_value > 0:
			text.append(str(resource_value) + " " + resource_name)
	
	if text.size() > 0:
		return "Cost: " + ", ".join(text) + "."
	else:
		return ""


func get_status_information_production(_tile:Vector2i) -> String:
	var mod_data : Dictionary = Def.get_world_map().get_terrain_modifier_by_industry_type(_tile)
	var mod_text : PackedStringArray = PackedStringArray()
	mod_text.append("Farm: " + str(mod_data[Term.IndustryType.FARM]) + "%")
	mod_text.append("Mill: " + str(mod_data[Term.IndustryType.MILL]) + "%")
	mod_text.append("Mine: " + str(mod_data[Term.IndustryType.MINE]) + "%")

	return "Industry: " + ", ".join(mod_text)

#endregion
