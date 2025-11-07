# Integration Testing Guide

This guide explains how to write and run integration tests for the Conquest game. Integration tests verify that multiple systems work together correctly, unlike unit tests which test components in isolation.

---

## What are Integration Tests?

**Unit Tests** test individual components:
- ✅ Does `Transaction.add_resources()` work?
- ✅ Does `Building.get_cost()` return the right value?

**Integration Tests** test system interactions:
- ✅ Does a colony with a farm produce the correct amount of crops?
- ✅ Can I save and load a complete game state?
- ✅ Does upgrading a building change production correctly?

---

## Quick Start

### 1. Basic Integration Test

```gdscript
extends IntegrationTestBase

func test_my_scenario() -> void:
    # Setup the game world
    await setup_world()

    # Create a colony
    var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))

    # Create a farm
    var farm: Building = await create_test_building(
        colony,
        Term.BuildingType.FARM,
        Vector2i(11, 10),
        1  # Level 1
    )

    # Process a turn
    await process_colony_turn()

    # Verify production happened
    assert_gt(colony.bank.get_resource_amount(Term.ResourceType.CROPS), 0)
```

### 2. Running Integration Tests

**In Godot Editor:**
1. Open **GUT panel** (bottom panel)
2. Click **Run All** or select `test/integration/` folder
3. View results

**From Command Line:**
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/integration/
```

---

## IntegrationTestBase Class

All integration tests extend `IntegrationTestBase` which provides:

### Setup Methods

#### `setup_world() -> void`
Creates a minimal game world for testing.

```gdscript
func test_something() -> void:
    await setup_world()
    # Now you have: world_manager, player, and a 20x20 map
```

#### `load_scenario(scenario_name: String) -> bool`
Loads a predefined game state from `test/scenarios/`.

```gdscript
func test_endgame_scenario() -> void:
    var success: bool = await load_scenario("endgame_large_empire")
    assert_true(success)
    # Game state is now loaded
```

---

### Entity Creation Methods

#### `create_test_colony(tile_pos: Vector2i, starting_resources: Dictionary = {}) -> CenterBuilding`
Creates a colony at the specified position with optional starting resources.

```gdscript
# Default resources (1000 of each)
var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))

# Custom resources
var colony: CenterBuilding = await create_test_colony(Vector2i(5, 5), {
    "gold": 500,
    "crops": 2000
})
```

#### `create_test_building(colony: CenterBuilding, building_type: Term.BuildingType, tile_pos: Vector2i, level: int = 1) -> Building`
Creates a building in a colony.

```gdscript
var farm: Building = await create_test_building(
    colony,
    Term.BuildingType.FARM,
    Vector2i(11, 10),
    2  # Level 2 farm
)
```

#### `create_test_unit(unit_type: Term.UnitType, tile_pos: Vector2i, level: int = 1) -> Unit`
Creates a unit at the specified position.

```gdscript
var settler: Unit = await create_test_unit(
    Term.UnitType.SETTLER,
    Vector2i(15, 15),
    1
)
```

---

### Simulation Methods

#### `simulate_turns(num_turns: int) -> void`
Simulates N complete game turns (including all NPCs).

```gdscript
# Simulate 10 turns
await simulate_turns(10)

# Check state after simulation
assert_gt(colony.population, initial_population)
```

#### `process_colony_turn() -> void`
Processes production for all player colonies (faster than full turn simulation).

```gdscript
# Just process production, skip other turn logic
await process_colony_turn()

# Check production results
var crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
```

---

### Assertion Helpers

#### `assert_colony_exists(tile_pos: Vector2i, message: String = "") -> CenterBuilding`
Verifies a colony exists at a position and returns it.

```gdscript
var colony: CenterBuilding = assert_colony_exists(Vector2i(10, 10))
```

#### `assert_building_exists(colony: CenterBuilding, building_type: Term.BuildingType, message: String = "") -> Building`
Verifies a building type exists in a colony.

```gdscript
var farm: Building = assert_building_exists(colony, Term.BuildingType.FARM)
```

#### `assert_colony_resources(colony: CenterBuilding, expected: Dictionary, message: String = "") -> void`
Verifies a colony has at least the specified resources.

```gdscript
assert_colony_resources(colony, {
    "gold": 1000,
    "crops": 500
})
```

#### `assert_production(actual: Transaction, expected: Dictionary, message: String = "") -> void`
Verifies a production transaction matches expected values.

```gdscript
var production: Transaction = farm.get_production()
assert_production(production, {"crops": 50})
```

---

## Common Test Patterns

### Pattern 1: Single Building Production Test

```gdscript
func test_farm_produces_crops() -> void:
    # Setup
    await setup_world()
    var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
    var farm: Building = await create_test_building(
        colony,
        Term.BuildingType.FARM,
        Vector2i(11, 10),
        1
    )

    # Record starting state
    var starting_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)

    # Execute
    await process_colony_turn()

    # Verify
    var ending_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
    var production: int = ending_crops - starting_crops

    assert_gt(production, 0, "Farm should produce crops")
```

### Pattern 2: Multi-Turn Accumulation Test

```gdscript
func test_production_over_time() -> void:
    await setup_world()
    var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
    var farm: Building = await create_test_building(
        colony,
        Term.BuildingType.FARM,
        Vector2i(11, 10),
        1
    )

    # Get per-turn production
    var expected: Transaction = autofree(Def.get_building_make(Term.BuildingType.FARM, 1))
    var per_turn: int = expected.get_resource_amount(Term.ResourceType.CROPS)

    var starting_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)

    # Simulate 5 turns
    await simulate_turns(5)

    var ending_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
    var total_production: int = ending_crops - starting_crops

    assert_eq(total_production, per_turn * 5, "5 turns should produce 5x resources")
```

### Pattern 3: Multiple Buildings Test

```gdscript
func test_multiple_buildings_produce() -> void:
    await setup_world()
    var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))

    # Create multiple buildings
    var farm: Building = await create_test_building(colony, Term.BuildingType.FARM, Vector2i(11, 10), 1)
    var mill: Building = await create_test_building(colony, Term.BuildingType.MILL, Vector2i(12, 10), 1)
    var mine: Building = await create_test_building(colony, Term.BuildingType.METAL_MINE, Vector2i(11, 11), 1)

    # Record starting resources
    var start: Dictionary = {
        "crops": colony.bank.get_resource_amount(Term.ResourceType.CROPS),
        "goods": colony.bank.get_resource_amount(Term.ResourceType.GOODS),
        "metal": colony.bank.get_resource_amount(Term.ResourceType.METAL)
    }

    # Process production
    await process_colony_turn()

    # Verify each produced
    assert_gt(colony.bank.get_resource_amount(Term.ResourceType.CROPS), start["crops"])
    assert_gt(colony.bank.get_resource_amount(Term.ResourceType.GOODS), start["goods"])
    assert_gt(colony.bank.get_resource_amount(Term.ResourceType.METAL), start["metal"])
```

### Pattern 4: Scenario-Based Test

```gdscript
func test_endgame_empire() -> void:
    # Load a complex pre-built scenario
    var success: bool = await load_scenario("large_empire")
    assert_true(success, "Scenario should load")

    # Verify scenario state
    assert_gte(player.cm.colonies.size(), 5, "Should have at least 5 colonies")

    # Test scenario-specific logic
    var capital: CenterBuilding = player.cm.colonies[0]
    assert_gt(capital.population, 1000, "Capital should have large population")
```

---

## Creating Test Scenarios

Test scenarios are saved game files in `test/scenarios/` directory.

### Method 1: Play and Save

1. Start the game normally
2. Set up the desired game state (build colonies, units, etc.)
3. Save the game (this creates `conquest_save_01.ini` in user data)
4. Copy the save file to `test/scenarios/my_scenario.ini`
5. Load in tests: `await load_scenario("my_scenario")`

### Method 2: Programmatic Creation

```gdscript
# In a test or helper script:
func create_scenario_file(scenario_name: String) -> void:
    await setup_world()

    # Create desired state
    var colony1: CenterBuilding = await create_test_colony(Vector2i(10, 10))
    var colony2: CenterBuilding = await create_test_colony(Vector2i(20, 20))
    # ... more setup

    # Save to scenario file
    var config: ConfigFile = ConfigFile.new()
    # ... populate config from game state
    config.save("res://test/scenarios/" + scenario_name + ".ini")
```

---

## Best Practices

### DO:
- ✅ Test complete workflows (colony founding → building → production → turns)
- ✅ Use realistic game data (load costs/production from Def)
- ✅ Test edge cases (empty resources, max level buildings)
- ✅ Use `await` for all async operations
- ✅ Use `autofree()` for Transaction objects to prevent memory leaks
- ✅ Name tests descriptively: `test_farm_level_3_produces_correct_crops()`

### DON'T:
- ❌ Test implementation details (test behavior, not internal state)
- ❌ Make tests depend on execution order
- ❌ Hardcode game values that should come from JSON metadata
- ❌ Create enormous test scenarios (keep them focused)
- ❌ Skip cleanup (use `autofree()` and `add_child_autofree()`)

---

## Debugging Integration Tests

### View Detailed Failures

When a test fails, GUT shows:
- Expected vs actual values
- Line number of assertion
- Custom message

### Common Issues

**"Player must be initialized"**
- Forgot to call `await setup_world()`

**"Colony cannot be null"**
- Building creation failed, check that colony exists
- Check map position is valid

**Tests pass individually but fail in suite**
- Check `after_each()` cleanup
- Verify no shared state between tests

**Production values don't match**
- Verify you're using `Def.get_building_make()` for expected values
- Check if bonuses/modifiers are affecting production

### Enable Debug Output

```gdscript
func test_with_debug_output() -> void:
    await setup_world()
    print("Turn number: ", world_manager.turn_number)

    var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
    print("Colony created at: ", colony.global_position)
    print("Colony resources: ", colony.bank.resources)

    # ... rest of test
```

---

## Example Test Files

See these files for complete examples:

- **test/integration/test_colony_production.gd** - Production system tests
- **test/integration/test_game_persistence.gd** - Save/load tests

---

## Memory Management

Integration tests create many Node-based objects. Always use:

```gdscript
# For Nodes added to scene tree
var colony: CenterBuilding = await create_test_colony(...)  # Already managed

# For Transactions and other RefCounted objects
var transaction: Transaction = autofree(Transaction.new())

# For manually instantiated nodes
var my_node: Node = autofree(MyNode.new())
add_child_autofree(my_node)
```

The `IntegrationTestBase` automatically cleans up `world_manager` and related nodes.

---

## Continuous Integration

### Run Integration Tests in CI

```yaml
# .github/workflows/test.yml
name: Integration Tests

on: [push, pull_request]

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: 4.4

      - name: Run Integration Tests
        run: |
          godot --headless -s addons/gut/gut_cmdln.gd \
            -gdir=res://test/integration/ \
            -gjunit_xml_file=test/results/integration_junit.xml

      - name: Publish Results
        uses: EnricoMi/publish-unit-test-result-action@v2
        with:
          files: test/results/integration_junit.xml
```

---

## Next Steps

1. **Write your first integration test**: Start with `test_colony_production.gd` as a template
2. **Create test scenarios**: Save interesting game states for testing
3. **Test edge cases**: Empty resources, maximum levels, invalid positions
4. **Test workflows**: Colony founding → building → upgrading → selling
5. **Test persistence**: Save and load game states

---

**Happy Integration Testing! 🧪**
