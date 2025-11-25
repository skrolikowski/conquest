# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

# Conquest Game Architecture

A turn-based strategy game built in Godot 4.4 that simulates colonization, city building, resource management, and military combat. The architecture follows a modular design with clear separation between world management, player systems, building/unit mechanics, and UI.

## High-Level Architecture Overview

```
WorldManager (Root Scene)
├── WorldSelector (Input/Cursor Management)
├── WorldCamera (Camera/View Management)
├── WorldGen (Map Generation & Terrain)
├── WorldCanvas (UI Layer)
└── PlayerManager (Turn Management)
    ├── Player (Player State & Units)
    │   ├── ColonyManager (Colony/Building Management)
    │   ├── UnitList (All Player Units)
    │   ├── Bank (Resource Management)
    │   └── Trade System
    └── NPC[] (AI Players - Disabled)
```

## Core Systems

### 1. Autoload/Singleton Systems

The game uses Godot autoloads (singletons) for global state and shared resources:

#### **Def (DefinitionsRef)** - Game Metadata & Configuration
- **Location**: `autoload/definitions.gd`
- **Responsibilities**:
  - Central registry for all game definitions (buildings, units, resources)
  - Loads JSON metadata from `assets/metadata/buildings.json` and `units.json`
  - Manages scene references for buildings and units
  - Provides helper methods for type conversions (BuildingType, UnitType, ResourceType)
  - Stores game configuration constants (tile size, FOG_OF_WAR_ENABLED, etc.)
  - Implements sorting logic for buildings and combat units
- **Key Methods**:
  - `get_building_cost()`, `get_building_make()`, `get_building_need()` - building economics
  - `get_unit_cost()`, `get_unit_stat()` - unit definitions
  - `get_world_canvas()`, `get_world_map()` - global node getters
  - Conversion methods: `_convert_to_building_type()`, `_convert_to_unit_type()`, etc.

#### **Preload** - Scene Asset Management
- **Location**: `autoload/preloads.gd`
- **Responsibilities**:
  - Pre-caches all PackedScenes for instant instantiation
  - Organized into categories: player, NPC, buildings, units, combat
  - Stores UI scene references for building/unit interfaces
  - Loads combat animation resources
- **Pattern**: Static references to prevent runtime loading delays

#### **Persistence** - Save/Load System
- **Location**: `autoload/persistence.gd`
- **Responsibilities**:
  - Manages game save/load operations using ConfigFile
  - Orchestrates serialization across all game systems
  - Tracks game state (new_game flag)
  - Saves to `user://conquest_save_01.ini`
- **Data Sections**: GAME, CAMERA, WORLD, PLAYER
- **Flow**: Each system implements `on_save_data()` and `on_load_data()` methods

#### **Print** - Debug Logging
- **Location**: `autoload/print.gd`
- **Responsibilities**: Centralized logging system

#### **Popups** - Global Popup Management
- **Location**: `autoload/popups.gd`
- **Responsibilities**: Manages shared popup dialogs

#### **NameGenerator & NameMaker** - NPC Name Generation
- **Location**: `autoload/name_generator.gd` and `scripts/name_gen.gd`
- **Responsibilities**: Procedural name generation for NPCs and units

---

### 2. Main Game Flow & World Management

#### **WorldManager** - Game Orchestrator
- **Location**: `scenes/world_manager.gd`
- **Parent Scene**: `scenes/world_manager.tscn`
- **Responsibilities**:
  - Main game entry point (loaded at startup)
  - Orchestrates game initialization and turn cycle
  - Manages cursor/tile selection and focus
  - Coordinates between all major systems
  - Handles game state persistence
- **Key Properties**:
  - `focus_tile`: Currently selected map tile
  - `focus_node`: Currently selected game object (unit, building, etc.)
  - `turn_number`: Current game turn
- **Signal Connections**:
  - Connects to `WorldSelector.cursor_updated` for tile selection
  - Connects to `WorldGen.map_loaded` for map initialization
  - Connects to `WorldCanvas.end_turn` for turn progression
- **Turn Flow**:
  1. `begin_turn()` - Update UI, call `player_manager.begin_turn()`
  2. `end_turn()` - Call `player_manager.end_turn()`, loop back to begin_turn()
  3. Each turn increments `turn_number`

#### **WorldSelector** - Input & Cursor Management
- **Responsibilities**: Processes mouse/keyboard input for tile selection
- **Emits**: `cursor_updated` signal with world position
- **Used by**: WorldManager to track focused tile

#### **WorldCamera** - View Management
- **Responsibilities**: Camera control, zoom, pan
- **Supports**: Reset, zoom in/out, position tracking

#### **WorldCanvas** - UI Overlay
- **Location**: `ui/world_canvas.gd`
- **Responsibilities**:
  - Main HUD layer above game world
  - Manages UI panel stack (current_ui, current_sub_ui arrays)
  - Turn number display
  - Tile/object status display
  - Coordinates popup dialogs and building UIs
  - Emits `end_turn` signal
- **UI Management Pattern**:
  - `current_ui`: Primary open panel
  - `locking_ui`: Modal dialog that blocks other inputs
  - `current_sub_ui[]`: Array of sub-panels (stacking)
  - `close_all_ui()`: Clears all open panels

---

### 3. Map & World Generation System

#### **WorldGen** - Procedural Map Generation
- **Location**: `scenes/world/generation/world_gen.gd`
- **Parent**: `scenes/world_manager.tscn`
- **Uses**: Gaea noise generation addon for terrain
- **Responsibilities**:
  - Procedural terrain generation using Perlin noise
  - River generation
  - Terrain modifier calculation (industry bonuses)
  - Fog of war generation and updates
  - Tile categorization (ocean, land, grass, forest, mountain, etc.)
  - Pathfinding navigation layer setup
- **Key Subsystems**:
  - `NoiseGenerator`: Perlin noise-based height map
  - `TilemapGaeaRenderer`: Renders noise data to TileMap
  - `MountainRange[]`: Pre-generated mountain ranges
  - `River[]`: Generated river systems
- **Data Storage**:
  - `tile_heights`: Dictionary of Vector2i -> float elevation
  - `tile_custom_data`: Custom data per tile
  - `terrain_modifier`: Industry production modifiers per tile
  - `artifact_modifier`: Special tile modifiers
- **Signals**: `map_loaded` - emitted when map generation complete
- **Game Persistence**: Implements `on_save_data()` / `on_load_data()`

#### **LocationFinder** - Optimal Building Placement
- **Location**: `scenes/world/generation/location_finder.gd`
- **Type**: RefCounted (utility class)
- **Responsibilities**:
  - Find optimal locations for colony centers
  - Find optimal locations for specific building types (farms, mines, mills, docks)
  - Score potential locations based on terrain modifiers and biome bonuses
  - Apply weighted randomness to avoid always picking the same location
- **Key Methods**:
  - `find_optimal_colony_location()`: Find best colony location with ocean access
  - `find_optimal_farm_location()`: Find high farm modifier tiles
  - `find_optimal_mine_location()`: Find high mine modifier tiles (mountains OK)
  - `find_optimal_mill_location()`: Find high mill modifier tiles (rivers preferred)
  - `find_optimal_dock_location()`: Find shore/river tiles with ocean access
- **Randomization Strategy**:
  - Scores all candidates
  - Sorts by score (highest first)
  - Selects randomly from top 20-30% using weighted probability
  - Higher scores have higher probability, but not guaranteed
- **Colony Location Requirements**:
  1. Colony center on **land tile** (not shore/water)
  2. 2x2 footprint fits on land
  3. At least 50% buildable land within build_radius
  4. At least one shore/river tile in build_radius for dock
  5. Balanced terrain modifiers preferred

#### **TileMap Structure**
- **Land Layer**: Main terrain tilemap
- **Cursor Layer**: Shows selected tile
- **Fog of War Layer**: Reveals/hides terrain based on unit vision

#### **Tile Categories** (from height values)
```
Height <= -0.01    : Ocean (ships only)
-0.30 to -0.01     : Coast (special zone)
> -0.01 to 0.80    : Land (can place buildings/units)
0.80+              : Mountains (high elevation)
```

---

### 4. Player & Unit System

#### **Player** - Player State Container
- **Location**: `scenes/player/player.gd`
- **Parent**: PlayerManager
- **Responsibilities**:
  - Manages all player units
  - Manages all player colonies (via ColonyManager)
  - Manages player resources (via Bank)
  - Handles unit creation and disbanding
  - Handles fog of war revelation
  - Coordinates turn-based colony production
- **Key Properties**:
  - `units[]`: Array of all player units
  - `cm` (ColonyManager): Colony and building management
  - `trades[]`: Trade agreements
- **Unit Creation Flow**:
  1. Create UnitStats with type and level
  2. Call `create_unit(stat, position)`
  3. Instantiate scene from Def.get_unit_scene_by_type()
  4. Add to UnitList (child node)
- **Game Persistence**: Serializes all units and colonies

#### **ColonyManager** - Colony & Building Management
- **Location**: `scenes/player/colony_manager.gd`
- **Responsibilities**:
  - Manages array of player colonies (CenterBuildings)
  - Handles colony founding (from Settler units)
  - Manages building placement and building tiles
  - Coordinates building manager per colony
- **Key Properties**:
  - `colonies[]`: Array of CenterBuildings
  - `placing_colony`: Temporary colony during placement preview
  - `placing_tiles`: Dictionary of tiles for placement visualization
- **Colony Founding Flow**:
  1. Settler unit calls `found_colony(tile, position, stats)`
  2. ColonyManager creates CenterBuilding and adds to colony list
  3. Resources transferred from settler to colony
  4. Undo available if building not completed

#### **Unit System Hierarchy**
```
Unit (Base Class - scenes/units/unit.gd)
├── LeaderUnit - Military commander, can lead armies
├── SettlerUnit - Founds colonies
├── ExplorerUnit - Explores map (no combat)
├── ShipUnit - Carrier unit, moves on water
└── CarrierUnit - Generic unit for combat system
    ├── UnitStats - Data container for stats
    └── UnitMovement - Movement capabilities
```

- **Unit Stats** (UnitStats class):
  - `unit_type`: Type identifier
  - `level`: Unit strength level (1-5)
  - `health`: Current unit health
  - `player`: Owner reference
  - `attached_units[]`: Units being carried (ships only)
  - Resources needed/produced
  - Combat statistics

- **Unit Categories**:
  - `SHIP`: Water-based carriers
  - `MILITARY`: Land-based combat units
  - `NONE`: Settlers, explorers (non-combat)

- **Unit Movement**:
  - `EXPLORER`: Can only move to land
  - `SHIP`: Can only move on water
  - `OTHER`: Default land movement

#### **Bank & Resource Management**
- **Location**: `scenes/player/bank.gd`
- **Manages**: Resource inventory and transactions
- **Key Methods**:
  - `can_afford_this_turn()`: Check if resources available
  - `add_resources()`: Add resource transaction
  - `remove_resources()`: Consume resources

---

### 5. Building System

#### **Building Base Class**
- **Location**: `scenes/buildings/building.gd`
- **Parent**: Area2D (spatial with collision)
- **Responsibilities**:
  - Base class for all building types
  - Selection/highlighting effects (pulse animation)
  - Tile occupancy calculations (small 1x1, large 2x2)
  - Status information display
- **Key Properties**:
  - `building_type`: Type identifier from Term.BuildingType
  - `building_size`: SMALL (1x1) or LARGE (2x2)
  - `level`: Building level (1-4 max)
  - `building_state`: NEW, ACTIVE, UPGRADE, SELL
  - `colony`: Parent CenterBuilding
  - `player`: Owner Player
- **Methods**:
  - `get_tiles()`: Returns array of occupied map tiles
  - `get_cost()`, `get_make()`, `get_need()`: Economic definitions
  - `can_upgrade()`: Check upgrade possibility
  - `get_status_information()`: Returns UI status text

#### **CenterBuilding** - Colony Center
- **Location**: `scenes/buildings/center_building.gd`
- **Extends**: Building
- **Responsibilities**:
  - Represents the core of a player colony
  - Manages all buildings in the colony (via BuildingManager)
  - Manages population and growth
  - Manages production and resource flow
  - Manages labor distribution
  - Manages unit training (military units)
- **Key Systems**:
  - `bm` (BuildingManager): All buildings in colony
  - `bank`: Colony resource pool
  - `population`: Current population
  - `population_growth`: Growth mechanics
  - `production_system`: Calculate building output

#### **Building Types**
- **Production**: Farm, Mill, Mine (Metal/Gold)
- **Military**: Fort, War College
- **Social**: Housing, Church, Tavern
- **Trade**: Commerce, Dock
- **Government**: Colony Center

#### **Building Manager** (scenes/player/building_manager.gd)
- Manages buildings within a single colony
- Handles building creation/placement
- Tracks building tiles and prevents overlaps
- Manages building upgrades and demolition
- Calculates colony-wide production bonuses

---

### 6. Combat System

#### **Combat** - Battle Resolution
- **Location**: `combat/combat.gd`
- **Responsibilities**:
  - Orchestrates turn-based combat between military units
  - Manages combat grid (6x6 battlefield)
  - Manages turn order and unit actions
  - Calculates damage and hits
  - Updates unit health
- **Combat Unit**: `combat/combat_unit.gd`
  - Represents a unit in combat
  - Tracks health, position, animations
  - Can move and attack adjacent squares
- **Combat Group**: `combat/combat_group.gd`
  - Groups multiple combat units for tactics
  - Manages group-level actions
- **Combat Squad Positions**:
  - Defender Reserve Row: Vector2i(5, 0)
  - Attacker Reserve Row: Vector2i(0, 0)
  - Flag Squares mark strategic positions
- **Combat Animations**: Resources in `combat/resources/` for unit types

#### **Combat Triggers**
- Leader units can attack adjacent cities/units
- Combat initiated from leader/unit UI
- Results update unit health and may disband units

---

### 7. UI System Architecture

#### **UI Organization**
```
ui/
├── world_canvas.gd - Main HUD layer
├── player/ - Player interaction UIs
│   ├── ui_found_colony.tscn - Colony founding dialog
│   ├── ui_build_building.tscn - Building placement
│   ├── ui_building_list.tscn - Buildings in colony
│   └── ui_population_detail.tscn - Population management
├── buildings/ - Building-specific UIs
│   ├── ui_center_building.tscn
│   ├── ui_farm_building.tscn
│   ├── ui_fort_building.tscn
│   └── [etc]
├── units/ - Unit-specific UIs
│   ├── ui_settler_unit.tscn
│   ├── ui_leader_unit.tscn
│   └── [etc]
├── trade/ - Trade system UIs
├── npc/ - NPC interaction UIs
└── menus/ - Main menu systems
```

#### **UI Panel Pattern**
- All player-facing UIs inherit from PanelContainer
- WorldCanvas manages panel stack
- Modal (locking) UIs prevent other interactions
- Sub-UIs can stack for nested workflows
- Close buttons route through WorldCanvas.close_all_ui()

#### **Building UI Examples**
- Click building -> Load UI scene from Def.get_ui_building_scene_by_type()
- UI displays building stats, production, upgrades
- Buttons trigger building actions through building's methods
- Status updates refresh through signals or manual calls

---

### 8. Data Flow & Persistence

#### **Save/Load Pipeline**
```
Game Initiated
└── WorldManager._ready()
    └── Persistence.load_game() OR new_game()
        ├── WorldGen.on_load_data() [map terrain]
        ├── WorldCamera.on_load_data() [view position]
        ├── Player.on_load_data() [colonies, units]
        └── PlayerManager.on_load_data() [diplomacy, NPCs]
```

#### **Turn Cycle Data Flow**
```
Player clicks End Turn
└── WorldCanvas.end_turn signal
    └── WorldManager._on_end_turn()
        ├── Increments turn_number
        ├── Calls player_manager.end_turn() [NPC turns]
        ├── Calls player_manager.begin_turn() [Player updates]
        │   ├── player.begin_turn()
        │   │   ├── Each colony.begin_turn() [process production]
        │   │   └── Each unit.begin_turn() [restore movement]
        │   └── player.reveal_fog_of_war()
        └── Updates UI (turn counter, etc.)
```

#### **Resource Transaction System**
- **Transaction** class: Encapsulates resource changes
- Used for: building costs, unit costs, production, trade
- Each transaction tracks amounts per ResourceType
- Can be cloned, queried, accumulated

---

### 9. Game Patterns & Conventions

#### **Signal-Driven Communication**
- WorldManager -> WorldCamera, WorldCanvas: Camera zoom, UI updates
- WorldGen -> WorldManager: Map loaded event
- Player units -> UI: Status changes
- Building state changes -> UI refresh

#### **Scene Tree Groups**
Used for quick node lookup:
- `"world_canvas"` - WorldCanvas node
- `"world"` - WorldManager node

#### **Dependency Injection**
Buildings and units receive references to:
- Parent colony (for shared resources)
- Player (for unit commands)
- World systems (via Def accessors)

#### **State Machines**
- **BuildingState**: NEW, ACTIVE, UPGRADE, SELL
- **UnitState**: IDLE, DISBAND, ATTACK, EXPLORE
- **Unit Movement Types**: EXPLORER, SHIP, OTHER

#### **Configuration Constants** (in Def)
```
TILE_SIZE = Vector2i(48, 48)
FOG_OF_WAR_ENABLED = false
CONFIRM_END_TURN_ENABLED = false
WEALTH_MODE_ENABLED = true
```

---

### 10. Key Directories & File Organization

```
Conquest/
├── autoload/                 # Singleton systems
│   ├── definitions.gd        # Game metadata & config
│   ├── preloads.gd           # Scene asset cache
│   ├── persistence.gd        # Save/load system
│   ├── print.gd              # Debug logging
│   ├── popups.gd             # Popup management
│   └── name_generator.gd     # NPC name generation
├── scenes/                   # Main game scenes
│   ├── world_manager.gd      # Game orchestrator
│   ├── world_manager.tscn    # Root scene
│   ├── world_map.gd          # Legacy map system
│   ├── world_selector.gd     # Input/cursor
│   ├── map/                  # Map generation
│   │   ├── world_gen.gd      # Procedural terrain
│   │   ├── world_gen.tscn
│   │   ├── river.gd          # River generation
│   │   ├── mountain_range.gd # Mountain generation
│   │   └── tile_custom_data.gd
│   ├── player/               # Player systems
│   │   ├── player.gd         # Player state
│   │   ├── colony_manager.gd # Colony management
│   │   ├── building_manager.gd # Buildings in colony
│   │   ├── bank.gd           # Resource management
│   │   └── trade.gd          # Trade system
│   ├── units/                # Unit types
│   │   ├── unit.gd           # Base unit class
│   │   ├── leader_unit.gd    # Military commander
│   │   ├── settler_unit.gd   # Colony founder
│   │   ├── explorer_unit.gd  # Scout unit
│   │   ├── ship_unit.gd      # Water transport
│   │   └── carrier_unit.gd   # Unit for combat
│   ├── buildings/            # Building types
│   │   ├── building.gd       # Base building
│   │   ├── center_building.gd # Colony center
│   │   ├── farm_building.gd
│   │   ├── church_building.gd
│   │   └── [etc]
│   ├── npc/                  # NPC/AI players
│   └── camera/               # Camera system
├── combat/                   # Combat system
│   ├── combat.gd             # Battle orchestrator
│   ├── combat_unit.gd        # Unit in combat
│   ├── combat_group.gd       # Unit grouping
│   ├── combat_square.gd      # Battle grid squares
│   ├── combat_queue.gd       # Turn order
│   ├── resources/            # Animation data
│   └── ui/                   # Combat UI
├── ui/                       # User interface
│   ├── world_canvas.gd       # Main HUD
│   ├── player/               # Player interaction
│   ├── buildings/            # Building UIs
│   ├── units/                # Unit UIs
│   ├── trade/                # Trade UI
│   ├── npc/                  # NPC diplomacy
│   └── menus/                # Game menus
├── scripts/                  # Utility scripts
│   ├── term.gd               # Enum definitions
│   ├── transaction.gd        # Resource transactions
│   ├── diplomacy.gd          # NPC diplomacy
│   ├── name_generator.gd     # Name generation
│   └── weighted_table.gd     # Probability table
├── assets/                   # Game resources
│   ├── metadata/             # JSON definitions
│   │   ├── buildings.json    # Building stats
│   │   └── units.json        # Unit stats
│   ├── sprites/              # 2D graphics
│   ├── tileset/              # Tile definitions
│   └── sounds/
├── addons/                   # Third-party plugins
│   └── gaea/                 # Procedural generation
├── exports/                  # Export settings
└── project.godot             # Project configuration
```

---

### 11. Asset & Configuration Files

#### **JSON Metadata** (`assets/metadata/`)
- **buildings.json**: Defines for each building:
  - `cost[]`: Resource cost per level
  - `make[]`: Resources produced per level
  - `need[]`: Resources consumed per level
  - `labor_demand[]`: Population required per level
  - `stat[]`: Special attributes per level

- **units.json**: Defines for each unit:
  - `cost[]`: Resource cost per level
  - `need[]`: Resources consumed per level
  - `stat[]`: Combat/movement stats per level

#### **Tile Sets** (`map/`)
- `tile_map.tres`: TileSet resource with:
  - Terrain sets (grass, forest, mountain, etc.)
  - Physics layers
  - Navigation layers
- `noise_gen_settings.tres`: Perlin noise configuration

---

### 12. Important Design Notes

#### **NPC System** (Mostly Stubbed)
- PlayerManager has `npcs[]` array
- NPC class exists but not fully implemented
- Diplomacy system exists but minimal
- NPC turns processed in `player_manager.end_turn()`

#### **Fog of War** (Currently Disabled)
- FOG_OF_WAR_ENABLED = false in Def
- Infrastructure exists for implementation
- Units have `fog_reveal` stat for vision range

#### **Building Specialization Bonuses**
- Based on building-level-grid-squares
- Blocks of 20 tiles with diminishing returns
- Asymptotically approach 40% max bonus
- Calculated per building type (farm, mill, mine)
- Commerce doesn't gain production bonuses

#### **Population Growth**
- Base rate: 8% of current population + 10 per Church level
- Crops consumption: 1 crop feeds 100 population (0.01 rate)
- Affects colony production and military unit training

#### **Turn Costs**
- Units and buildings have per-turn resource costs
- Checked in `Player.begin_turn()` on turn 0+
- Buildings transition states during turns (NEW -> ACTIVE, UPGRADE processes)

---

## Data Model Examples

### Building Definition (from JSON)
```json
{
  "farm": {
    "cost": [{"wood": 10, "crops": 5}],
    "make": [{"crops": 50}],
    "need": [{"crops": 10}],
    "labor_demand": [20],
    "stat": [{"efficiency": 1.0}]
  }
}
```

### Unit Stat Object
```gdscript
UnitStats {
  unit_type: Term.UnitType
  level: int (1-5)
  health: int
  player: Player
  attached_units[]: UnitStats (for carriers)
  resources: {gold: 0, metal: 0, ...}
}
```

### Building State
```gdscript
Building {
  building_type: Term.BuildingType
  building_size: Term.BuildingSize
  level: int (1-4)
  building_state: Term.BuildingState (NEW, ACTIVE, UPGRADE, SELL)
  colony: CenterBuilding
  player: Player
}
```

---

## Coding Standards & Best Practices

### **Static Typing (REQUIRED)**

This project uses **strict static typing** throughout all GDScript code. The project is configured with:
```gdscript
# project.godot
[debug]
gdscript/warnings/untyped_declaration=2  # Error level
```

#### **Type Annotation Requirements**

**Variables:**
```gdscript
// ✅ CORRECT - Always type variables
var health: int = 100
var player_name: String = "Alice"
var position: Vector2i = Vector2i(0, 0)
var transaction: Transaction = Transaction.new()
var buildings: Array[Building] = []

// ❌ WRONG - No type inference
var health = 100
var player_name = "Alice"
var position = Vector2i(0, 0)
```

**Function Parameters:**
```gdscript
// ✅ CORRECT - Type all parameters and returns
func calculate_damage(attacker: Unit, defender: Unit) -> int:
    return attacker.strength - defender.defense

func get_building_cost(building_type: Term.BuildingType, level: int) -> Transaction:
    return costs[building_type][level]

// ❌ WRONG - Missing types
func calculate_damage(attacker, defender):
    return attacker.strength - defender.defense
```

**Arrays with Type Hints:**
```gdscript
// ✅ CORRECT - Typed arrays
var units: Array[Unit] = []
var colonies: Array[CenterBuilding] = []
var resource_types: Array[Term.ResourceType] = [
    Term.ResourceType.GOLD,
    Term.ResourceType.WOOD,
]

// ❌ WRONG - Untyped arrays
var units = []
var colonies = []
```

**Loop Variables:**
```gdscript
// ✅ CORRECT - Type loop variables
for building: Building in buildings:
    building.update()

for i: int in range(10):
    process_turn(i)

for resource_type: Term.ResourceType in Term.ResourceType.values():
    print(resource_type)

// ❌ WRONG - Untyped loop variables
for building in buildings:
    building.update()
```

**Constants:**
```gdscript
// ✅ CORRECT - Type constants
const MAX_LEVEL: int = 4
const TILE_SIZE: Vector2i = Vector2i(48, 48)
const DEFAULT_POPULATION: int = 100

// ❌ WRONG - Untyped constants
const MAX_LEVEL = 4
const TILE_SIZE = Vector2i(48, 48)
```

**Null/Optional Types:**
```gdscript
// ✅ CORRECT - Can be null (no initializer)
var colony: CenterBuilding  # Can be null
var transaction: Transaction  # Can be null

// ✅ CORRECT - Cannot be null (initialized)
var colony: CenterBuilding = null  # Explicitly null initially
var transaction: Transaction = Transaction.new()  # Always valid

// Use null checks when needed
if colony != null:
    colony.process_turn()
```

#### **When Types Can Be Inferred**

Only in these specific cases can you omit explicit types:

**@onready variables (type inferred from node path):**
```gdscript
// ✅ ACCEPTABLE - Type inferred from scene tree
@onready var world_camera := %WorldCamera as WorldCamera
@onready var world_gen := %WorldGen as WorldGen
@onready var player_label := $PlayerLabel as Label

// Note: Still use 'as Type' for clarity
```

**Enum values in match statements:**
```gdscript
// ✅ ACCEPTABLE - Type known from context
match building_state:
    Term.BuildingState.NEW:
        setup_building()
    Term.BuildingState.ACTIVE:
        process_production()
```

#### **Benefits of Static Typing**

1. **Compile-time error detection** - Catch bugs before runtime
2. **Better IDE autocomplete** - Full method/property suggestions
3. **Self-documenting code** - Types clarify intent
4. **Refactoring safety** - Changes propagate correctly
5. **Performance** - Minor optimizations from type knowledge

#### **Enforcement**

- **All new code MUST follow these standards**
- **All modified code SHOULD be updated to follow these standards**
- **Project will not merge code with type warnings**
- **CI/CD will reject untyped code**

---

### **Testing Standards**

#### **Unit Tests with GUT**
- All new features require unit tests
- Test files located in `test/unit/`
- Use GUT testing framework (installed in `addons/gut/`)
- Follow Arrange-Act-Assert pattern

#### **Memory Management in Tests**
**IMPORTANT:** All Node-based objects must be freed to prevent memory leaks.

```gdscript
// ✅ CORRECT - Use autofree() for Node objects
func test_transaction():
    var transaction: Transaction = autofree(Transaction.new())
    var cost: Transaction = autofree(GameData.get_building_cost(Term.BuildingType.FARM, 1))
    var cloned: Transaction = autofree(transaction.clone())

    # All objects auto-freed after test

// ❌ WRONG - Memory leaks (orphans)
func test_transaction():
    var transaction = Transaction.new()  # Orphan!
    var cost = GameData.get_building_cost(Term.BuildingType.FARM, 1)  # Orphan!
```

**When to use `autofree()`:**
- Any `Transaction.new()`
- Any `.clone()` operations
- Any `GameData.get_*()` calls that return Transactions
- Any Node-based object instantiation in tests

**See also:**
- [test/MEMORY_MANAGEMENT_GUIDE.md](test/MEMORY_MANAGEMENT_GUIDE.md)
- [test/AUTOFREE_CHEATSHEET.md](test/AUTOFREE_CHEATSHEET.md)

#### **Test Coverage Requirements**
- **Goal:** 0 orphans after all tests run
- **Check:** GUT panel shows `Orphans: 0`
- **Documentation:** All tests documented with docstrings

---

### **Code Style**

#### **Naming Conventions**
- **Classes:** PascalCase (`CenterBuilding`, `WorldManager`)
- **Variables:** snake_case (`building_type`, `current_turn`)
- **Constants:** SCREAMING_SNAKE_CASE (`MAX_LEVEL`, `TILE_SIZE`)
- **Private variables:** Prefix with `_` (`_internal_state`)
- **Signals:** snake_case (`cursor_updated`, `map_loaded`)

#### **File Organization**
- Group related functionality with `#region` tags
- Order: constants → exports → variables → lifecycle → public methods → private methods
- Use docstrings for classes and public methods

#### **Comments & Documentation**
```gdscript
## Class-level documentation
## Describes purpose and responsibilities
class_name MyClass extends Node

## Public method documentation
## Describes what the method does, parameters, and return value
func calculate_production(building: Building, bonus: float) -> int:
    # Inline comment explaining complex logic
    var base_production: int = building.get_base_production()
    return int(base_production * (1.0 + bonus))
```

---

### **Performance Guidelines**

- **Avoid excessive allocations** - Reuse objects where possible
- **Use object pooling** for frequently created/destroyed objects
- **Profile before optimizing** - Don't guess at bottlenecks
- **Prefer signals over polling** - Event-driven architecture

---

### **Git Commit Standards**

- **Descriptive commits** - Explain the "why", not just the "what"
- **Atomic commits** - One logical change per commit
- **Test before commit** - All tests must pass
- **Include co-author** when using Claude Code:
  ```
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

---

## Getting Started for Developers

1. **Main entry point**: `scenes/world_manager.tscn` - Start here
2. **Game flow**: Follow WorldManager.begin_turn() -> end_turn()
3. **Coding standards**: Review section above - **static typing required**
4. **Testing setup**: See [test/README.md](test/README.md) and [test/QUICKSTART.md](test/QUICKSTART.md)
5. **Adding features**:
   - New building type: Add to Term.BuildingType, define in buildings.json, create scene
   - New unit type: Add to Term.UnitType, define in units.json, create scene
   - New UI: Create panel in ui/, add to WorldCanvas, connect signals
   - Write unit tests in `test/unit/` for all new code
6. **Debugging**: Use Print singleton or GDScript print() statements
7. **Saving**: Ensure new systems implement on_save_data() and on_load_data()
8. **Running tests**:
   - Open GUT panel in Godot Editor (bottom panel)
   - Click "Run All" to execute all tests
   - Verify `Orphans: 0` (no memory leaks)

---

## Project Statistics
- Total GDScript files: 173
- Main autoloads: 7 singletons
- Building types: 12
- Unit types: 7
- Core scenes: ~50+ scene files
- Config: Godot 4.4, Canvas2D rendering
- **Static typing: Required** (warning level = error)
- **Test framework: GUT v9.3.0**

