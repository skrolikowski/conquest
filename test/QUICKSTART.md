# GUT Testing Quick Start

Follow these steps to run your first tests!

---

## Step 1: Restart Godot Editor

**Important:** You need to restart Godot for the GUT plugin to load.

1. Close Godot Editor completely
2. Reopen your Conquest project
3. GUT plugin will now be active

---

## Step 2: Verify GUT is Installed

After reopening Godot:

1. Look at the **bottom panel** (where Output, Debugger are)
2. You should see a new **GUT** tab
3. If you don't see it:
   - Click **Project** → **Tools** → **GUT** to open it manually
   - Or go to **Project** → **Project Settings** → **Plugins** and enable **Gut**

---

## Step 3: Run Your First Test

### Using the GUT Panel (Easiest)

1. Click the **GUT** tab in the bottom panel
2. You'll see the GUT test runner interface
3. Click **"Run All"** button
4. Watch the tests execute!

Expected output:
```
Running: test_transaction.gd
  ✅ test_transaction_initializes_with_zero_resources
  ✅ test_transaction_contains_all_resource_types
  ✅ test_add_resource_amount_by_type_increases_resource
  ... (more tests)

Running: test_building_definitions.gd
  ✅ test_all_building_types_have_definitions
  ✅ test_farm_has_correct_level_1_definition
  ... (more tests)

Tests run: XX
Passed: XX
Failed: 0
```

---

## Step 4: Understanding Test Results

### Green (Passed) ✅
Test worked correctly! The assertion was true.

### Red (Failed) ❌
Something broke. Click the failed test to see:
- **Expected value**: What the test expected
- **Actual value**: What it actually got
- **Line number**: Where the test failed

### Example Failed Test
```
❌ test_farm_produces_crops
   Expected: 50
   Actual: 0
   Line: 147
   Message: "Farm should produce crops"
```

This tells you:
- The farm isn't producing crops
- Check your JSON metadata or production calculation

---

## Step 5: Run Specific Tests

### Run One Test File
1. In GUT panel, expand the test file list
2. Click on `test_transaction.gd`
3. Click **"Run"** (not "Run All")
4. Only that file's tests will run

### Run One Test Method
1. Open `test/unit/test_transaction.gd` in the editor
2. Find the test method (e.g., `test_clone_creates_independent_copy`)
3. In GUT panel, select the file
4. Click **"Run"** → Select specific test

---

## Step 6: Add Debugging to Your Test

If a test fails, add print statements:

```gdscript
func test_something():
    # Arrange
    var my_value = 42

    # Debug output
    print("DEBUG: my_value = ", my_value)

    # Assert
    assert_eq(my_value, 42, "Should be 42")
```

Output appears in the **Output** tab (next to GUT tab).

---

## Common First-Time Issues

### "Test file not found"
- Make sure your test files are in `res://test/unit/`
- Check that `.gutconfig.json` has correct paths

### "Autoload not found (Def, GameData, etc.)"
- Autoloads are available in tests automatically
- Check spelling: `GameData` not `gameData`

### "Tests pass individually but fail together"
- Use `before_each()` to reset state
- Tests shouldn't depend on execution order

### GUT tab doesn't appear
- Restart Godot Editor
- Check **Project** → **Project Settings** → **Plugins** → Enable **Gut**

---

## Next Steps After First Test Run

### If All Tests Pass ✅
Congratulations! Your testing framework is working.

**Next:**
1. Read [test/README.md](README.md) for detailed guide
2. Add more tests for colony management
3. Try the manual test UI: `test/colony_test_menu.tscn`

### If Tests Fail ❌
Don't worry! Failed tests are valuable feedback.

**Troubleshoot:**
1. Click the failed test to see details
2. Check the expected vs actual values
3. Review the line number in the test file
4. Add `print()` statements to debug

**Common failures:**
- **JSON metadata missing**: Check `assets/metadata/buildings.json`
- **Transaction issues**: Review `scripts/transaction.gd`
- **Null values**: Object might not be initialized

---

## Example: Debugging a Failed Test

**Test Output:**
```
❌ test_farm_has_correct_level_1_definition
   Expected: not null
   Actual: null
   Message: "Farm level 1 should have cost"
```

**How to Fix:**

1. **Open the test file**: `test/unit/test_building_definitions.gd:48`
2. **Add debug output**:
   ```gdscript
   func test_farm_has_correct_level_1_definition():
       var cost = GameData.get_building_cost(Term.BuildingType.FARM, 1)

       # DEBUG
       print("DEBUG: cost = ", cost)
       print("DEBUG: FARM enum value = ", Term.BuildingType.FARM)

       assert_not_null(cost, "Farm level 1 should have cost")
   ```

3. **Run the test again**
4. **Check Output tab** for your debug prints
5. **Investigate** why cost is null:
   - Is `buildings.json` loaded?
   - Is the key name correct (`"farm"` vs `"FARM"`)?
   - Is the level correct (1-indexed)?

---

## Visual Testing Alternative

If you prefer visual/interactive testing:

1. Open `test/colony_test_menu.tscn`
2. Press **F6** (Run Current Scene)
3. Click **"Run All Tests"** button
4. View results in the UI with color-coded output

---

## Running Tests from Command Line

For automation or CI/CD:

```bash
# Navigate to project directory
cd /Users/shanekrolikowski/Code/Godot/Conquest

# Run all tests
godot --headless -s addons/gut/gut_cmdln.gd

# Run with output
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/
```

---

## Cheat Sheet

| Action | How To |
|--------|--------|
| Run all tests | GUT panel → **Run All** |
| Run one test file | Select file → **Run** |
| View failed test details | Click on red test name |
| Add debug output | `print("DEBUG:", value)` in test |
| Open test file | Double-click in GUT panel |
| Refresh test list | GUT panel → **Refresh** button |

---

## You're Ready! 🚀

1. **Restart Godot Editor** (if you haven't already)
2. **Open GUT panel** (bottom panel)
3. **Click "Run All"**
4. **Watch your tests pass!**

If you get stuck, check [test/README.md](README.md) for more details.

**Happy Testing!**
