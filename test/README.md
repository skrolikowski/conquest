# Conquest Testing Guide

This directory contains unit tests, integration tests, and testing utilities for the Conquest game.

---

## Quick Start

### Running Tests in Godot Editor

1. **Open Test Panel**
   - Click **Project** → **Tools** → **GUT**
   - Or press the GUT button in the bottom panel

2. **Run All Tests**
   - Click **Run All** button in GUT panel
   - Tests will execute and show results in real-time

3. **Run Specific Test**
   - Select test file from the list
   - Click **Run** to run just that test

---

## Directory Structure

```
test/
├── unit/                   # Unit tests (isolated component tests)
│   ├── test_transaction.gd           # Resource transaction system tests
│   ├── test_building_definitions.gd  # Building metadata tests
│   └── [more tests...]
├── integration/            # Integration tests (system interactions)
│   ├── test_colony_production.gd     # Colony production workflows
│   ├── test_game_persistence.gd      # Save/load system tests
│   └── [more tests...]
├── scenarios/              # Saved game states for scenario testing
├── results/                # Test output (JUnit XML, logs)
├── integration/
│   └── integration_test_base.gd  # Base class for integration tests
├── colony_test_menu.tscn   # Manual testing UI
├── colony_debug_overlay.gd # In-game debug overlay
├── INTEGRATION_TESTING_GUIDE.md  # Complete integration testing guide
└── COLONY_TESTING_CHECKLIST.md  # Manual test checklist
```

---

## Running Tests

### Method 1: GUT Panel (Recommended)

1. Open Godot Editor
2. Bottom panel → **GUT** tab
3. Click **Run All** or select specific test
4. View results in the panel

### Method 2: Command Line

Run tests headlessly for CI/CD pipelines:

```bash
# Run all tests
godot --headless -s addons/gut/gut_cmdln.gd

# Run specific test directory
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/

# Run specific test file
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_transaction.gd

# Export results to JUnit XML
godot --headless -s addons/gut/gut_cmdln.gd -gjunit_xml_file=res://test/results/junit.xml
```

### Method 3: Manual Test Scene

For visual/interactive testing:

```
1. Open test/colony_test_menu.tscn
2. Run the scene (F6)
3. Click "Run All Tests" button
```

---

## Writing Tests

### Basic Test Structure

```gdscript
extends GutTest
## Description of what this test file covers

func before_each():
    # Setup before each test
    pass

func test_something_works():
    # Arrange
    var my_object = MyClass.new()

    # Act
    my_object.do_something()

    # Assert
    assert_eq(my_object.value, 10, "Value should be 10")
```

### Common Assertions

```gdscript
# Equality
assert_eq(actual, expected, "message")
assert_ne(actual, not_expected, "message")

# Null checks
assert_null(value, "message")
assert_not_null(value, "message")

# Boolean
assert_true(condition, "message")
assert_false(condition, "message")

# Comparison
assert_gt(a, b, "a should be greater than b")
assert_gte(a, b, "a should be >= b")
assert_lt(a, b, "a should be less than b")
assert_lte(a, b, "a should be <= b")

# Type checking
assert_is(object, Class, "message")
```

### Test Naming Convention

- Test methods must start with `test_`
- Use descriptive names: `test_farm_produces_crops_at_level_1()`
- Tests run in alphabetical order by default

---

## Test Categories

### Unit Tests (`test/unit/`)

Test individual components in isolation:

- **test_transaction.gd** - Resource transaction operations
- **test_building_definitions.gd** - JSON metadata loading
- Future: test_population_growth.gd, test_labor_distribution.gd

**When to write unit tests:**
- Testing a single class or function
- Testing math/calculation logic
- Testing data structures

### Integration Tests (`test/integration/`)

Test system interactions across multiple components:

- **test_colony_production.gd** - Colony + buildings + resource production workflows
- **test_game_persistence.gd** - Save/Load system and scenario loading

**When to write integration tests:**
- Testing complete game workflows
- Testing multiple systems working together
- Testing scenarios (e.g., "colony with farm produces crops")

**See:** [INTEGRATION_TESTING_GUIDE.md](INTEGRATION_TESTING_GUIDE.md) for complete guide

### Manual Tests

- **colony_test_menu.tscn** - Visual test runner
- **COLONY_TESTING_CHECKLIST.md** - Full manual test suite

---

## Test Coverage Goals

### Current Coverage
- ✅ Transaction system (100% - unit tests)
- ✅ Building definitions (metadata - unit tests)
- ✅ Colony production workflows (integration tests)
- ✅ Game persistence basics (integration tests)
- 🟡 Population system (partial - manual tests)
- 🟡 Save/Load complete scenarios (partial)
- ❌ Production bonuses (terrain + specialization - todo)
- ❌ Labor distribution (todo)
- ❌ Combat system (todo)

### Priority Tests to Add
1. Population growth formulas
2. Production bonus calculations (terrain + specialization)
3. Building placement validation
4. Labor distribution
5. Resource flow (production → consumption)

---

## Debugging Failed Tests

### View Detailed Output

GUT panel shows:
- ✅ Passed tests (green)
- ❌ Failed tests (red)
- ⚠️ Warnings

Click on a failed test to see:
- Expected vs Actual values
- Line number of failure
- Custom assertion messages

### Common Issues

**Test can't find autoload (Def, GameData, etc.)**
- Autoloads are available in tests
- Check spelling and capitalization

**Resource not found**
- Use `res://` paths
- Verify file exists at that path

**Test passes individually but fails in suite**
- Check `before_each()`/`after_each()` cleanup
- Tests should not depend on execution order

---

## Continuous Integration

### GitHub Actions Example

```yaml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: 4.4

      - name: Run GUT Tests
        run: |
          godot --headless -s addons/gut/gut_cmdln.gd \
            -gjunit_xml_file=test/results/junit.xml

      - name: Publish Test Results
        uses: EnricoMi/publish-unit-test-result-action@v2
        with:
          files: test/results/junit.xml
```

---

## Best Practices

### DO:
- ✅ Write tests for new features before implementation (TDD)
- ✅ Test edge cases (zero, negative, large values)
- ✅ Use descriptive assertion messages
- ✅ Keep tests fast and isolated
- ✅ Use `before_each()` to reset state

### DON'T:
- ❌ Test implementation details (test behavior, not internals)
- ❌ Make tests depend on execution order
- ❌ Use `await get_tree().process_frame` unless necessary
- ❌ Commit test results to git (they're auto-generated)

---

## Resources

- **GUT Documentation**: https://github.com/bitwes/Gut/wiki
- **GUT Assertions**: https://github.com/bitwes/Gut/wiki/Asserts-and-Methods
- **Godot Testing Best Practices**: https://docs.godotengine.org/en/stable/tutorials/scripting/unit_testing.html

---

## Getting Help

- Review existing tests in `test/unit/` for examples
- Check GUT wiki for assertion reference
- Run `colony_test_menu.tscn` for interactive testing
- Use `colony_debug_overlay.gd` for runtime inspection (F12 in-game)

---

**Happy Testing! 🧪**
