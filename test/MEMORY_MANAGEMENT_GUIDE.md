# Memory Management in GUT Tests

## The Problem

Your `Transaction` class extends `Node`, which requires manual memory management:

```gdscript
extends Node  # ← Nodes need to be freed manually
class_name Transaction
```

When you create `Transaction.new()` in tests, these Node objects become **orphans** if not freed.

---

## The Solution: Use `autofree()`

GUT provides `autofree()` to automatically free Node objects after each test.

### **Before (Memory Leak)**
```gdscript
func test_something():
    var transaction = Transaction.new()  # ← Orphan!
    assert_eq(transaction.get_resource_amount(Term.ResourceType.GOLD), 0)
    # Transaction is never freed
```

### **After (Fixed)**
```gdscript
func test_something():
    var transaction = autofree(Transaction.new())  # ← Auto-freed after test
    assert_eq(transaction.get_resource_amount(Term.ResourceType.GOLD), 0)
    # GUT automatically frees transaction when test finishes
```

---

## When to Use `autofree()`

### ✅ **Use `autofree()` for:**
- Any `Transaction.new()`
- Any Node-based objects created in tests
- Objects returned from factory methods that create Nodes
- Instantiated scenes (`load().instantiate()`)

### ❌ **Don't use `autofree()` for:**
- RefCounted objects (they auto-free themselves)
- Built-in types (int, String, Dictionary, Array)
- Objects you explicitly `free()` yourself

---

## Pattern: Wrap ALL Node Creation

### Single Object
```gdscript
func test_transaction_creation():
    var transaction = autofree(Transaction.new())
    assert_not_null(transaction)
```

### Multiple Objects
```gdscript
func test_transaction_merge():
    var t1 = autofree(Transaction.new())
    var t2 = autofree(Transaction.new())

    t1.add_resource_amount_by_type(Term.ResourceType.GOLD, 100)
    t2.add_resource_amount_by_type(Term.ResourceType.GOLD, 50)

    t1.add_transaction(t2)
    assert_eq(t1.get_resource_amount(Term.ResourceType.GOLD), 150)
    # Both t1 and t2 are auto-freed
```

### Cloned Objects (Important!)
```gdscript
func test_clone():
    var original = autofree(Transaction.new())
    var cloned = autofree(original.clone())  # ← clone() creates new Node!

    # Both original and cloned will be freed
```

### Objects from GameData
```gdscript
func test_building_cost():
    # GameData.get_building_cost() returns a NEW Transaction object
    var cost = autofree(GameData.get_building_cost(Term.BuildingType.FARM, 1))

    assert_not_null(cost)
    assert_gt(cost.get_resource_amount(Term.ResourceType.WOOD), 0)
```

---

## Complete Test Example (No Memory Leaks)

```gdscript
extends GutTest

func test_transaction_operations():
    # All transactions auto-freed after test
    var t1 = autofree(Transaction.new())
    var t2 = autofree(Transaction.new())

    t1.add_resource_amount_by_type(Term.ResourceType.GOLD, 100)
    t2.add_resource_amount_by_type(Term.ResourceType.WOOD, 50)

    var merged = autofree(t1.clone())  # clone creates new object
    merged.add_transaction(t2)

    assert_eq(merged.get_resource_amount(Term.ResourceType.GOLD), 100)
    assert_eq(merged.get_resource_amount(Term.ResourceType.WOOD), 50)

    # GUT automatically calls free() on t1, t2, merged after test completes


func test_building_definitions():
    # GameData returns NEW Transaction objects - must autofree
    var cost = autofree(GameData.get_building_cost(Term.BuildingType.FARM, 1))
    var make = autofree(GameData.get_building_make(Term.BuildingType.FARM, 1))

    assert_not_null(cost)
    assert_not_null(make)

    # Both cost and make are freed automatically
```

---

## Alternative: Manual Cleanup in `after_each()`

If you prefer explicit control:

```gdscript
extends GutTest

var transactions: Array[Transaction] = []

func after_each():
    # Manually free all transactions after each test
    for t in transactions:
        t.free()
    transactions.clear()

func test_something():
    var t1 = Transaction.new()
    transactions.append(t1)  # Track for cleanup

    var t2 = Transaction.new()
    transactions.append(t2)

    # Test logic...
    # Transactions freed in after_each()
```

**Note:** `autofree()` is simpler and recommended.

---

## Fixing Your Existing Tests

### test_transaction.gd

Replace every:
```gdscript
var transaction = Transaction.new()
```

With:
```gdscript
var transaction = autofree(Transaction.new())
```

**Also fix clones:**
```gdscript
var cloned = autofree(original.clone())  # clone() creates new object!
```

### test_building_definitions.gd

Replace every:
```gdscript
var cost = GameData.get_building_cost(...)
var make = GameData.get_building_make(...)
var need = GameData.get_building_need(...)
```

With:
```gdscript
var cost = autofree(GameData.get_building_cost(...))
var make = autofree(GameData.get_building_make(...))
var need = autofree(GameData.get_building_need(...))
```

---

## How `autofree()` Works

```gdscript
func autofree(obj: Node) -> Node:
    # GUT tracks this object
    # After test completes, GUT calls obj.free()
    return obj
```

GUT maintains a list of autofreed objects and frees them in `after_each()` automatically.

---

## Checking for Memory Leaks

### In GUT Panel
After running tests, check for:
```
Orphans: 0  # ← Good! No memory leaks
```

If you see:
```
Orphans: 47  # ← Bad! Memory leaks detected
```

### In Test Output
GUT will warn:
```
WARNING: ObjectDB instances leaked at exit (run with --verbose for details).
Orphan StringName: ...
```

---

## Best Practice: Always Use `autofree()`

**Make it a habit:**

```gdscript
// ❌ BAD - Creates orphans
var obj = MyNodeClass.new()

// ✅ GOOD - Auto-freed
var obj = autofree(MyNodeClass.new())
```

---

## Quick Reference

| Code | Memory Management |
|------|-------------------|
| `Transaction.new()` | ❌ Orphan - needs `autofree()` |
| `autofree(Transaction.new())` | ✅ Auto-freed after test |
| `original.clone()` | ❌ Orphan - needs `autofree()` |
| `autofree(original.clone())` | ✅ Auto-freed after test |
| `GameData.get_building_cost(...)` | ❌ Orphan - needs `autofree()` |
| `autofree(GameData.get_building_cost(...))` | ✅ Auto-freed after test |
| `RefCounted.new()` | ✅ Auto-freed (RefCounted) |
| `int`, `String`, `Dictionary` | ✅ Auto-freed (built-in types) |

---

## Why Transaction Extends Node?

If Transaction doesn't need to be in the scene tree, consider changing to `RefCounted`:

```gdscript
extends RefCounted  # ← Auto memory management
class_name Transaction
```

**Benefits:**
- No manual `free()` needed
- No `autofree()` in tests
- Automatic garbage collection

**Trade-offs:**
- Can't be added to scene tree
- No `_ready()`, `_process()` methods

If Transaction is only used for data (no scene tree presence), RefCounted is better.

---

## Summary

1. **Always use `autofree()` for Node objects in tests**
2. **Wrap all `Transaction.new()` calls**
3. **Wrap cloned objects: `autofree(original.clone())`**
4. **Wrap GameData returns: `autofree(GameData.get_...())`**
5. **Check GUT output for orphan count**

**Goal:** `Orphans: 0` after all tests run

---

**Next Steps:**
1. Read example test file below
2. Update your test files with `autofree()`
3. Re-run tests and verify `Orphans: 0`
