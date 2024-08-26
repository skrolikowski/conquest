extends Building
class_name CenterBuilding

@onready var bank  := $Bank as Bank
@onready var bm    := $BuildingManager as BuildingManager

@export var population : int = 0

var placing_level     : int = 1  # Resource level; for undoing found colony
var commission_leader : bool = false
var military_research : Dictionary = {}  #TODO: Move to Player?
var attached_units    : Array[UnitStats] = []


func _ready() -> void:
	super._ready()

	title = "Center"
	
	building_type  = Term.BuildingType.CENTER
	building_size  = Term.BuildingSize.LARGE
	building_state = Term.BuildingState.NEW

	# -- Init stats..
	var building_stat  : Dictionary = Def.get_building_stat(building_type, level)
	population = building_stat.init_population

	# Init military research..
	init_military_research()

	# -- TEMP: Colony contents for testing..
	#var u1 : UnitStats = UnitStats.New_Unit(Term.UnitType.LEADER, 1)
	#u1.max_attached_units = 10
	#attached_units.append(u1)
	#attached_units.append(UnitStats.New_Unit(Term.UnitType.CALVARY, 1))
	#attached_units.append(UnitStats.New_Unit(Term.UnitType.CALVARY, 2))
	#attached_units.append(UnitStats.New_Unit(Term.UnitType.CALVARY, 3))
	
	# Take first turn..
	#begin_turn()


func set_init_resources(_resources: Dictionary) -> void:
	bank.set_resources(Def._convert_to_transaction(_resources))


func refresh_bank() -> void:
	for i:String in Term.ResourceType:
		var type       : Term.ResourceType = Term.ResourceType[i]
		var consuming  : int = 0
		
		# -- Consumption
		if type == Term.ResourceType.CROPS:
			consuming += get_crops_needed()

		for building:Building in bm.get_buildings():
			if building is MakeBuilding:
				consuming += building.get_consumption_need_value_by_resource_type(type)

		bank.set_consuming_value(type, consuming)

		# -- Trading
		#TODO:

		# -- Predicted Value
		var next_value : int = get_total_value_by_resource_type(type)
		bank.set_next_resource_value(type, next_value)


#region TURN MANAGEMENT
func begin_turn() -> void:

	# BUILDING ACTIONS
	for building:Building in bm.get_buildings():
		if building.building_state == Term.BuildingState.SELL:
			sell_building(building)
		elif building.building_state == Term.BuildingState.NEW:
			build_building(building)
		elif building.building_state == Term.BuildingState.UPGRADE:
			upgrade_building(building)

	# -- Resource Management
	bank.commit()
	refresh_bank()


func end_turn() -> void:
	
	# -- Military Research
	commit_military_research()

	# -- Immigration..
	population += get_immigration()

#endregion


#region POPULATION/LABOR
func get_total_population_capacity_value(_building_type:Term.BuildingType) -> int:
	var value : int = 0
	for building:Building in bm.get_buildings():
		if building.building_type == _building_type:
			value += Def.get_building_stat(building.building_type, level).max_population
	return value


func get_max_population() -> int:
	var value : int = Def.get_building_stat(building_type, level).max_population
	for building:Building in bm.get_buildings():
		if building.building_type == Term.BuildingType.HOUSING:
			value += Def.get_building_stat(building.building_type, level).max_population
		elif building.building_type == Term.BuildingType.FARM:
			value += Def.get_building_stat(building.building_type, level).max_population
	return value


func is_at_max_population() -> bool:
	return get_total_population() >= get_max_population()


func get_next_max_population() -> int:
	#TODO: calculate based on housing being contructed
	return 0


func get_total_population() -> int:
	return population + get_unit_population()


func get_labor_demand() -> int:
	var value : int = 0
	for building:Building in bm.get_buildings():
		if building.building_state == Term.BuildingState.ACTIVE:
			value += building.get_labor_demand()
	return value


func get_next_labor_demand() -> int:
	var value : int = 0
	for building:Building in bm.get_buildings():
		if building.building_state == Term.BuildingState.NEW:
			value += building.get_labor_demand()
	return value


func get_free_labor() -> int:
	return population - get_labor_demand()


func has_free_labor() -> bool:
	return get_free_labor() > 0


func has_labor_shortage() -> bool:
	return get_free_labor() < 0

#endregion


#region IMMIGRATION
func get_immigration() -> int:
	
	# -- Calculate immigration..
	var growth_rate : float = Def.get_base_population_growth_rate()
	var immigration : int = floor(population * growth_rate)

	# --
	if is_at_max_population():
		#emigration
		return ceil(immigration * -0.5)

	# --
	if is_starving():
		#emigration
		return immigration * -1

	# -- Immigration bonus.. (e.g. Church)
	var immigration_bonus : int = 0

	for building: Building in bm.get_buildings():
		if building.building_type == Term.BuildingType.CHURCH:
			immigration_bonus += Def.get_building_stat(building.building_type, building.level).immigration
	
	return immigration + immigration_bonus


func get_crops_needed() -> int:
	return ceil(float(get_total_population()) * Def.get_crops_consumption_rate())


func is_starving() -> bool:
	return bank.get_resource_value(Term.ResourceType.CROPS) < get_crops_needed()

#endregion


#region UNITS
func get_colony_units() -> Array[UnitStats]:
	return attached_units


func get_unit_count() -> int:
	return get_colony_units().size()


func get_unit_population() -> int:
	var value : int = 0
	for unit_stat:UnitStats in get_colony_units():
		value += unit_stat.get_population()
	return value


func get_next_unit_population() -> int:
	#TODO: calculate based on units being trained
	return 0


func get_units_sorted_by_unit_type() -> Array[UnitStats]:
	var units : Array[UnitStats] = get_colony_units()
	units.sort_custom(func(a:Unit, b:Unit) -> bool: return a.unit_type < b.unit_type)
	return units
	
	
func detach_unit(_unit_stat: UnitStats) -> void:
	var unit_scene : PackedScene = Def.get_unit_scene_by_type(_unit_stat.unit_type)
	var unit       : Unit = unit_scene.instantiate() as Unit
	
	unit.stat     = _unit_stat
	unit.position = global_position
	unit.player   = player
	
	player.add_unit(unit)
	
	# -- Remove from collection..
	attached_units.erase(_unit_stat)

	# -- Remove Unit/Leader reference..
	#WARNING: this should work.. untested
	if _unit_stat.leader:
		_unit_stat.leader.attached_units.erase(_unit_stat)
		_unit_stat.leader = null
	
#endregion


#region MILITARY
func init_military_research() -> void:
	military_research = {
		Term.MilitaryResearch.OFFENSIVE: {
			Term.UnitType.INFANTRY: { "level": 0, "exp": 0 },
			Term.UnitType.CALVARY: { "level": 0, "exp": 0 },
			Term.UnitType.ARTILLARY: { "level": 0, "exp": 0 },
		},
		Term.MilitaryResearch.DEFENSIVE: {
			Term.UnitType.INFANTRY: { "level": 0, "exp": 0 },
			Term.UnitType.CALVARY: { "level": 0, "exp": 0 },
			Term.UnitType.ARTILLARY: { "level": 0, "exp": 0 },
		},
		Term.MilitaryResearch.LEADERSHIP: {
			Term.UnitType.LEADER: { "level": 0, "exp": 0 },
		}
	}


func commit_military_research() -> void:
	for building:Building in bm.get_buildings():
		if building.building_type == Term.BuildingType.WAR_COLLEGE:
			building.commit_military_research()


func train_military_research(_research_type:Term.MilitaryResearch, _unit_type:Term.UnitType, _gold: int) -> void:
	var unit_level : int = military_research[_research_type][_unit_type]["level"]
	var prev_exp   : int = military_research[_research_type][_unit_type]["exp"]
	var next_exp   : int = Def.get_research_max_exp_by_level(unit_level)
	
	if prev_exp + _gold >= next_exp:
		_gold = next_exp - prev_exp
		military_research[_research_type][_unit_type]["exp"] = 0
		military_research[_research_type][_unit_type]["level"] += 1

		train_military_research(_research_type, _unit_type, _gold)
	else:
		military_research[_research_type][_unit_type]["exp"] = prev_exp + _gold

func get_colony_military_units() -> Array[Node]:
	return player.get_military_units_by_colony(self)


func get_military_unit_count() -> int:
	return get_colony_military_units().size()


func get_max_military_unit_count() -> int:
	var value : int = 0
	for building:Building in bm.get_buildings():
		if building.building_type == Term.BuildingType.FORT:
			value += building.get_unit_capacity_value()
	return value


func get_player_ships() -> Array[Node]:
	return player.get_ships()


func get_ship_unit_count() -> int:
	return get_player_ships().size()


func get_max_ship_unit_count() -> int:
	var value : int = 0
	for building:Building in bm.get_buildings():
		if building.building_type == Term.BuildingType.DOCK:
			value += building.get_unit_capacity_value()
	return value


func get_military_unit_level_count_by_unit_type(_unit_type: Term.UnitType) -> Dictionary:
	var value : Dictionary = {}
	var units : Array[Unit] = get_colony_military_units() as Array[Unit]
	
	for i in range(4):
		value[i + 1] = 0
		
	for unit in units:
		if unit.unit_category == Term.UnitCategory.MILITARY and unit.unit_type == _unit_type:
			value[unit.level] += 1
				
	return value
#endregion


#region COMMODITY DETAILS
func get_expected_produce_value_by_resource_type(_resource_type:Term.ResourceType) -> int:
	var total : int = 0
	if _resource_type == Term.ResourceType.GOLD:
		for building:Building in bm.get_buildings():
			if building.building_type == Term.BuildingType.GOLD_MINE:
				total += building.get_expected_produce_value()
	elif _resource_type == Term.ResourceType.METAL:
		for building:Building in bm.get_buildings():
			if building.building_type == Term.BuildingType.METAL_MINE:
				total += building.get_expected_produce_value()
	elif _resource_type == Term.ResourceType.WOOD:
		for building:Building in bm.get_buildings():
			if building.building_type == Term.BuildingType.MILL:
				total += building.get_expected_produce_value()
	elif _resource_type == Term.ResourceType.GOODS:
		for building:Building in bm.get_buildings():
			if building.building_type == Term.BuildingType.COMMERCE:
				total += building.get_expected_produce_value()
	elif _resource_type == Term.ResourceType.CROPS:
		for building:Building in bm.get_buildings():
			if building.building_type == Term.BuildingType.FARM:
				total += building.get_expected_produce_value()
	return total


func get_actual_produce_value_by_resource_type(_resource_type:Term.ResourceType) -> int:
	var total : int = 0
	if _resource_type == Term.ResourceType.GOLD:
		for building:Building in bm.get_buildings():
			if building.building_type == Term.BuildingType.GOLD_MINE:
				total += building.get_actual_produce_value()
	elif _resource_type == Term.ResourceType.METAL:
		for building:Building in bm.get_buildings():
			if building.building_type == Term.BuildingType.METAL_MINE:
				total += building.get_actual_produce_value()
	elif _resource_type == Term.ResourceType.WOOD:
		for building:Building in bm.get_buildings():
			if building.building_type == Term.BuildingType.MILL:
				total += building.get_actual_produce_value()
	elif _resource_type == Term.ResourceType.GOODS:
		for building:Building in bm.get_buildings():
			if building.building_type == Term.BuildingType.COMMERCE:
				total += building.get_actual_produce_value()
	elif _resource_type == Term.ResourceType.CROPS:
		for building:Building in bm.get_buildings():
			if building.building_type == Term.BuildingType.FARM:
				total += building.get_actual_produce_value()
	return total


func get_consume_value_by_resource_type(_resource_type:Term.ResourceType) -> int:
	return bank.get_consuming_value(_resource_type)


func get_trade_value_by_resource_type(_resource_type:Term.ResourceType) -> int:
	var total : int = 0
	#TODO: calculate based on _resource_type involved in trade(s) this turn
	return total


func get_total_value_by_resource_type(_resource_type:Term.ResourceType) -> int:
	var actual_produce : int = get_actual_produce_value_by_resource_type(_resource_type)
	var consume : int = get_consume_value_by_resource_type(_resource_type)
	var trade   : int = get_trade_value_by_resource_type(_resource_type)
	return actual_produce - consume + trade

#endregion


#region BUILDINGS
func get_expected_produce_value_by_building_type(_building_type:Term.BuildingType) -> int:
	"""
		Expected Produce Value by Building Type

		Gets total resources produced by all buildings of a specific type.
	"""
	var total : int = 0
	for building:Building in bm.get_buildings():
		if building.building_type == _building_type:
			total += building.get_expected_produce_value()
	return total


func calculate_specialization_bonus() -> Dictionary:
	"""
	Reference:
	https://gamefaqs.gamespot.com/pc/196975-conquest-of-the-new-world/faqs/2038

	Specialisation bonuses are based on `building-level-grid-squares` (ie: farms are worth 4 points per building level),
	in blocks of 20: the first block is worth 1% each, the next block is worth a 0.5% each, the next block of 20 is worth 0.25% each,
	such that you asymptotically approach 40% total possible bonus. Once this bonus is calculated for the largest commodity sector in your colony,
	the bonus value of the SECOND largest commodity is subtracted from the first.
	
	Bonuses are calculated for mills, mines (gold and metal lumped together), and farms.
	Commerce does not gain production bonuses.
	"""
	var commodity_points : Dictionary = {
		Term.IndustryType.FARM: 0,
		Term.IndustryType.MILL: 0,
		Term.IndustryType.MINE: 0
	}

	for building:Building in bm.get_buildings():
		if building is MakeBuilding:
			commodity_points[building.make_industry_type] += building.get_specialization_points()

	var sorted_points : Array = commodity_points.keys()
	sorted_points.sort_custom(
		func(a:int, b:int) -> bool: return commodity_points[a] > commodity_points[b])

	var primary_industry   : Term.IndustryType = sorted_points[0]
	var secondary_industry : Term.IndustryType = sorted_points[1]
	
	var primary_points   : int = commodity_points[primary_industry]
	var secondary_points : int = commodity_points[secondary_industry]
	
	var primary_bonus   : float = calculate_bonus(primary_points)
	var secondary_bonus : float = calculate_bonus(secondary_points)
	var final_bonus     : float = primary_bonus - secondary_bonus
	
	return { "industry" : primary_industry, "value" : final_bonus }
	
	
# Method to calculate bonus based on points
func calculate_bonus(points: int) -> float:
	var bonus :float = 0.0
	
	if points > 60:
		bonus += 20 * 1
		bonus += 20 * 0.5
		bonus += 20 * 0.25
	elif points > 40:
		bonus += 20 * 1
		bonus += 20 * 0.5
		bonus += (points - 40) * 0.25
	elif points > 20:
		bonus += 20 * 1
		bonus += (points - 20) * 0.5
	else:
		bonus += points * 1
		
	return bonus


func create_building(_building_type: Term.BuildingType) -> void:
	"""
	Creates to building to place in World.
	"""
	var building_scene : PackedScene = Def.get_building_scene_by_type(_building_type)
	var building       : Building = building_scene.instantiate() as Building
	
	building.colony = self
	building.player = player
	
	# control passed to BuildingManager..
	bm.add_temp_building(building)


func purchase_building(_building : Building) -> void:
	"""
	Purchases _building in World; owned by this Colony.
	"""
	var buy_value : Transaction = Def.get_building_cost(_building.building_type)
	if bank.can_afford_this_turn(buy_value):
		bank.resource_purchase(buy_value)


func sell_building(_building : Building) -> void:
	"""
	Refunds _building and removes from World.
	"""
	var transaction : Transaction = _building.get_sell_value()
	bank.resource_credit(transaction)

	bm.remove_building(_building)


func build_building(_building : Building) -> void:
	_building.building_state = Term.BuildingState.ACTIVE


func upgrade_building(_building : Building) -> void:
	bank.make_purchase(_building.get_upgrade_value())
	
	_building.level += 1
	_building.building_state = Term.BuildingState.ACTIVE


func get_buildings_sorted_by_building_type() -> Array[Node]:
	return bm.get_buildings_sorted_by_building_type()

#endregion






func can_commission_leader() -> bool:
	return false



# func _on_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
# 	if _event is InputEventMouseButton:
# 		var mouse_event : InputEventMouseButton = _event as InputEventMouseButton
# 		if mouse_event.button_index == 1:
# 			if mouse_event.double_click:
# 				Def.get_world_canvas().open_building_menu(self)
# 			elif mouse_event.pressed:
# 				Def.get_world().select_building(self)
