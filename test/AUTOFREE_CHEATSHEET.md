# `autofree()` Cheat Sheet

## Quick Reference for Memory-Leak-Free Tests

---

## ✅ **Always Wrap These with `autofree()`**

### Transaction Objects
```gdscript
// ❌ WRONG - Memory leak
var transaction = Transaction.new()

// ✅ CORRECT - Auto-freed
var transaction = autofree(Transaction.new())
```

### Cloned Transactions
```gdscript
// ❌ WRONG - clone() creates new Node
var cloned = original.clone()

// ✅ CORRECT - Wrap the clone
var cloned = autofree(original.clone())
```

### GameData Method Returns
```gdscript
// ❌ WRONG - Returns new Transaction
var cost = GameData.get_building_cost(Term.BuildingType.FARM, 1)

// ✅ CORRECT - Wrap the return value
var cost = autofree(GameData.get_building_cost(Term.BuildingType.FARM, 1))
```

---

## 🔄 **Common Patterns**

### Multiple Transactions
```gdscript
func test_something():
    var t1 = autofree(Transaction.new())
    var t2 = autofree(Transaction.new())
    var t3 = autofree(Transaction.new())

    // Use them...

    // All auto-freed after test
```

### Clone + Modify
```gdscript
func test_clone():
    var original = autofree(Transaction.new())
    original.add_resource_amount_by_type(Term.ResourceType.GOLD, 100)

    var copy = autofree(original.clone())  // ← Must autofree clone!
    copy.add_resource_amount_by_type(Term.ResourceType.GOLD, 50)

    assert_eq(original.get_resource_amount(Term.ResourceType.GOLD), 100)
    assert_eq(copy.get_resource_amount(Term.ResourceType.GOLD), 150)
```

### GameData + Transaction
```gdscript
func test_building():
    var cost = autofree(GameData.get_building_cost(Term.BuildingType.FARM, 1))
    var bank = autofree(Transaction.new())

    bank.add_resources({"wood": 100, "crops": 100})

    // Check affordability...

    // Both cost and bank freed
```

---

## 📋 **Full Test Example**

```gdscript
extends GutTest

func test_production_chain():
    // Step 1: Get building definitions (all return new Transactions)
    var farm_make = autofree(GameData.get_building_make(Term.BuildingType.FARM, 1))
    var mill_need = autofree(GameData.get_building_need(Term.BuildingType.MILL, 1))
    var mill_make = autofree(GameData.get_building_make(Term.BuildingType.MILL, 1))

    // Step 2: Create colony bank
    var bank = autofree(Transaction.new())
    bank.add_resources({"crops": 0})

    // Step 3: Simulate production
    var net_production = autofree(farm_make.clone())  // ← Clone needs autofree!
    net_production.add_transaction(mill_need)  // Subtract consumption

    // Step 4: Assert
    var crops = net_production.get_resource_amount(Term.ResourceType.CROPS)
    assert_gt(crops, 0, "Should have net crop production")

    // All 6 objects (farm_make, mill_need, mill_make, bank, net_production, clone) freed!
```

---

## 🚫 **Don't Use `autofree()` For**

### Built-in Types (Auto-Managed)
```gdscript
// ✅ No autofree needed
var number = 42
var text = "hello"
var array = [1, 2, 3]
var dict = {"key": "value"}
```

### RefCounted Objects (Auto-Managed)
```gdscript
// ✅ No autofree needed (if your class extends RefCounted)
class_name MyData extends RefCounted

var data = MyData.new()  // Auto garbage-collected
```

### Static/Singleton References
```gdscript
// ✅ No autofree needed (not creating new objects)
var config = GameData
var world = Def.get_world()
```

---

## 🔍 **How to Check for Leaks**

### In GUT Panel
After running tests, look for:
```
Orphans: 0  ← ✅ GOOD! No leaks
```

If you see:
```
Orphans: 47  ← ❌ BAD! You have 47 memory leaks
```

### Find the Leak
1. Search your test for `Transaction.new()` without `autofree()`
2. Search for `.clone()` without `autofree()`
3. Search for `GameData.get_building_*()` without `autofree()`

---

## 🛠️ **Quick Fix Script**

Run this in your terminal to find all potential leaks:

```bash
# Find Transaction.new() without autofree
grep -n "Transaction\.new()" test/unit/*.gd | grep -v "autofree"

# Find .clone() without autofree
grep -n "\.clone()" test/unit/*.gd | grep -v "autofree"

# Find GameData calls without autofree
grep -n "GameData\.get_building" test/unit/*.gd | grep -v "autofree"
```

---

## 📝 **Before/After Examples**

### Before (47 Orphans)
```gdscript
func test_building_cost():
    var cost = GameData.get_building_cost(Term.BuildingType.FARM, 1)
    var bank = Transaction.new()
    var cloned = cost.clone()

    // ... test logic ...

    // 3 orphans created!
```

### After (0 Orphans)
```gdscript
func test_building_cost():
    var cost = autofree(GameData.get_building_cost(Term.BuildingType.FARM, 1))
    var bank = autofree(Transaction.new())
    var cloned = autofree(cost.clone())

    // ... test logic ...

    // All 3 objects auto-freed!
```

---

## 🎯 **Golden Rule**

> **If it's a Node and you created it, wrap it with `autofree()`**

### Decision Tree
```
Is it a Node?
├─ Yes → Use autofree()
│  ├─ Transaction.new() → autofree(Transaction.new())
│  ├─ .clone() → autofree(original.clone())
│  ├─ GameData.get_*() → autofree(GameData.get_*())
│  └─ load().instantiate() → autofree(load().instantiate())
│
└─ No → No autofree needed
   ├─ int, String, Array, Dictionary
   ├─ RefCounted objects
   └─ Autoload/singleton references
```

---

## 📚 **Further Reading**

- [test/MEMORY_MANAGEMENT_GUIDE.md](MEMORY_MANAGEMENT_GUIDE.md) - Detailed guide
- [test/unit/test_transaction_FIXED.gd](unit/test_transaction_FIXED.gd) - Example without leaks
- [GUT autofree() docs](https://github.com/bitwes/Gut/wiki/Quick-Start#autofree)

---

## 💡 **Pro Tips**

1. **Run tests frequently** - Catch orphans early
2. **Check orphan count** - Should always be 0
3. **Use fixed examples** - Copy patterns from `*_FIXED.gd` files
4. **When in doubt** - Use `autofree()` (it's safe even for null)

---

**Target: 0 Orphans, Always! 🎯**
