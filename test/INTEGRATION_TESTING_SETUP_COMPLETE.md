# Integration Testing Setup Complete ✅

Integration testing has been successfully set up for the Conquest project!

---

## What Was Added

### 1. Base Framework

**File**: `test/integration_test_base.gd`

A powerful base class that all integration tests extend. Provides:

- **World Setup**: `setup_world()` - Creates a full game world
- **Entity Creation**: `create_test_colony()`, `create_test_building()`, `create_test_unit()`
- **Simulation**: `simulate_turns()`, `process_colony_turn()`
- **Scenario Loading**: `load_scenario()` - Load saved game states
- **Custom Assertions**: `assert_colony_exists()`, `assert_building_exists()`, etc.

### 2. Example Integration Tests

#### **test/integration/test_colony_production.gd**
Comprehensive tests for the colony production system:
- ✅ Farm production at different levels
- ✅ Resource consumption
- ✅ Multiple buildings accumulating production
- ✅ Mixed building types (farm, mill, mine)
- ✅ Multi-turn production accumulation
- ✅ Building upgrades changing production
- ✅ Resource deficit handling

#### **test/integration/test_game_persistence.gd**
Tests for save/load and game state:
- ✅ World setup validation
- ✅ Colony persistence in player state
- ✅ Building persistence in colonies
- ✅ Scenario loading
- ✅ Turn simulation
- ✅ Assertion helper validation

### 3. Documentation

- **[INTEGRATION_TESTING_GUIDE.md](INTEGRATION_TESTING_GUIDE.md)** - Complete guide with examples
- **[scenarios/README.md](scenarios/README.md)** - How to create and use test scenarios
- **[README.md](README.md)** - Updated with integration testing info

### 4. Directory Structure

```
test/
├── integration_test_base.gd      # Base class for all integration tests
├── integration/                   # Integration test files
│   ├── test_colony_production.gd  # Production system tests
│   └── test_game_persistence.gd   # Save/load tests
└── scenarios/                     # Saved game states for testing
    └── README.md                  # How to create scenarios
```

---

## Quick Start

### Writing Your First Integration Test

```gdscript
extends IntegrationTestBase

func test_my_feature() -> void:
    # 1. Setup the game world
    await setup_world()

    # 2. Create entities
    var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
    var farm: Building = await create_test_building(
        colony,
        Term.BuildingType.FARM,
        Vector2i(11, 10),
        1
    )

    # 3. Record starting state
    var starting_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)

    # 4. Execute the test
    await process_colony_turn()

    # 5. Verify results
    var ending_crops: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
    assert_gt(ending_crops, starting_crops, "Farm should produce crops")
```

### Running Integration Tests

**In Godot Editor:**
1. Open **GUT panel** (bottom panel)
2. Select `test/integration/` folder
3. Click **Run** or **Run All**

**From Command Line:**
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/integration/
```

---

## Key Features

### 1. Realistic Game Simulation

Integration tests use the actual game systems:
- Real WorldManager, Player, Colonies
- Actual production calculations from JSON metadata
- Complete turn cycle simulation
- Save/load functionality

### 2. Easy Entity Creation

```gdscript
# Create a colony with custom resources
var colony: CenterBuilding = await create_test_colony(Vector2i(5, 5), {
    "gold": 500,
    "crops": 2000
})

# Create a level 3 farm
var farm: Building = await create_test_building(
    colony,
    Term.BuildingType.FARM,
    Vector2i(6, 5),
    3  # Level 3
)

# Create a settler unit
var settler: Unit = await create_test_unit(
    Term.UnitType.SETTLER,
    Vector2i(10, 10),
    1
)
```

### 3. Turn Simulation

```gdscript
# Simulate 10 complete turns (including NPCs)
await simulate_turns(10)

# Or just process colony production (faster)
await process_colony_turn()
```

### 4. Scenario Testing

```gdscript
# Load a pre-built game state
var success: bool = await load_scenario("large_empire")

# Test complex scenarios without manual setup
assert_gte(player.cm.colonies.size(), 5)
```

### 5. Custom Assertions

```gdscript
# Assert colony exists and get it
var colony: CenterBuilding = assert_colony_exists(Vector2i(10, 10))

# Assert building type exists in colony
var farm: Building = assert_building_exists(colony, Term.BuildingType.FARM)

# Assert colony has resources
assert_colony_resources(colony, {"gold": 1000, "crops": 500})

# Assert production transaction
var production: Transaction = farm.get_production()
assert_production(production, {"crops": 50})
```

---

## Test Coverage

### Current Coverage ✅

- **Colony Creation** - Settlers founding colonies
- **Building Creation** - All building types can be created
- **Production System** - Buildings produce resources per turn
- **Resource Consumption** - Buildings consume resources
- **Multi-Building Production** - Multiple buildings accumulate correctly
- **Building Upgrades** - Level changes affect production
- **Turn Simulation** - Game progresses correctly over time
- **Game State Persistence** - Colonies and buildings persist

### Next Steps 🎯

Expand coverage to:
- **Population Growth** - Test growth formulas
- **Labor Distribution** - Workers allocated to buildings
- **Production Bonuses** - Terrain and specialization bonuses
- **Trade System** - Trade routes between colonies
- **Combat System** - Unit battles and sieges
- **NPC Interactions** - Diplomacy and AI behavior
- **Complete Scenarios** - Full save/load cycles with all systems

---

## Example Test: Farm Production

Here's a complete example from `test_colony_production.gd`:

```gdscript
func test_farm_level_1_produces_correct_crops() -> void:
    # Arrange - Create a colony with a level 1 farm
    await setup_world()
    var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
    var farm: Building = await create_test_building(
        colony,
        Term.BuildingType.FARM,
        Vector2i(11, 10),
        1
    )

    # Get expected production from game data
    var expected_production: Transaction = autofree(
        Def.get_building_make(Term.BuildingType.FARM, 1)
    )
    var expected_crops: int = expected_production.get_resource_amount(
        Term.ResourceType.CROPS
    )

    # Record starting crops
    var starting_crops: int = colony.bank.get_resource_amount(
        Term.ResourceType.CROPS
    )

    # Act - Process one production turn
    await process_colony_turn()

    # Assert - Verify crops produced
    var ending_crops: int = colony.bank.get_resource_amount(
        Term.ResourceType.CROPS
    )
    var actual_production: int = ending_crops - starting_crops

    assert_eq(
        actual_production,
        expected_crops,
        "Farm level 1 should produce " + str(expected_crops) + " crops"
    )
```

---

## Best Practices

### DO ✅

- Test complete workflows (not just individual methods)
- Use realistic game data from JSON metadata
- Test edge cases (no resources, max levels, etc.)
- Use descriptive test names
- Use `autofree()` for Transaction objects
- Use `await` for all async operations

### DON'T ❌

- Test implementation details
- Hardcode game values that come from JSON
- Make tests depend on execution order
- Create massive test scenarios (keep focused)
- Skip cleanup (autofree handles this)

---

## Memory Management

All Node-based objects are automatically cleaned up:

```gdscript
# Entities created by helpers are managed
var colony: CenterBuilding = await create_test_colony(...)  # Auto-freed

# Transactions need autofree
var transaction: Transaction = autofree(Transaction.new())

# World manager cleaned up in after_each()
await setup_world()  # Automatically cleaned up
```

See [MEMORY_MANAGEMENT_GUIDE.md](MEMORY_MANAGEMENT_GUIDE.md) for details.

---

## Resources

- **[INTEGRATION_TESTING_GUIDE.md](INTEGRATION_TESTING_GUIDE.md)** - Complete reference
- **[README.md](README.md)** - Main testing guide
- **[scenarios/README.md](scenarios/README.md)** - Scenario creation guide
- **[GUT Documentation](https://github.com/bitwes/Gut/wiki)** - GUT framework docs

---

## Next Steps

1. **Run the existing tests** to verify everything works
2. **Write tests for your features** using the examples as templates
3. **Create test scenarios** for complex game states
4. **Expand coverage** to other game systems

---

**Happy Integration Testing! 🧪**

Integration tests give you confidence that complex game systems work correctly together. Use them to validate gameplay, catch regressions, and document expected behavior.

---

## Technical Notes

### System Requirements

- Godot 4.4+
- GUT testing framework (already installed)
- Project must compile without errors

### Known Limitations

1. **Map Generation**: Currently uses full map generation. A minimal test map system can be added later for faster tests.
2. **Async Operations**: All entity creation requires `await` - don't forget it!
3. **Turn Orchestration**: Some tests may need full turn simulation vs just colony production processing.

### Troubleshooting

**"Player must be initialized"**
- Call `await setup_world()` at the start of your test

**"Colony cannot be null"**
- Verify the colony was created successfully
- Check that tile position is valid

**Production values don't match**
- Use `Def.get_building_make()` for expected values
- Check if bonuses/modifiers are being applied

**Tests hang or timeout**
- Missing `await` on async operations
- Too many turns being simulated

---

**Setup completed on**: 2025-11-07
**Framework version**: 1.0
**Status**: ✅ Ready for use
