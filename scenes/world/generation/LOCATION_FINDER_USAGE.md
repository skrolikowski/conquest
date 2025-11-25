# LocationFinder Usage Guide

The `LocationFinder` class provides optimal location-finding algorithms for colony centers and specific building types.

---

## Quick Start

```gdscript
# Get reference to WorldGen
var world_gen: WorldGen = Def.get_world_map()

# Create LocationFinder instance
var location_finder: LocationFinder = LocationFinder.new(world_gen)

# Find optimal colony location
var colony_tile: Vector2i = location_finder.find_optimal_colony_location()
var colony_pos: Vector2 = world_gen.get_map_to_local_position(colony_tile)
```

---

## Finding Colony Locations

### Basic Usage

```gdscript
var location_finder: LocationFinder = LocationFinder.new(world_gen)
var colony_tile: Vector2i = location_finder.find_optimal_colony_location()
```

### Requirements

The colony finder ensures:
1. **Colony center on land** (not shore/water)
2. **2x2 footprint** fits entirely on land tiles
3. **At least 50% buildable land** within build_radius
4. **At least one shore/river tile** in build_radius for dock placement
5. **Balanced terrain modifiers** preferred

### Scoring System

Locations are scored based on:
- **Ocean/river access** (200 points) - Top priority
- **Direct ocean neighbors** (50 points each)
- **River tiles** (150 points)
- **Terrain modifiers** (weighted: farm 1.5x, mine 1.0x, mill 1.0x)
- **Balanced resources** (60 points if min/max diff < 50)
- **Biome bonuses** (grass 30, forest 20, swamp 10)

### Randomization

The finder doesn't always pick the highest-scored location:
- Selects from **top 20%** of candidates
- Uses **weighted random selection** (higher score = higher probability)
- Ensures variety across multiple colonies

---

## Finding Building Locations

### Farm Location

```gdscript
var colony: CenterBuilding = player.cm.get_colonies()[0]
var build_radius: float = GameData.get_building_stat(Term.BuildingType.CENTER, colony.level).build_radius
var build_radius_pixels: float = build_radius * Preload.C.TILE_SIZE.x

var farm_tile: Vector2i = location_finder.find_optimal_farm_location(
    colony.position,
    build_radius_pixels
)
```

**Prioritizes:**
- High farm terrain modifier (×2.0)
- Grass biome (+50 points)
- River access (+30 points)

### Mine Location

```gdscript
var mine_tile: Vector2i = location_finder.find_optimal_mine_location(
    colony.position,
    build_radius_pixels,
    Term.BuildingType.METAL_MINE  # or GOLD_MINE
)
```

**Prioritizes:**
- High mine terrain modifier (×2.0)
- Mountain biome (+80 points) - mines can be built on mountains
- Land tiles only (water excluded)

### Mill Location

```gdscript
var mill_tile: Vector2i = location_finder.find_optimal_mill_location(
    colony.position,
    build_radius_pixels
)
```

**Prioritizes:**
- High mill terrain modifier (×2.0)
- Forest biome (+50 points)
- River access (+40 points) - water power

### Dock Location

```gdscript
var dock_tile: Vector2i = location_finder.find_optimal_dock_location(
    colony.position,
    build_radius_pixels
)
```

**Prioritizes:**
- Ocean access (+100 points)
- River tiles (+50 points)
- Adjacent ocean tiles (+20 points each)

**Note:** Docks **must** be on shore or river tiles.

---

## Advanced Usage

### Custom Scoring

You can create your own location finder by extending the class:

```gdscript
class_name MyLocationFinder
extends LocationFinder

func find_optimal_fort_location(colony_position: Vector2, build_radius_pixels: float) -> Vector2i:
    var tiles_in_radius: Array[Vector2i] = world_gen.get_tiles_in_radius(colony_position, build_radius_pixels)
    var scored_candidates: Array[Dictionary] = []

    for tile: Vector2i in tiles_in_radius:
        var tile_data: TileCustomData = world_gen.tile_custom_data[tile]

        # Must be land, mountains preferred
        if not world_gen.is_land_tile(tile):
            continue

        var score: float = 0.0

        # Prefer high elevation (mountains)
        if tile_data.biome == WorldGen.TileCategory.MOUNTAIN:
            score += 100.0

        # Prefer positions at edge of build_radius
        var distance: float = colony_position.distance_to(world_gen.get_map_to_local_position(tile))
        if distance > build_radius_pixels * 0.7:
            score += 50.0

        if score > 0:
            scored_candidates.append({"tile": tile, "score": score})

    if scored_candidates.is_empty():
        return Vector2i.ZERO

    scored_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return a.score > b.score
    )

    return _select_random_top_candidate(scored_candidates, 0.3)
```

### Tuning Randomization

The `_select_random_top_candidate()` method accepts a `top_percent` parameter:

```gdscript
# More variety (top 30%)
return _select_random_top_candidate(scored_candidates, 0.3)

# Less variety (top 10%)
return _select_random_top_candidate(scored_candidates, 0.1)

# High variety (top 50%)
return _select_random_top_candidate(scored_candidates, 0.5)
```

---

## Integration with Test Scenarios

### Example from generate_test_scenario.gd

```gdscript
func _create_colony_at_optimal_location() -> CenterBuilding:
    var world_gen: WorldGen = Def.get_world_map()
    var location_finder: LocationFinder = LocationFinder.new(world_gen)

    # Find optimal location
    var optimal_tile: Vector2i = location_finder.find_optimal_colony_location()
    var colony_pos: Vector2 = world_gen.get_map_to_local_position(optimal_tile)

    # Create settler with resources
    var settler: UnitStats = UnitStats.New_Unit(Term.UnitType.SETTLER, 1)
    settler.resources[Term.ResourceType.WOOD] = 100
    settler.resources[Term.ResourceType.GOLD] = 100

    # Create and settle
    var settler_unit: SettlerUnit = player.create_unit(settler, colony_pos) as SettlerUnit
    settler_unit.settle()
    await get_tree().process_frame

    # Return colony
    return player.cm.get_colonies()[0] as CenterBuilding
```

---

## Performance Considerations

### Caching LocationFinder

If finding multiple building locations for the same colony:

```gdscript
var location_finder: LocationFinder = LocationFinder.new(world_gen)
var build_radius_pixels: float = GameData.get_building_stat(Term.BuildingType.CENTER, colony.level).build_radius * Preload.C.TILE_SIZE.x

# Find multiple locations with same instance
var farm_tile: Vector2i = location_finder.find_optimal_farm_location(colony.position, build_radius_pixels)
var mill_tile: Vector2i = location_finder.find_optimal_mill_location(colony.position, build_radius_pixels)
var mine_tile: Vector2i = location_finder.find_optimal_mine_location(colony.position, build_radius_pixels)
```

### Pre-filtering Tiles

For large maps, consider pre-filtering tiles before scoring:

```gdscript
# Example: Only check tiles in specific quadrant
var tiles_in_radius: Array[Vector2i] = world_gen.get_tiles_in_radius(colony.position, build_radius_pixels)
var filtered_tiles: Array[Vector2i] = []

for tile: Vector2i in tiles_in_radius:
    # Only northeast quadrant
    if tile.x > colony_tile.x and tile.y < colony_tile.y:
        filtered_tiles.append(tile)

# Then score only filtered tiles
```

---

## Troubleshooting

### No Valid Location Found

If `find_optimal_*_location()` returns `Vector2i.ZERO`:

```gdscript
var farm_tile: Vector2i = location_finder.find_optimal_farm_location(colony.position, build_radius_pixels)

if farm_tile == Vector2i.ZERO:
    print("Warning: No valid farm location found")
    # Fallback: use any land tile in radius
    var tiles: Array[Vector2i] = world_gen.get_tiles_in_radius(colony.position, build_radius_pixels)
    for tile: Vector2i in tiles:
        if world_gen.is_land_tile(tile):
            farm_tile = tile
            break
```

### Same Location Every Time

If getting the same location despite randomization:
- Check that `randf()` is being called (it should be)
- Verify multiple candidates exist with similar scores
- Increase `top_percent` parameter for more variety

### Colony on Water/Shore

If colony is being placed incorrectly:
- Check `is_land_tile()` implementation
- Verify `_validate_center_building_footprint()` logic
- Review candidate filtering in first pass

---

## See Also

- [world_gen.gd](world_gen.gd) - Map generation and tile data
- [building_placement_controller.gd](../../player/colony/building_placement_controller.gd) - Building placement workflow
- [test/tools/generate_test_scenario.gd](../../../test/tools/generate_test_scenario.gd) - Usage examples
