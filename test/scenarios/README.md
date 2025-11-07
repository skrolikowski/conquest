# Test Scenarios

This directory contains saved game states for integration testing.

## What are Scenarios?

Scenarios are saved game files (`.ini` format) that represent specific game states. They're used in integration tests to:

- Test complex game situations without manual setup
- Reproduce specific bugs or edge cases
- Test endgame scenarios (large empires, multiple colonies)
- Validate save/load functionality

## Creating Scenarios

### Method 1: Play and Save (Recommended)

1. Start the Conquest game normally
2. Build the game state you want to test (colonies, buildings, units)
3. Save the game (creates `conquest_save_01.ini` in user data folder)
4. Copy the file here and rename it: `test/scenarios/my_scenario.ini`

**User data location:**
- **macOS**: `~/Library/Application Support/Godot/app_userdata/Conquest/`
- **Linux**: `~/.local/share/godot/app_userdata/Conquest/`
- **Windows**: `%APPDATA%/Godot/app_userdata/Conquest/`

### Method 2: Duplicate Existing Scenario

1. Copy an existing scenario file
2. Edit the `.ini` file to modify game state
3. Test with `load_scenario("my_new_scenario")`

## Using Scenarios in Tests

```gdscript
extends "res://test/integration_test_base.gd"

func test_my_scenario() -> void:
    # Load the scenario
    var success: bool = await load_scenario("large_empire")
    assert_true(success, "Scenario should load")

    # Test the loaded state
    assert_gte(player.cm.colonies.size(), 3, "Should have at least 3 colonies")

    # Simulate gameplay
    await simulate_turns(10)

    # Verify results
    var capital: CenterBuilding = player.cm.colonies[0]
    assert_gt(capital.population, 100, "Capital should grow")
```

## Scenario Naming Conventions

Use descriptive names that indicate what the scenario tests:

- `early_game_single_colony.ini` - One colony, few resources
- `mid_game_production_chain.ini` - Multiple buildings testing production
- `large_empire_endgame.ini` - Many colonies, high population
- `resource_deficit.ini` - Colony with no resources (edge case)
- `max_level_buildings.ini` - All buildings at max level

## Scenario File Format

Scenarios use Godot's `ConfigFile` format:

```ini
[game]
turn_number=50

[camera]
position_x=1000.0
position_y=800.0
zoom=1.5

[world]
seed=12345
# ... terrain data

[player]
# ... colony and unit data
```

## Tips

- **Keep scenarios focused** - Test one thing at a time
- **Document what each scenario tests** - Add comments to scenario files
- **Version control** - Commit scenarios to git for team sharing
- **Clean up old scenarios** - Remove obsolete ones as game changes

## Current Scenarios

_Add documentation here as scenarios are created_

---

**Need Help?**

See [INTEGRATION_TESTING_GUIDE.md](../INTEGRATION_TESTING_GUIDE.md) for complete integration testing documentation.
