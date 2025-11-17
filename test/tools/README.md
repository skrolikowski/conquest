# Test Scenario Generator

Generate playable save files for manual testing and playtesting different game states.

## Quick Start

### Option 1: Using the Shell Script (Recommended)

```bash
# Generate a specific scenario
./test/tools/generate_scenario.sh 03

# Or use default (scenario 01 - fresh start)
./test/tools/generate_scenario.sh
```

### Option 2: Using Godot Directly

```bash
/Applications/Godot.app/Contents/MacOS/Godot \
  --path . \
  --headless \
  test/tools/generate_test_scenario.tscn \
  --scenario=03 \
  --quit-after 5
```

### Option 3: Via Godot Editor

1. Open `test/tools/generate_test_scenario.tscn`
2. Edit the `_ready()` function to set your desired scenario
3. Run the scene (F6)
4. Wait for "SUCCESS!" message
5. Close the scene

## Available Scenarios

| ID | Name | Description |
|----|------|-------------|
| `00` | **Empty Baseline** | Clean slate - no units or colonies. Good for performance testing. |
| `01` | **Fresh Start** | Settler + ship near shore. Classic starting position. |
| `02` | **Established Colony** | Level 1 colony with 8 essential buildings. Uses realistic starting resources. |
| `03` | **Developed Colony** | Level 2 colony with multiple buildings (2 farms, mill, housing, church). Test production chains. |
| `04` | **Multi-Colony** | 3 colonies at different stages. Test colony management and expansion. |
| `05` | **Military Scenario** | Colony with fort, war college, and military units. Test combat and training. |
| `06` | **Trade Scenario** | 2 colonies optimized for trade (commerce hub + production colony). Test trade routes. |

## Scenario Details

### 01 - Fresh Start
- **Units:** 1 Settler, 1 Ship
- **Position:** Near shore at optimal location
- **Use Case:** Test new game flow, colony founding
- **Resources:** Settler on ship with starting resources

### 02 - Established Colony
- **Colony Level:** 1
- **Buildings:** Center, Dock
- **Population:** 200
- **Resources:** Wood (100), Crops (150), Gold (50)
- **Use Case:** Test building placement, early game economy

### 03 - Developed Colony
- **Colony Level:** 2
- **Buildings:** Center, 2x Farm, Mill, Housing, Church
- **Population:** 500
- **Resources:** Wood (200), Crops (300), Gold (150), Metal (80)
- **Use Case:** Test mid-game production, population growth, specialization bonuses

### 04 - Multi-Colony
- **Colonies:** 3 (levels 1, 2, 1)
- **Colony 1:** Established with farm + dock (300 pop)
- **Colony 2:** Developed with farm, mill, housing, fort (600 pop)
- **Colony 3:** New settlement (150 pop)
- **Use Case:** Test colony switching, resource distribution, expansion

### 05 - Military Scenario
- **Colony Level:** 2
- **Buildings:** Fort, War College, 2x Farm
- **Population:** 800
- **Units:** 1 Leader, 2 Infantry (levels 1, 2), 1 Cavalry
- **Resources:** Gold (300), Metal (200) for training
- **Use Case:** Test combat, unit training, military research

### 06 - Trade Scenario
- **Colonies:** 2 (both level 2)
- **Hub Colony:** Commerce, Dock, Tavern (500 pop)
- **Production Colony:** 2x Farm, Mill, Metal Mine (400 pop)
- **Use Case:** Test trade routes, economic specialization

## Save File Locations

Generated scenarios are saved to:
```
macOS: ~/Library/Application Support/Godot/app_userdata/Conquest/
Linux: ~/.local/share/godot/app_userdata/Conquest/
Windows: %APPDATA%/Godot/app_userdata/Conquest/
```

File naming pattern: `conquest_save_test_scenario_XX.ini`

## Loading a Scenario

### In-Game
1. Launch the game
2. Click **"Continue"** on main menu
3. The most recent test scenario will load

### Specific Scenario
The game loads the most recently saved file. To load a specific scenario:
1. Delete or rename other save files
2. Keep only the scenario you want to test
3. Launch game and click "Continue"

## Creating New Scenarios

### Step 1: Add to SCENARIOS Dictionary

```gdscript
const SCENARIOS : Dictionary = {
    "07": "Your new scenario description",
}
```

### Step 2: Create Scenario Function

```gdscript
func _test_scenario_07() -> Vector2:
    """
    Your scenario description.
    """
    # Create colonies, units, buildings
    var colony: CenterBuilding = await _create_colony_at(Vector2i(10, 10), 1, 300)

    # Add buildings
    await _create_and_place_building(colony, Term.BuildingType.FARM, Vector2i(2, 0))

    # Return camera focus position
    return colony.position
```

### Step 3: Test Your Scenario

```bash
./test/tools/generate_scenario.sh 07
```

## Helper Functions

### _create_colony_at(tile, settler_level, population_override = -1)
Creates a colony at the specified tile using a settler of the given level. The settler level determines starting resources and population from units.json. Optionally override the population.

**Settler Levels & Starting Resources:**
- **Level 1:** 150 people, gold 100, wood 40, crops 10
- **Level 2:** 300 people, gold 200, metal 20, wood 60, crops 20
- **Level 3:** 450 people, gold 300, metal 40, wood 80, crops 30
- **Level 4:** 600 people, gold 400, metal 80, wood 100, crops 40

```gdscript
# Create Level 2 colony with default population (300)
var colony: CenterBuilding = await _create_colony_at(Vector2i(15, 15), 2)

# Create Level 2 colony with custom population override (500)
var colony: CenterBuilding = await _create_colony_at(Vector2i(15, 15), 2, 500)
```

**Important:** The colony's `begin_turn()` is called automatically to initialize production systems before buildings are added.

### _create_and_place_building(colony, building_type, tile_offset)
Creates and places a building at an offset from the colony center.

```gdscript
# Place a farm 2 tiles east of colony
await _create_and_place_building(colony, Term.BuildingType.FARM, Vector2i(2, 0))

# Place a dock 1 tile east (adjacent to shore)
await _create_and_place_building(colony, Term.BuildingType.DOCK, Vector2i(1, 0))
```

**Available Building Types:**
- `FARM`, `MILL`, `METAL_MINE`, `GOLD_MINE`
- `HOUSING`, `CHURCH`, `TAVERN`
- `COMMERCE`, `DOCK`
- `FORT`, `WAR_COLLEGE`

## Tips

1. **Camera Focus:** Return position determines where camera centers on scenario load
2. **Tile Offsets:** Use negative values for west/north placement: `Vector2i(-1, 0)`
3. **Resources:** Add via `colony.bank.add_resources(Transaction.new().set_resource(...))`
4. **Units:** Add to colony via `colony.attached_units.append(unit_stats)`
5. **Building Placement:** Ensure tiles are valid (land, not occupied, within build radius)

## Troubleshooting

### Scenario Doesn't Save
- Check console for errors
- Ensure all awaits are used properly
- Verify building placements are valid

### Game Crashes on Load
- Building placed on invalid tile (water for land building)
- Tile occupied by multiple buildings
- Missing required references (colony, player)

### Buildings Don't Appear
- Not calling `await` before `_create_and_place_building`
- Invalid tile offset (out of build radius)
- Tile already occupied

## Examples

### Simple Starting Position
```gdscript
func _test_scenario_example() -> Vector2:
    var settler: UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, 1)
    settler.resources[Term.ResourceType.WOOD] = 100

    var settler_pos: Vector2 = Vector2(100, 100)
    var settler_unit: Unit = player.create_unit(settler, settler_pos)

    return settler_pos
```

### Colony with Multiple Buildings
```gdscript
func _test_scenario_example2() -> Vector2:
    var colony: CenterBuilding = await _create_colony_at(Vector2i(20, 20), 1, 300)

    await _create_and_place_building(colony, Term.BuildingType.FARM, Vector2i(2, 0))
    await _create_and_place_building(colony, Term.BuildingType.FARM, Vector2i(3, 0))
    await _create_and_place_building(colony, Term.BuildingType.MILL, Vector2i(0, 2))

    colony.bank.add_resources(Transaction.new().set_resource(Term.ResourceType.WOOD, 200))

    return colony.position
```

## See Also

- [Integration Test Base](../integration/integration_test_base.gd) - For automated testing
- [CLAUDE.md](../../CLAUDE.md) - Project architecture documentation
- [Building System](../../scenes/buildings/) - Building types and mechanics
