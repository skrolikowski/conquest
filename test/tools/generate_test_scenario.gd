extends Node

var game_controller : GameController
var game_session    : GameSession
var world_manager   : WorldManager
var player          : Player

const SCENARIO_PREFIX : String = "test_scenario_"
const SCENARIOS : Dictionary = {
	"01": "Player starts with settler and ship near shore.",
	"02": "Player starts with colony off shore.",
	# ...
	# ...
	# ...
}


func _ready() -> void:
	await generate_scenario("02")


func generate_scenario(_scenario_id: String) -> void:
	# Clean up any existing test save
	Persistence.delete_save_file(SCENARIO_PREFIX + _scenario_id)
	
	# Create game controller
	game_controller = GameController.new()
	game_controller.test_mode = true  # => blocks natural game flow for testing
	add_child(game_controller)

	# Setup game systems
	game_controller._setup_game()
	await get_tree().process_frame

	# Get references
	game_session = game_controller.game_session
	world_manager = game_controller.world_manager
	player = game_session.turn_orchestrator.player

	# Generate the test map
	await game_session.start_new_game(SCENARIO_PREFIX + _scenario_id)

	# Create scenario
	var pos : Vector2 = call("_" + SCENARIO_PREFIX + _scenario_id)

	# Center camera on scenario location
	world_manager.world_camera.position =  pos

	# Save the scenario
	var success: bool = game_session.save_game()
	if success:
		print("\n✅ SUCCESS! Test scenario saved!")
		print("   Location: user://conquest_save_test.ini")
	else:
		print("\n❌ FAILED to save test scenario")
		print("   Check console for errors")

	print("\n========================================\n")

	# Exit after a short delay
	#await get_tree().create_timer(0.25).timeout
	#get_tree().quit()


func _test_scenario_01() -> Vector2:
	"""
	Player starts with settler and ship near shore.
	"""
	var settler       : UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, 1)
	var settler_pos   : Vector2 = Def.get_world_tile_map().map_to_local(Vector2i(51, 32))
	var settler_unit  : Unit = player.create_unit(settler, settler_pos)
	
	var ship       : UnitStats = UnitStats.New_Unit(Term.UnitType.SHIP, 1)
	var shore_tile : Vector2i = Def.get_world_map().get_random_starting_tile()
	var ship_pos   : Vector2 = Def.get_world_tile_map().map_to_local(shore_tile)
	# var ship_pos   : Vector2 = Def.get_world_tile_map().map_to_local(Vector2i(53, 32))
	var ship_unit  : Unit = player.create_unit(ship, ship_pos)

	ship_unit.stat.attached_units.append(settler_unit.stat)

	return ship_unit.position


func _test_scenario_02() -> Vector2:
	"""
	Player starts with colony off shore at an optimal location.
	"""
	# Find optimal colony location
	var world_gen: WorldGen = Def.get_world_map()
	var optimal_tile: Vector2i = world_gen.get_optimal_colony_location()
	var colony_pos: Vector2 = Def.get_world_tile_map().map_to_local(optimal_tile)

	var center : CenterBuilding = player.cm.get_colonies()[0] as CenterBuilding
	center.create_building(Term.BuildingType.DOCK)
	center.bm._update_temp_building(colony_pos)
	center.bm._place_temp_building()

	# Create settler unit (will immediately found colony)
	# var settler: UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, 1)
	# settler.resources[Term.ResourceType.WOOD] = 100
	# settler.resources[Term.ResourceType.CROPS] = 50
	# settler.resources[Term.ResourceType.GOLD] = 20

	# var settler_unit: Unit = player.create_unit(settler, colony_pos)

	# Found the colony immediately
	# if settler_unit is SettlerUnit:
	# 	settler_unit.settle()

	# Print colony location info for debugging
	var tile_data: TileCustomData = world_gen.get_tile_custom_data(optimal_tile)
	if tile_data:
		print("Colony founded at tile %s" % optimal_tile)
		print("  Biome: %s" % tile_data.biome)
		print("  Is Shore: %s" % tile_data.is_shore)
		print("  Is River: %s" % tile_data.is_river)
		print("  Farm Modifier: %d" % tile_data.terrain_modifiers[Term.IndustryType.FARM])
		print("  Mine Modifier: %d" % tile_data.terrain_modifiers[Term.IndustryType.MINE])
		print("  Mill Modifier: %d" % tile_data.terrain_modifiers[Term.IndustryType.MILL])

	return colony_pos
