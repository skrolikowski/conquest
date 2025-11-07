# Integration Testing Quick Start

Get started with integration testing in 5 minutes!

---

## 1. Create Your Test File

Create a new file in `test/integration/`:

```gdscript
extends IntegrationTestBase
## My first integration test

func test_colony_produces_resources() -> void:
    # Setup game world
    await setup_world()

    # Create colony with farm
    var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
    var farm: Building = await create_test_building(
        colony,
        Term.BuildingType.FARM,
        Vector2i(11, 10),
        1  # Level 1
    )

    # Record starting resources
    var start: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)

    # Process one turn
    await process_colony_turn()

    # Verify production happened
    var end: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
    assert_gt(end, start, "Farm should produce crops")
```

---

## 2. Run the Test

**In Godot Editor:**
1. Bottom panel → **GUT**
2. Find your test in the list
3. Click **Run**
4. ✅ Watch it pass!

**From Terminal:**
```bash
cd /path/to/Conquest
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/integration/your_test.gd
```

---

## 3. Common Patterns

### Test Multiple Buildings

```gdscript
func test_multiple_farms() -> void:
    await setup_world()
    var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))

    # Create 3 farms
    await create_test_building(colony, Term.BuildingType.FARM, Vector2i(11, 10), 1)
    await create_test_building(colony, Term.BuildingType.FARM, Vector2i(12, 10), 1)
    await create_test_building(colony, Term.BuildingType.FARM, Vector2i(11, 11), 1)

    var start: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
    await process_colony_turn()
    var end: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)

    # 3 farms should produce 3x crops
    assert_gt(end - start, 100, "Multiple farms should produce")
```

### Test Over Multiple Turns

```gdscript
func test_production_over_time() -> void:
    await setup_world()
    var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
    await create_test_building(colony, Term.BuildingType.FARM, Vector2i(11, 10), 1)

    var start: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)

    # Simulate 5 turns
    await simulate_turns(5)

    var end: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
    assert_gt(end - start, 200, "5 turns should produce significant crops")
```

### Test Building Upgrades

```gdscript
func test_building_upgrade() -> void:
    await setup_world()
    var colony: CenterBuilding = await create_test_colony(Vector2i(10, 10))
    var farm: Building = await create_test_building(
        colony,
        Term.BuildingType.FARM,
        Vector2i(11, 10),
        1
    )

    # Test level 1 production
    var start1: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
    await process_colony_turn()
    var end1: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
    var level1_production: int = end1 - start1

    # Upgrade to level 2
    farm.level = 2
    farm.building_state = Term.BuildingState.ACTIVE

    # Test level 2 production
    var start2: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
    await process_colony_turn()
    var end2: int = colony.bank.get_resource_amount(Term.ResourceType.CROPS)
    var level2_production: int = end2 - start2

    assert_gt(level2_production, level1_production, "Level 2 should produce more")
```

---

## 4. Helper Methods Reference

### Setup
- `setup_world()` - Create game world (always call first)
- `load_scenario(name)` - Load saved game state

### Entity Creation
- `create_test_colony(pos, resources)` - Create colony at position
- `create_test_building(colony, type, pos, level)` - Add building to colony
- `create_test_unit(type, pos, level)` - Create unit at position

### Simulation
- `process_colony_turn()` - Process production for all colonies (fast)
- `simulate_turns(n)` - Simulate N complete game turns (slower)

### Assertions
- `assert_colony_exists(pos)` - Verify colony exists, return it
- `assert_building_exists(colony, type)` - Verify building exists in colony
- `assert_colony_resources(colony, dict)` - Verify colony has resources
- `assert_production(transaction, dict)` - Verify production amounts

---

## 5. Examples to Study

Check out these complete examples:

1. **test/integration/test_colony_production.gd**
   - Farm production at different levels
   - Multiple buildings
   - Multi-turn accumulation
   - Building upgrades

2. **test/integration/test_game_persistence.gd**
   - World setup validation
   - Turn simulation
   - Save/load basics

---

## Tips

✅ **Always use `await`** on async methods (setup_world, create_test_*)
✅ **Use `autofree()`** for Transaction objects
✅ **Name tests descriptively**: `test_farm_level_2_produces_more_crops()`
✅ **Test one thing at a time** - Keep tests focused
✅ **Use game data**: `Def.get_building_make()` for expected values

❌ **Don't hardcode** game values that come from JSON
❌ **Don't forget** to call `await setup_world()` first
❌ **Don't test** implementation details, test behavior

---

## Need More Help?

- **Full Guide**: [INTEGRATION_TESTING_GUIDE.md](INTEGRATION_TESTING_GUIDE.md)
- **Main Testing Docs**: [README.md](README.md)
- **Scenarios**: [scenarios/README.md](scenarios/README.md)

---

**You're ready to write integration tests! 🎉**
