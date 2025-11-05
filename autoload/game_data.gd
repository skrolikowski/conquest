extends Node
class_name GameDataRef

## Game metadata repository - loads and provides access to building/unit definitions.
## All economic data (costs, production, labor demands) comes from JSON files.
##
## Example usage:
##   var cost = GameData.get_building_cost(Term.BuildingType.FARM, 1)
##   var production = GameData.get_building_make(Term.BuildingType.FARM, 2)

var buildings: Dictionary = {}  # BuildingType -> { cost: [], make: [], need: [], labor_demand: [], stat: [] }
var units: Dictionary = {}      # UnitType -> { cost: [], need: [], stat: [] }


func _ready() -> void:
	_load_buildings()
	_load_units()


func _load_buildings() -> void:
	"""Load building definitions from JSON."""
	var json_text: String = FileAccess.get_file_as_string("res://assets/metadata/buildings.json")
	var json_dict: Dictionary = JSON.parse_string(json_text)

	if not json_dict:
		push_error("Failed to parse buildings.json")
		return

	for key: String in json_dict:
		var building_type: Term.BuildingType = TypeRegistry.building_type_from_code(key)
		if building_type == Term.BuildingType.NONE:
			push_warning("Unknown building code in JSON: " + key)
			continue

		var building_data: Dictionary = json_dict[key]
		buildings[building_type] = {
			"cost": [],
			"make": [],
			"need": [],
			"stat": [],
			"labor_demand": [],
		}

		# Parse cost
		if "cost" in building_data:
			for cost_dict: Dictionary in building_data["cost"]:
				buildings[building_type]["cost"].append(_dict_to_transaction(cost_dict))

		# Parse make
		if "make" in building_data:
			for make_dict: Dictionary in building_data["make"]:
				buildings[building_type]["make"].append(_dict_to_transaction(make_dict))

		# Parse need
		if "need" in building_data:
			for need_dict: Dictionary in building_data["need"]:
				buildings[building_type]["need"].append(_dict_to_transaction(need_dict))

		# Parse labor_demand
		if "labor_demand" in building_data:
			for labor: int in building_data["labor_demand"]:
				buildings[building_type]["labor_demand"].append(labor)

		# Parse stat
		if "stat" in building_data:
			for stat_dict: Dictionary in building_data["stat"]:
				buildings[building_type]["stat"].append(stat_dict)


func _load_units() -> void:
	"""Load unit definitions from JSON."""
	var json_text: String = FileAccess.get_file_as_string("res://assets/metadata/units.json")
	var json_dict: Dictionary = JSON.parse_string(json_text)

	if not json_dict:
		push_error("Failed to parse units.json")
		return

	for key: String in json_dict:
		var unit_type: Term.UnitType = TypeRegistry.unit_type_from_code(key)
		if unit_type == Term.UnitType.NONE:
			push_warning("Unknown unit code in JSON: " + key)
			continue

		var unit_data: Dictionary = json_dict[key]
		units[unit_type] = {
			"cost": [],
			"need": [],
			"stat": [],
		}

		# Parse cost
		if "cost" in unit_data:
			for cost_dict: Dictionary in unit_data["cost"]:
				units[unit_type]["cost"].append(_dict_to_transaction(cost_dict))

		# Parse need
		if "need" in unit_data:
			for need_dict: Dictionary in unit_data["need"]:
				units[unit_type]["need"].append(_dict_to_transaction(need_dict))

		# Parse stat
		if "stat" in unit_data:
			for stat_dict: Dictionary in unit_data["stat"]:
				units[unit_type]["stat"].append(stat_dict)


func _dict_to_transaction(resources: Dictionary) -> Transaction:
	"""Convert dictionary of resources to Transaction object."""
	var transaction: Transaction = Transaction.new()
	for resource_key: String in resources:
		var resource_type: Term.ResourceType = TypeRegistry.resource_type_from_code(resource_key)
		if resource_type == Term.ResourceType.NONE:
			push_warning("Unknown resource code in JSON: " + resource_key)
			continue
		var amount: int = resources[resource_key]
		transaction.resources[resource_type] = amount
	return transaction


#region BUILDING QUERIES

func get_building_cost(type: Term.BuildingType, level: int) -> Transaction:
	"""Get building cost for specific level. Returns cloned Transaction."""
	assert(buildings.has(type), "No data for building type: " + str(type))
	assert(level >= 1 and level <= buildings[type]["cost"].size(), "Invalid building level: " + str(level))
	var transaction: Transaction = buildings[type]["cost"][level - 1]
	return transaction.clone()


func get_building_make(type: Term.BuildingType, level: int) -> Transaction:
	"""Get building production for specific level. Returns cloned Transaction."""
	assert(buildings.has(type), "No data for building type: " + str(type))
	assert(level >= 1 and level <= buildings[type]["make"].size(), "Invalid building level: " + str(level))
	var transaction: Transaction = buildings[type]["make"][level - 1]
	return transaction.clone()


func get_building_need(type: Term.BuildingType, level: int) -> Transaction:
	"""Get building consumption for specific level. Returns Transaction with all resource types."""
	var transaction: Transaction = Transaction.new()

	if not buildings.has(type):
		push_warning("No building data for type: " + str(type))
		return transaction

	if not "need" in buildings[type] or buildings[type]["need"].is_empty():
		return transaction

	if level < 1 or level > buildings[type]["need"].size():
		push_warning("Invalid level for building need: " + str(level))
		return transaction

	var need: Transaction = buildings[type]["need"][level - 1]

	# Fill all resource types (matches original Def behavior)
	for i: String in Term.ResourceType:
		var resource_type: Term.ResourceType = Term.ResourceType[i]
		if resource_type in need.resources:
			transaction.resources[resource_type] = need.resources[resource_type]
		else:
			transaction.resources[resource_type] = 0

	return transaction


func get_building_labor_demand(type: Term.BuildingType, level: int) -> int:
	"""Get labor demand for building at specific level."""
	if not buildings.has(type):
		return 0
	if not "labor_demand" in buildings[type] or buildings[type]["labor_demand"].is_empty():
		return 0
	if level < 1 or level > buildings[type]["labor_demand"].size():
		return 0
	return buildings[type]["labor_demand"][level - 1]


func get_building_stat(type: Term.BuildingType, level: int) -> Dictionary:
	"""Get building stats for specific level."""
	if not buildings.has(type):
		return {}
	if not "stat" in buildings[type] or buildings[type]["stat"].is_empty():
		return {}
	if level < 1 or level > buildings[type]["stat"].size():
		return {}
	return buildings[type]["stat"][level - 1]

#endregion


#region UNIT QUERIES

func get_unit_cost(type: Term.UnitType, level: int) -> Transaction:
	"""Get unit cost for specific level. Returns cloned Transaction."""
	assert(units.has(type), "No data for unit type: " + str(type))
	assert(level >= 1 and level <= units[type]["cost"].size(), "Invalid unit level: " + str(level))
	var transaction: Transaction = units[type]["cost"][level - 1]
	return transaction.clone()


func get_unit_stat(type: Term.UnitType, level: int) -> Dictionary:
	"""Get unit stats for specific level."""
	if not units.has(type):
		return {}
	if not "stat" in units[type] or units[type]["stat"].is_empty():
		return {}
	if level < 1 or level > units[type]["stat"].size():
		return {}
	return units[type]["stat"][level - 1]

#endregion
