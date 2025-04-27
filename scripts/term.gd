extends Node
class_name Term

enum CollisionMask {
	UNIT    = 1 << 0,
	CARRIER = 1 << 1,
}

enum BuildingSize {
	NONE,
	SMALL,
	LARGE
}

enum ResourceType {
	NONE,
	GOLD,
	METAL,
	WOOD,
	GOODS,
	CROPS
}

enum IndustryType {
	NONE,
	FARM,
	MILL,
	MINE
}

enum BuildingType {
	NONE,
	CENTER,
	CHURCH,
	COMMERCE,
	DOCK,
	FARM,
	FORT,
	GOLD_MINE,
	HOUSING,
	METAL_MINE,
	WAR_COLLEGE,
	MILL,
	TAVERN,
}

enum BuildingState {
	NEW,
	SELL,
	UPGRADE,
	ACTIVE,
	TRAIN,
}

enum UnitCategory {
	NONE,
	SHIP,
	MILITARY
}

enum UnitMovement {
	EXPLORER,
	SHIP,
	OTHER,
}

enum UnitType {
	NONE,
	SETTLER,
	EXPLORER,
	INFANTRY,
	CALVARY,
	ARTILLARY,
	LEADER,
	SHIP,
}

enum UnitState {
	IDLE,
	DISBAND,
	ATTACK,      # Leaders & Ships only..
	EXPLORE,     # Explorers only..
}

enum MilitaryResearch {
	OFFENSIVE,
	DEFENSIVE,
	LEADERSHIP
}

enum ResearchStatus {
	NONE,
	SUSPENDED,
	ONE_TIME,
	PER_TURN,
}

enum TerrainType {
	NONE,
	WATER,      # Ships only
	GRASSLAND,  # inc. Crops, dec. Wood
	DESERT,     # dec. Crops, dec. Wood
	FOREST,     # dec. Crops, inc. Wood
	MOUNTAINS,  # inc. Metals and Gold
	SNOW,       # Gold (if mountainous)
	
	# JUNGLE,
	# RIVER,
	# RIVER_DELTA,
	# LAKE,
	# OCEAN,
}
