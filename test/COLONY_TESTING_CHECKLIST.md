# Colony Management Testing Checklist

Use this checklist to manually verify all colony management features before moving to trading/diplomacy.

---

## 1. Colony Founding

- [ ] Settler can found a colony on valid land tiles
- [ ] Settler cannot found colony on ocean/mountain
- [ ] Resources transfer from settler to new colony
- [ ] Undo colony works before completion
- [ ] Colony appears in player's colony list
- [ ] Center building created at correct position

---

## 2. Building Placement

### Small Buildings (1x1)
- [ ] Can place Farm on valid tile
- [ ] Can place Church on valid tile
- [ ] Can place Commerce on valid tile
- [ ] Cannot place on occupied tiles
- [ ] Cannot place on invalid terrain

### Large Buildings (2x2)
- [ ] Can place Fort (requires 2x2 space)
- [ ] Cannot place if any tile is occupied
- [ ] Placement preview shows all 4 tiles
- [ ] Building occupies correct tiles after placement

### Placement Rules
- [ ] Cannot overlap existing buildings
- [ ] Cannot place too far from colony center
- [ ] Building tiles correctly reserved
- [ ] BuildingManager tracks all building tiles

---

## 3. Building Economics

### Costs
- [ ] Level 1 building costs correct resources
- [ ] Level 2 building costs correct resources
- [ ] Level 3 building costs correct resources
- [ ] Level 4 building costs correct resources
- [ ] Cannot build if resources insufficient
- [ ] Bank.can_afford_this_turn() works correctly

### Production (Make)
- [ ] Farm produces crops per turn
- [ ] Mill produces goods per turn
- [ ] Mine produces metal/gold per turn
- [ ] Commerce produces gold per turn
- [ ] Production added to colony bank each turn

### Consumption (Need)
- [ ] Buildings consume resources per turn
- [ ] Resources deducted from colony bank
- [ ] Building stops if resources unavailable

### Turn Costs
- [ ] Per-turn maintenance costs deducted
- [ ] Cost starts on turn 0 (or configured turn)
- [ ] Buildings don't cost resources if bank empty (verify intended behavior)

---

## 4. Building Upgrades

- [ ] Can upgrade building from level 1 → 2
- [ ] Can upgrade building from level 2 → 3
- [ ] Can upgrade building from level 3 → 4
- [ ] Cannot upgrade beyond level 4
- [ ] Upgrade costs correct resources
- [ ] Building state transitions: ACTIVE → UPGRADE → ACTIVE
- [ ] Production scales with level

---

## 5. Building Demolition

- [ ] Can sell/demolish building
- [ ] Building removed from BuildingManager
- [ ] Tiles freed for new buildings
- [ ] Partial refund (if implemented)

---

## 6. Population System

### Growth
- [ ] Base growth: 8% of current population
- [ ] Church bonus: +10 per church level
- [ ] Growth formula: int(pop * 0.08) + (10 * church_level)
- [ ] Population increases each turn

### Consumption
- [ ] Crops consumed: 1 crop per 100 population (0.01 rate)
- [ ] Insufficient crops stops growth (verify behavior)

### Labor
- [ ] Buildings require labor from population
- [ ] Labor demand tracked per building type/level
- [ ] Labor distributed across buildings
- [ ] Insufficient labor affects production (verify)

---

## 7. Production Bonuses

### Terrain Modifiers
- [ ] Industry tiles provide production bonus
- [ ] WorldGen.terrain_modifier tracked correctly
- [ ] Bonuses apply to farm/mill/mine buildings
- [ ] Commerce doesn't gain terrain bonuses

### Specialization Bonuses
- [ ] Bonus calculated per building type
- [ ] Based on 20-tile blocks (tier system)
- [ ] Formula: 0.40 * (1 - exp(-0.1 * tier))
- [ ] Asymptotically approaches 40% max
- [ ] Bonus applied to production calculations

---

## 8. Resource Flow

### Transaction System
- [ ] Transaction.add_resource() works
- [ ] Transaction.clone() works
- [ ] Transaction.multiply() works
- [ ] Transaction.add_transaction() works
- [ ] Transaction.can_afford() checks work

### Bank System
- [ ] Colony bank tracks all resources
- [ ] Bank.add_resources() increases amounts
- [ ] Bank.remove_resources() decreases amounts
- [ ] Bank.can_afford_this_turn() validates availability

---

## 9. Turn Processing

### Colony Turn Cycle
- [ ] colony.begin_turn() called each turn
- [ ] Production calculated and added
- [ ] Consumption calculated and deducted
- [ ] Population grows each turn
- [ ] Building states update (NEW → ACTIVE, UPGRADE completes)

### Turn Number Tracking
- [ ] TurnOrchestrator tracks current_turn
- [ ] Turn increments each end_turn()
- [ ] Turn displayed in UI (WorldCanvas)

---

## 10. UI Integration

### Building UIs
- [ ] Clicking building opens correct UI
- [ ] Building stats displayed correctly
- [ ] Upgrade button works
- [ ] Sell button works
- [ ] UI refreshes on state changes

### Colony UIs
- [ ] Colony list shows all colonies
- [ ] Colony details show resources
- [ ] Population displayed correctly
- [ ] Building list shows all buildings

### Status Display
- [ ] Building status info shown on focus
- [ ] Tile info displayed
- [ ] WorldCanvas.update_status() works

---

## 11. Persistence (Save/Load)

### Saving
- [ ] Colony data saved to config file
- [ ] Building data saved (type, level, state, position)
- [ ] Resource amounts saved
- [ ] Population saved
- [ ] Turn number saved

### Loading
- [ ] Colony recreated from save data
- [ ] Buildings instantiated correctly
- [ ] Resources restored
- [ ] Population restored
- [ ] Game state matches pre-save state

---

## 12. Edge Cases

### Resource Scarcity
- [ ] Buildings handle negative resources gracefully
- [ ] Production stops if inputs unavailable
- [ ] UI shows warnings for insufficient resources

### Building Limits
- [ ] Cannot place unlimited buildings (space constraints)
- [ ] Cannot upgrade beyond max level (4)
- [ ] Cannot place buildings outside colony range

### Population Edge Cases
- [ ] Zero population handled correctly
- [ ] High population (1000+) handled correctly
- [ ] Negative population prevented

### Turn 0 Behavior
- [ ] New colonies work correctly on turn 0
- [ ] Resources don't become negative immediately
- [ ] Buildings in NEW state don't produce yet

---

## 13. Performance

- [ ] Loading game with multiple colonies is fast
- [ ] Turn processing completes quickly
- [ ] UI updates are responsive
- [ ] No memory leaks over extended play

---

## 14. Integration Points (Future Systems)

### Trading (Upcoming)
- [ ] Colony resources can be traded
- [ ] Trade routes affect resource flow
- [ ] Trade UI can access colony data

### Diplomacy (Upcoming)
- [ ] Colonies visible to diplomacy system
- [ ] NPC colonies tracked separately
- [ ] Colony ownership clear

### Combat (Existing)
- [ ] Fort building affects combat
- [ ] Military units can be trained from colonies
- [ ] Colony can be attacked/captured

---

## Test Scenarios to Run

### Scenario 1: Early Game Colony
1. Found new colony with settler
2. Build 1 farm
3. Advance 10 turns
4. Verify population grew
5. Verify crops produced

### Scenario 2: Production Chain
1. Load mid-game save
2. Build: 3 Farms → 2 Mills
3. Advance 5 turns
4. Verify crops → goods conversion
5. Check resource flow

### Scenario 3: Resource Stress
1. Load resource-stress save
2. Try to build with insufficient resources
3. Verify blocked
4. Advance turns until resources available
5. Verify building succeeds

### Scenario 4: Building Upgrades
1. Build level 1 farm
2. Upgrade to level 2
3. Upgrade to level 3
4. Upgrade to level 4
5. Verify cannot upgrade further
6. Verify production increased each level

### Scenario 5: Save/Load
1. Create complex colony (multiple buildings, population, resources)
2. Save game
3. Exit and reload
4. Verify all data matches

---

## Automated Test Coverage

Run `test/colony_test_menu.tscn` to verify:
- ✅ Building definitions loaded
- ✅ Resource transactions work
- ✅ Building cost scaling
- ✅ Tile placement logic
- ✅ Population growth formula
- ✅ Production calculations
- ✅ Specialization bonuses
- ✅ Labor distribution

---

## Sign-Off

When all items are checked and all scenarios pass, colony management is ready for trading/diplomacy integration.

**Tested by:** _________________
**Date:** _________________
**Status:** [ ] READY [ ] NEEDS WORK
