extends Node

var game_controller : GameController
var game_session    : GameSession
var world_manager   : WorldManager
var world_gen       : WorldGen
var player          : Player

const SCENARIO_PREFIX : String = "test_scenario_"
const SCENARIOS : Dictionary = {
	"00": "Empty baseline - no units or colonies",
	"01": "Fresh start - settler and ship near shore",
	"02": "Established colony - Level 1 with 8 essential buildings (dock, farms, housing, mills, mine)",
	"03": "Developed colony - level 2 colony with multiple buildings",
	"04": "Multi-colony - 3 colonies at different development stages",
	"05": "Military scenario - colony with fort and military units",
	"06": "Trade scenario - multiple colonies with trade routes",
}


func _ready() -> void:
	# Print menu
	print("\n" + "=".repeat(60))
	print("  TEST SCENARIO GENERATOR")
	print("=".repeat(60))
	print("\nAvailable Scenarios:")
	for id: String in SCENARIOS.keys():
		print("  %s - %s" % [id, SCENARIOS[id]])
	print("\n" + "=".repeat(60))

	# Get scenario from command line args or use default
	var args: PackedStringArray = OS.get_cmdline_args()
	var scenario_id: String = "02"  # Default to fresh start

	for arg: String in args:
		if arg.begins_with("--scenario="):
			scenario_id = arg.substr(11)
			break

	if not SCENARIOS.has(scenario_id):
		print("\n❌ ERROR: Invalid scenario '%s'" % scenario_id)
		print("   Valid scenarios: %s" % ", ".join(SCENARIOS.keys()))
		get_tree().quit()
		return

	print("\n🎮 Generating scenario: %s - %s\n" % [scenario_id, SCENARIOS[scenario_id]])
	await generate_scenario(scenario_id)


func generate_scenario(_scenario_id: String) -> void:
	# Clean up any existing test save
	Persistence.delete_save_file(SCENARIO_PREFIX + _scenario_id)
	
	# Create game controller
	game_controller = GameController.new()
	add_child(game_controller)

	# Setup game systems
	game_controller._setup_game()
	await get_tree().process_frame

	# Get references
	game_session = game_controller.game_session
	world_manager = game_controller.world_manager
	world_gen = world_manager.world_gen
	player = game_session.turn_orchestrator.player

	# Generate the test map
	await game_session.start_new_game(SCENARIO_PREFIX + _scenario_id)

	# Create scenario
	var pos : Vector2 = await call("_" + SCENARIO_PREFIX + _scenario_id)

	# Center camera on scenario location
	world_manager.world_camera.position =  pos

	# Save the scenario
	var success: bool = game_session.save_game()
	if success:
		print("\n✅ SUCCESS! Test scenario saved!")
		print("   Location: user://conquest_save_" + SCENARIO_PREFIX + _scenario_id + ".ini")
	else:
		print("\n❌ FAILED to save test scenario")
		print("   Check console for errors")

	print("\n========================================\n")

	# Exit after a short delay
	await get_tree().create_timer(0.25).timeout
	get_tree().quit()


func _test_scenario_00() -> Vector2:
	"""
	Empty scenario for baseline testing.
	"""
	return Vector2.ZERO


func _test_scenario_01() -> Vector2:
	"""
	Player starts with settler and ship near shore.
	"""
	var settler      : UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, 1)
	var settler_unit : Unit = player.create_unit(settler, Vector2.ZERO)
	
	var ship       : UnitStats = UnitStats.New_Unit(Term.UnitType.SHIP, 1)
	var shore_tile : Vector2i = Def.get_world_map().get_random_starting_tile()
	var ship_pos   : Vector2 = Def.get_world_tile_map().map_to_local(shore_tile)
	var ship_unit  : Unit = player.create_unit(ship, ship_pos)

	ship_unit.stat.attached_units.append(settler_unit.stat)

	return ship_unit.position


func _test_scenario_02() -> Vector2:
	"""
	Established colony - Level 1 colony with essential buildings.
	Buildings: 1 Dock, 2 Farms, 2 Housing, 2 Mills, 1 Metal Mine
	Uses realistic starting resources from units.json and deducts building costs.
	"""
	# Find optimal colony location (near shore)
	var optimal_tile: Vector2i = world_gen.get_optimal_colony_location()
	# var colony_pos: Vector2 = Def.get_world_tile_map().map_to_local(optimal_tile)

	var colony: CenterBuilding = await _create_colony_at(optimal_tile, 1)
	if colony:
		# Build essential buildings (all Level 1)
		# Building costs (from buildings.json Level 1):
		# - 1 Dock: wood 2
		# - 2 Farms: wood 4 each = 8 total
		# - 2 Housing: wood 2 each = 4 total
		# - 2 Mills: wood 3 each = 6 total
		# - 1 Metal Mine: wood 4
		# Total: 24 wood (starting 40 - 24 = 16 remaining)

		# await _create_and_place_building(colony, Term.BuildingType.DOCK)
		# await _create_and_place_building(colony, Term.BuildingType.DOCK, Vector2i(1, 0))
		# await _create_and_place_building(colony, Term.BuildingType.FARM, Vector2i(2, 0))
		# await _create_and_place_building(colony, Term.BuildingType.FARM, Vector2i(3, 0))
		# await _create_and_place_building(colony, Term.BuildingType.HOUSING, Vector2i(0, 2))
		# await _create_and_place_building(colony, Term.BuildingType.HOUSING, Vector2i(1, 2))
		# await _create_and_place_building(colony, Term.BuildingType.MILL, Vector2i(-1, 0))
		# await _create_and_place_building(colony, Term.BuildingType.MILL, Vector2i(-1, 1))
		# await _create_and_place_building(colony, Term.BuildingType.METAL_MINE, Vector2i(0, -2))

		# Deduct building costs from bank
		# Total cost: 24 wood
		# var total_cost: Transaction = Transaction.new()
		# total_cost.set_resource(Term.ResourceType.WOOD, 24)
		# colony.bank.remove_resources(total_cost)

		# Refresh the colony's build tiles
		# colony.placement_controller._refresh_build_tiles()

		# Print colony info
		print("\n🏘️ Established Colony Created:")
		print("  Buildings: %d" % colony.bm.get_buildings().size())
		print("  Population: %d / %d" % [colony.population, colony.get_max_population()])
		print("  Resources:")
		print("    Gold: %d" % colony.bank.get_resource_value(Term.ResourceType.GOLD))
		print("    Wood: %d (started 40, spent 24)" % colony.bank.get_resource_value(Term.ResourceType.WOOD))
		print("    Crops: %d" % colony.bank.get_resource_value(Term.ResourceType.CROPS))
		print("    Metal: %d" % colony.bank.get_resource_value(Term.ResourceType.METAL))

	# Print tile info
	var tile_data: TileCustomData = world_gen.get_tile_custom_data(optimal_tile)
	if tile_data:
		print("\n📍 Location Info:")
		print("  Tile: %s" % optimal_tile)
		print("  Biome: %s" % tile_data.biome)
		print("  Shore: %s | River: %s" % [tile_data.is_shore, tile_data.is_river])
		print("  Modifiers - Farm: %d%%, Mine: %d%%, Mill: %d%%" % [
			tile_data.terrain_modifiers[Term.IndustryType.FARM],
			tile_data.terrain_modifiers[Term.IndustryType.MINE],
			tile_data.terrain_modifiers[Term.IndustryType.MILL]
		])

	return colony.position


func _test_scenario_03() -> Vector2:
	"""
	Developed colony - level 2 colony with multiple buildings.
	"""
	# Create initial settler
	var world_gen: WorldGen = Def.get_world_map()
	var optimal_tile: Vector2i = world_gen.get_optimal_colony_location()
	var colony_pos: Vector2 = Def.get_world_tile_map().map_to_local(optimal_tile)

	var settler: UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, 1)
	settler.resources[Term.ResourceType.WOOD] = 300
	settler.resources[Term.ResourceType.CROPS] = 200
	settler.resources[Term.ResourceType.GOLD] = 100
	settler.resources[Term.ResourceType.METAL] = 50

	var settler_unit: Unit = player.create_unit(settler, colony_pos)

	# Found colony
	if settler_unit is SettlerUnit:
		var settler_casted: SettlerUnit = settler_unit as SettlerUnit
		settler_casted.settle()
		await get_tree().process_frame

	# Get the colony and develop it
	var colony: CenterBuilding = player.cm.get_colonies()[0] as CenterBuilding
	if colony:
		# Upgrade colony to level 2
		colony.level = 2
		colony.building_state = Term.BuildingState.ACTIVE
		colony.population = 500

		# Add substantial resources
		colony.bank.add_resources(Transaction.new().set_resource(Term.ResourceType.WOOD, 200))
		colony.bank.add_resources(Transaction.new().set_resource(Term.ResourceType.CROPS, 300))
		colony.bank.add_resources(Transaction.new().set_resource(Term.ResourceType.GOLD, 150))
		colony.bank.add_resources(Transaction.new().set_resource(Term.ResourceType.METAL, 80))

		# Build various buildings
		# await _create_and_place_building(colony, Term.BuildingType.FARM, Vector2i(2, 0))
		# await _create_and_place_building(colony, Term.BuildingType.FARM, Vector2i(3, 0))
		# await _create_and_place_building(colony, Term.BuildingType.MILL, Vector2i(0, 2))
		# await _create_and_place_building(colony, Term.BuildingType.HOUSING, Vector2i(1, 2))
		# await _create_and_place_building(colony, Term.BuildingType.CHURCH, Vector2i(-1, 0))

		# Refresh
		colony.placement_controller._refresh_build_tiles()

		print("\n🏛️ Developed Colony Created:")
		print("  Level: 2")
		print("  Population: %d" % colony.population)
		print("  Buildings: %d" % colony.bm.get_buildings().size())

	return colony_pos


func _test_scenario_04() -> Vector2:
	"""
	Multi-colony - 3 colonies at different development stages.
	Uses settler levels to determine starting resources.
	"""
	var world_gen: WorldGen = Def.get_world_map()
	var camera_focus: Vector2 = Vector2.ZERO

	# Colony 1: Established (Level 1 settler: 150 people, 40 wood, 100 gold, 10 crops)
	var tile1: Vector2i = world_gen.get_optimal_colony_location()
	var colony1: CenterBuilding = await _create_colony_at(tile1, 1, 300)
	if colony1:
		# await _create_and_place_building(colony1, Term.BuildingType.FARM, Vector2i(2, 0))
		# await _create_and_place_building(colony1, Term.BuildingType.DOCK, Vector2i(1, 0))
		camera_focus = colony1.position

	# Find a different location for colony 2 (search in a different direction)
	# Start from tile1 and search outward for valid land tiles
	var tile2: Vector2i = _find_next_colony_location(tile1, 25)

	# Colony 2: Developed (Level 2 settler: 300 people, 60 wood, 200 gold, 20 crops, 20 metal)
	var colony2: CenterBuilding = await _create_colony_at(tile2, 2, 600)
	# if colony2:
	# 	await _create_and_place_building(colony2, Term.BuildingType.FARM, Vector2i(2, 0))
	# 	await _create_and_place_building(colony2, Term.BuildingType.MILL, Vector2i(0, 2))
	# 	await _create_and_place_building(colony2, Term.BuildingType.HOUSING, Vector2i(1, 2))
	# 	await _create_and_place_building(colony2, Term.BuildingType.FORT, Vector2i(-2, 0))

	# Find location for colony 3
	var tile3: Vector2i = _find_next_colony_location(tile1, 25)

	# Colony 3: New settlement (Level 1 settler: 150 people, 40 wood, 100 gold, 10 crops)
	var _colony3: CenterBuilding = await _create_colony_at(tile3, 1)

	print("\n🌍 Multi-Colony Scenario:")
	print("  Total Colonies: %d" % player.cm.get_colonies().size())
	print("  Colony 1: Level 1 (300 pop) - Farm + Dock")
	print("  Colony 2: Level 2 (600 pop) - Farm + Mill + Housing + Fort")
	print("  Colony 3: Level 1 (150 pop) - New settlement")

	return camera_focus


func _test_scenario_05() -> Vector2:
	"""
	Military scenario - colony with fort and military units.
	"""
	var world_gen: WorldGen = Def.get_world_map()
	var optimal_tile: Vector2i = world_gen.get_optimal_colony_location()
	var colony_pos: Vector2 = Def.get_world_tile_map().map_to_local(optimal_tile)

	# Create colony
	var colony: CenterBuilding = await _create_colony_at(optimal_tile, 2, 800)
	if colony:
		# Build military infrastructure
		# await _create_and_place_building(colony, Term.BuildingType.FORT, Vector2i(3, 0))
		# await _create_and_place_building(colony, Term.BuildingType.WAR_COLLEGE, Vector2i(0, 3))
		# await _create_and_place_building(colony, Term.BuildingType.FARM, Vector2i(2, 0))
		# await _create_and_place_building(colony, Term.BuildingType.FARM, Vector2i(2, 1))

		# Add military units to colony
		var leader: UnitStats = UnitStats.New_Unit(Term.UnitType.LEADER, 1)
		leader.max_attached_units = 10
		colony.attached_units.append(leader)

		var infantry1: UnitStats = UnitStats.New_Unit(Term.UnitType.INFANTRY, 1)
		colony.attached_units.append(infantry1)

		var infantry2: UnitStats = UnitStats.New_Unit(Term.UnitType.INFANTRY, 2)
		colony.attached_units.append(infantry2)

		var cavalry: UnitStats = UnitStats.New_Unit(Term.UnitType.CALVARY, 1)
		colony.attached_units.append(cavalry)

		# Add resources for training more units
		colony.bank.add_resources(Transaction.new().set_resource(Term.ResourceType.GOLD, 300))
		colony.bank.add_resources(Transaction.new().set_resource(Term.ResourceType.METAL, 200))

		print("\n⚔️ Military Colony Created:")
		print("  Fort: Yes")
		print("  War College: Yes")
		print("  Units in Colony: %d" % colony.attached_units.size())

	return colony_pos


func _test_scenario_06() -> Vector2:
	"""
	Trade scenario - multiple colonies with trade routes.
	"""
	var world_gen: WorldGen = Def.get_world_map()
	var camera_focus: Vector2 = Vector2.ZERO

	# Colony 1: Trading hub with commerce
	var tile1: Vector2i = world_gen.get_optimal_colony_location()
	var colony1: CenterBuilding = await _create_colony_at(tile1, 2, 500)
	if colony1:
		# await _create_and_place_building(colony1, Term.BuildingType.COMMERCE, Vector2i(2, 0))
		# await _create_and_place_building(colony1, Term.BuildingType.DOCK, Vector2i(1, 0))
		# await _create_and_place_building(colony1, Term.BuildingType.TAVERN, Vector2i(0, 2))
		camera_focus = colony1.position

	# Colony 2: Production colony
	var tile2: Vector2i = tile1 + Vector2i(25, 5)
	# var colony2: CenterBuilding = await _create_colony_at(tile2, 2, 400)
	# if colony2:
		# await _create_and_place_building(colony2, Term.BuildingType.FARM, Vector2i(2, 0))
		# await _create_and_place_building(colony2, Term.BuildingType.FARM, Vector2i(3, 0))
		# await _create_and_place_building(colony2, Term.BuildingType.MILL, Vector2i(0, 2))
		# await _create_and_place_building(colony2, Term.BuildingType.METAL_MINE, Vector2i(1, 2))

	print("\n💰 Trade Scenario Created:")
	print("  Hub Colony: Commerce + Tavern + Dock")
	print("  Production Colony: Farms + Mill + Mine")

	return camera_focus


#region HELPER FUNCTIONS

## Create a colony at a specific tile using a settler's level for realistic starting resources
## The settler level determines starting resources and population (from units.json)
## Optional population parameter can override the settler's default people count
func _create_colony_at(tile: Vector2i, settler_level: int, population_override: int = -1) -> CenterBuilding:
	var colony_pos: Vector2 = Def.get_world_tile_map().map_to_local(tile)

	# Create settler at specified level (uses resources from units.json)
	# Level 1: 150 people, gold 100, wood 40, crops 10
	# Level 2: 300 people, gold 200, metal 20, wood 60, crops 20
	# Level 3: 450 people, gold 300, metal 40, wood 80, crops 30
	# Level 4: 600 people, gold 400, metal 80, wood 100, crops 40
	var settler_stats : UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, settler_level)
	var settler_unit  : Unit = player.create_unit(settler_stats, colony_pos)

	# Found the colony
	if settler_unit is SettlerUnit:
		var settler_casted: SettlerUnit = settler_unit as SettlerUnit
		settler_casted.settle()
		await get_tree().process_frame

	# Complete the colony creation (transfers resources from settler)
	# The settle() call put us in CONFIRMING state, but we need to call create_colony()
	# to actually transfer resources and complete the founding process
	var cm: ColonyManager = player.cm
	var create_result: ColonyFoundingWorkflow.Result = cm.create_colony()
	if create_result.is_error():
		push_error("Failed to create colony: %s" % create_result.error_message)
		return null

	# Get the newly created colony
	var colony: CenterBuilding = player.get_latest_colony()
	if colony:
		# Set colony to ACTIVE (skip NEW state)
		colony.building_state = Term.BuildingState.ACTIVE

		# Override population if specified (otherwise uses settler's people value)
		if population_override > 0:
			colony.population = population_override

		# Call begin_turn to properly initialize the colony
		# This ensures production systems, labor, and other mechanics are set up
		colony.begin_turn()
		await get_tree().process_frame

	return colony


## Create and place a building at a specific offset from colony
func _create_and_place_building(colony: CenterBuilding, building_type: Term.BuildingType) -> void:
	# Create the building
	var building_scene: PackedScene = PreloadsRef.get_building_scene(building_type)
	var building: Building = building_scene.instantiate() as Building
	building._ready()
	building.colony = colony
	building.player = player

	# Calculate position
	colony.placement_controller._refresh_build_tiles()
	var target_tile: Vector2i = LocationFinder.find_optimal_dock_location(world_gen, colony.placement_controller.build_tiles)
	var target_pos: Vector2 = Def.get_world_tile_map().map_to_local(target_tile)

	# Position the building
	building.global_position = target_pos
	if building.building_size == Term.BuildingSize.LARGE:
		building.global_position = target_pos + building.get_size() * 0.25

	# Add to colony
	colony.bm.add_building(building)
	colony.bm.add_occupied_tiles(building.get_tiles(), building)

	# Set building state to ACTIVE
	building.building_state = Term.BuildingState.ACTIVE

	await get_tree().process_frame


## Find a valid colony location that's not already occupied
## Searches in a spiral pattern from the reference tile to find valid land
func _find_next_colony_location(reference_tile: Vector2i, min_distance: int) -> Vector2i:
	var cm: ColonyManager = player.cm

	# Get all existing colony tiles
	var occupied_tiles: Array[Vector2i] = []
	for colony: CenterBuilding in cm.get_colonies():
		occupied_tiles.append_array(colony.get_tiles())

	# Search in expanding circles from reference tile
	for radius: int in range(min_distance, min_distance + 50):
		# Check tiles at this radius in 8 directions
		var directions: Array[Vector2i] = [
			Vector2i(radius, 0),      # East
			Vector2i(-radius, 0),     # West
			Vector2i(0, radius),      # South
			Vector2i(0, -radius),     # North
			Vector2i(radius, radius), # Southeast
			Vector2i(-radius, radius), # Southwest
			Vector2i(radius, -radius), # Northeast
			Vector2i(-radius, -radius) # Northwest
		]

		for direction: Vector2i in directions:
			var candidate: Vector2i = reference_tile + direction

			# Check if this tile is valid for a colony
			if not cm.can_settle(candidate):
				continue

			# Check if any of the 2x2 tiles for center building are occupied
			var tiles_occupied: bool = false
			for dx: int in [0, 1]:
				for dy: int in [0, 1]:
					var check_tile: Vector2i = candidate + Vector2i(dx, dy)
					if check_tile in occupied_tiles:
						tiles_occupied = true
						break
				if tiles_occupied:
					break

			if not tiles_occupied:
				return candidate

	# Fallback: return reference tile offset (might fail, but at least we tried)
	return reference_tile + Vector2i(min_distance, 0)

#endregion
