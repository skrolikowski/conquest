# Transaction Migration: Node → RefCounted

## Summary

**Transaction has been converted from `Node` to `RefCounted`** to eliminate memory leaks and simplify memory management.

## The Problem

Previously, Transaction extended Node:

```gdscript
extends Node  # ❌ Required manual memory management
class_name Transaction
```

This caused memory leaks because:
1. Every `Transaction.new()` created an orphan Node
2. Callers had to remember to free Transactions
3. Test code needed `autofree()` everywhere
4. GameData methods like `get_building_cost()` created orphans

## The Solution

Now Transaction extends RefCounted:

```gdscript
extends RefCounted  # ✅ Automatic memory management
class_name Transaction
```

**Benefits:**
- ✅ **Zero orphans** - automatic cleanup via reference counting
- ✅ **No `autofree()` needed** in tests
- ✅ **Simpler code** - just create and use
- ✅ **Better performance** - less overhead than Node objects

## What Changed

### 1. Transaction Class ([scripts/transaction.gd](../scripts/transaction.gd))

```diff
- extends Node
+ extends RefCounted
  class_name Transaction
+ ## Resource transaction container with automatic memory management
```

### 2. Test Files (No More autofree!)

**Before:**
```gdscript
func test_something():
    var transaction = autofree(Transaction.new())  # ❌ Required
    var cost = autofree(GameData.get_building_cost(...))  # ❌ Required
```

**After:**
```gdscript
func test_something():
    var transaction = Transaction.new()  # ✅ Auto-freed
    var cost = GameData.get_building_cost(...)  # ✅ Auto-freed
```

### 3. Updated Files

- ✅ `scripts/transaction.gd` - Changed base class
- ✅ `test/unit/test_transaction.gd` - Removed all `autofree()` calls
- ✅ `test/unit/test_building_definitions.gd` - Removed `autofree()` calls
- ✅ `test/integration/test_game_persistence.gd` - Removed `autofree()` calls
- ✅ `test/MEMORY_MANAGEMENT_GUIDE.md` - Updated documentation
- ✅ `test/AUTOFREE_CHEATSHEET.md` - Updated documentation

## Why RefCounted Instead of Node?

Transaction is a **pure data container** with no Node-specific features:

| Node Features | Transaction Uses? |
|--------------|-------------------|
| Scene tree hierarchy | ❌ No |
| Signals (custom) | ❌ No |
| `_process()` / `_physics_process()` | ❌ No |
| Transform/Position | ❌ No |
| Input handling | ❌ No |
| **Just data storage** | ✅ Yes |

RefCounted objects are perfect for data containers because:
- Lightweight (no scene tree overhead)
- Automatic cleanup when last reference is gone
- Still support signals, custom methods, persistence
- Can still be used in class_name and type hints

## Migration Impact

### Production Code
**No changes required!** All production code continues to work:

```gdscript
# Still works exactly the same
var cost = GameData.get_building_cost(Term.BuildingType.FARM, 1)
var production = building.calculate_production()
colony.bank.add_transaction(cost)
```

### Test Code
**Optionally remove `autofree()`** - it's harmless but unnecessary:

```gdscript
# Both work, but first is cleaner
var t1 = Transaction.new()  # ✅ Preferred
var t2 = autofree(Transaction.new())  # ✅ Also fine (no-op)
```

## Verification

Run tests to verify zero orphans:

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test/ -gexit
```

**Before migration:**
```
33 Orphans  # ❌ Memory leaks!
```

**After migration:**
```
0 Orphans   # ✅ All clean!
```

## Future Considerations

Other candidates for RefCounted conversion:

- **UnitStats** - Pure data container, currently Node
- **BuildingDefinition** - If it becomes a class
- **River** / **MountainRange** - May benefit if they're data-only

**Rule of thumb:** If it doesn't need to be in the scene tree, use RefCounted!

## References

- [Godot Docs: RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)
- [Memory Management Guide](MEMORY_MANAGEMENT_GUIDE.md)
- [Autofree Cheat Sheet](AUTOFREE_CHEATSHEET.md)

---

**Migration Date:** 2025-11-09
**Impact:** Breaking change for tests (positive), no impact on production code
