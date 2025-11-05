class_name TypeRegistry
extends RefCounted

## Bidirectional type conversion utilities for game enums.
## Uses static dictionaries for O(1) lookup performance.
##
## Example usage:
##   var building_type = TypeRegistry.building_type_from_code("farm")
##   var display_name = TypeRegistry.building_type_to_name(building_type)

#region BUILDING TYPES

static var _building_code_to_type: Dictionary = {
	"center": Term.BuildingType.CENTER,
	"housing": Term.BuildingType.HOUSING,
	"mill": Term.BuildingType.MILL,
	"farm": Term.BuildingType.FARM,
	"church": Term.BuildingType.CHURCH,
	"docks": Term.BuildingType.DOCK,
	"metal_mine": Term.BuildingType.METAL_MINE,
	"gold_mine": Term.BuildingType.GOLD_MINE,
	"commerce": Term.BuildingType.COMMERCE,
	"fort": Term.BuildingType.FORT,
	"war_college": Term.BuildingType.WAR_COLLEGE,
	"tavern": Term.BuildingType.TAVERN,
}

static var _building_type_to_name: Dictionary = {
	Term.BuildingType.CENTER: "Colony Center",
	Term.BuildingType.HOUSING: "Housing",
	Term.BuildingType.MILL: "Mill",
	Term.BuildingType.FARM: "Farm",
	Term.BuildingType.CHURCH: "Church",
	Term.BuildingType.DOCK: "Dock",
	Term.BuildingType.METAL_MINE: "Metal Mine",
	Term.BuildingType.GOLD_MINE: "Gold Mine",
	Term.BuildingType.COMMERCE: "Commerce",
	Term.BuildingType.FORT: "Fort",
	Term.BuildingType.WAR_COLLEGE: "War College",
	Term.BuildingType.TAVERN: "Tavern",
}

static func building_type_from_code(code: String) -> Term.BuildingType:
	"""Convert JSON string code to BuildingType enum.
	Returns BuildingType.NONE if code not found."""
	return _building_code_to_type.get(code, Term.BuildingType.NONE)

static func building_type_to_name(type: Term.BuildingType) -> String:
	"""Convert BuildingType enum to display name.
	Returns 'Unknown Building' if type not found."""
	return _building_type_to_name.get(type, "Unknown Building")

#endregion

#region UNIT TYPES

static var _unit_code_to_type: Dictionary = {
	"settler": Term.UnitType.SETTLER,
	"ship": Term.UnitType.SHIP,
	"infantry": Term.UnitType.INFANTRY,
	"cavalry": Term.UnitType.CALVARY,  # Note: JSON uses correct spelling, enum has typo
	"artillery": Term.UnitType.ARTILLARY,  # JSON uses correct spelling, enum has typo
	"explorer": Term.UnitType.EXPLORER,
	"leader": Term.UnitType.LEADER,
}

static var _unit_type_to_name: Dictionary = {
	Term.UnitType.SETTLER: "Settler",
	Term.UnitType.SHIP: "Ship",
	Term.UnitType.INFANTRY: "Infantry",
	Term.UnitType.CALVARY: "Cavalry",  # Display correct spelling
	Term.UnitType.ARTILLARY: "Artillery",  # Display correct spelling
	Term.UnitType.EXPLORER: "Explorer",
	Term.UnitType.LEADER: "Leader",
}

static func unit_type_from_code(code: String) -> Term.UnitType:
	"""Convert JSON string code to UnitType enum.
	Returns UnitType.NONE if code not found."""
	return _unit_code_to_type.get(code, Term.UnitType.NONE)

static func unit_type_to_name(type: Term.UnitType) -> String:
	"""Convert UnitType enum to display name.
	Returns 'Unknown Unit' if type not found."""
	return _unit_type_to_name.get(type, "Unknown Unit")

#endregion

#region RESOURCE TYPES

static var _resource_code_to_type: Dictionary = {
	"wood": Term.ResourceType.WOOD,
	"metal": Term.ResourceType.METAL,
	"crops": Term.ResourceType.CROPS,
	"gold": Term.ResourceType.GOLD,
	"goods": Term.ResourceType.GOODS,
}

static var _resource_type_to_name: Dictionary = {
	Term.ResourceType.WOOD: "Wood",
	Term.ResourceType.METAL: "Metal",
	Term.ResourceType.CROPS: "Crops",
	Term.ResourceType.GOLD: "Gold",
	Term.ResourceType.GOODS: "Goods",
}

static func resource_type_from_code(code: String) -> Term.ResourceType:
	"""Convert JSON string code to ResourceType enum.
	Returns ResourceType.NONE if code not found."""
	return _resource_code_to_type.get(code, Term.ResourceType.NONE)

static func resource_type_to_name(type: Term.ResourceType) -> String:
	"""Convert ResourceType enum to display name.
	Returns 'Unknown Resource' if type not found."""
	return _resource_type_to_name.get(type, "Unknown Resource")

#endregion
