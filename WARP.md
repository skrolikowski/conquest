# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**Conquest** is a turn-based strategy game built with **Godot 4.4** using GDScript. The game features colony management, unit movement, combat systems, and world generation with fog of war mechanics.

## Development Commands

### Running the Project
- **Open in Godot Editor**: Open `project.godot` in Godot 4.4+
- **Run Game**: Press F5 in Godot Editor or use the "Play" button
- **Run Specific Scene**: Press F6 to run currently opened scene

### Code Quality
The project has **strict type checking enabled**:
- `gdscript/warnings/untyped_declaration=2` (configured in project.godot)
- All GDScript should use static typing with type hints (`:` syntax)
- Use `class_name` declarations for exported classes

### Project Structure Commands
```bash
# Find all GDScript files
find . -name "*.gd" -type f

# Find all scene files
find . -name "*.tscn" -type f

# Search for class definitions
grep -r "class_name" --include="*.gd"
```

## Architecture Overview

### Core Game Loop

**WorldManager** (`scenes/world_manager.gd`) is the main game coordinator:
- Entry point: `res://scenes/world_manager.tscn` (configured in project.godot)
- Manages turn sequence via `begin_turn()` and `end_turn()`
- Coordinates between `PlayerManager`, `WorldGen` (map), `WorldCamera`, and `WorldCanvas` (UI)
- Handles cursor/tile selection and focus management

### Autoload Singletons

Six global singletons are auto-loaded (defined in project.godot):

1. **Def** (`autoload/definitions.tscn`) - Central definitions hub
   - Loads building/unit metadata from JSON files in `assets/metadata/`
   - Provides scene registry for buildings and units (`BuildingScenes`, `UnitScenes`)
   - Constants for tile size, combat grid positions, fog of war settings
   - Helper methods to access WorldManager, PlayerManager, WorldMap, etc.
   - Type conversion utilities for enums

2. **Preload** (`autoload/preloads.tscn`) - Scene preloading
   - Preloads all PackedScenes for buildings, units, combat, UI
   - Prevents runtime loading delays

3. **Persistence** (`autoload/persistence.gd`) - Save/Load system
   - Uses ConfigFile (.ini format) to save game state
   - Save path: `user://conquest_save_01.ini`
   - Sections: GAME, PLAYER, CAMERA, WORLD
   - Each game object implements `on_save_data()` and `on_load_data()` methods

4. **Popups** (`autoload/popups.tscn`) - UI popup manager

5. **Print** (`autoload/print.tscn`) - Debug printing utilities

6. **NameGenerator** (`autoload/name_generator.gd`) - Procedural name generation
   - Used alongside `NameMaker` and `FantasyNameGenerator` addon

### Entity Systems

#### Units (`scenes/units/`)
- Base class: **Unit** (extends Area2D)
- Specialized types: `LeaderUnit`, `SettlerUnit`, `ExplorerUnit`, `ShipUnit`, `CarrierUnit`
- **UnitStats** (`scenes/units/unit_stat.gd`) - Contains unit data (type, level, health, movement)
- Uses NavigationAgent2D for pathfinding
- Turn-based movement with move points system
- Fog of war reveal on movement

#### Buildings (`scenes/buildings/`)
- Base class: **Building** (extends Area2D)
- **CenterBuilding** - Colony headquarters (manages economy, construction, population)
- Specialized buildings: Farm, Mill, Fort, Dock, Church, Commerce, etc.
- Buildings consume/produce resources via **Transaction** system
- **BuildingManager** handles construction and placement
- Buildings have levels (1-4) and can be upgraded or demolished

#### Players (`scenes/player/`)
- **Player** - Manages units, colonies (via ColonyManager), and trades
- **ColonyManager** - Handles founding/managing colonies
- **Bank** - Resource and economy tracking per colony
- Turn-based: implements `begin_turn()` / `end_turn()`

### Combat System (`combat/`)

Turn-based tactical combat on a 3x4 grid battlefield:

- **CombatManager** - Initiates combat, manages combat queue
- **Combat** - Main combat coordinator
  - Attacker vs Defender (each represented by **CombatGroup**)
  - Turn-based with move/attack phases
  - Victory conditions: capture flag, eliminate units, force retreat
- **CombatUnit** - Units on the battlefield
- **CombatSquare** - Grid squares that hold units
- **CombatQueue** - Queues up combat encounters
- **CombatMovement** / **CombatAttack** / **CombatAssault** - Action classes

Combat rules are extensively documented in comments at the top of `combat/combat.gd` (lines 10-48).

### World Generation (`scenes/map/`)

- **WorldGen** (`scenes/map/world_gen.gd`) - Procedural map generation
  - Uses noise-based terrain generation
  - Multiple TileMapLayers for land, water, fog of war
  - **TileCustomData** - Custom data per tile (terrain modifiers, movement cost)
  - River and mountain range generation
  - Fog of war system (if enabled: `Def.FOG_OF_WAR_ENABLED`)

### Type System (`scripts/term.gd`)

Central enum definitions for type safety:
- `BuildingType`, `BuildingState`, `BuildingSize`
- `UnitType`, `UnitState`, `UnitCategory`, `UnitMovement`
- `ResourceType`, `IndustryType`, `TerrainType`
- `CollisionMask` for physics layers

### UI System (`ui/`)

- **WorldCanvas** - Main game UI overlay (HUD, controls)
- Building-specific UI panels: `ui/buildings/ui_*_building.gd`
- Unit-specific UI panels: `ui/units/ui_*_unit.gd`
- Trade, diplomacy, and NPC interaction panels
- **CombatCanvas** - Combat-specific UI

### Data-Driven Design

Building and unit stats are defined in JSON files:
- `assets/metadata/buildings.json` - Defines cost, production (make/need), labor demand, stats
- `assets/metadata/units.json` - Defines unit costs, requirements, stats
- Loaded at runtime by `Def` singleton in `_ready()`

### Transaction System

**Transaction** (`scripts/transaction.gd`) - Represents resource exchanges
- Used for building costs, production, trade
- Maps `Term.ResourceType` to quantities
- Integrated with Bank for resource validation

## Important Patterns

### Scene Organization
- Most game objects are Area2D nodes with CollisionShape2D
- Scene + Script pairing: `*.tscn` + `*.gd` with matching names
- Scripts use `class_name` for type identification

### Turn Management
- Objects implement `begin_turn()` and `end_turn()` methods
- Turn flow: WorldManager → PlayerManager → Player → Units/Colonies
- Turn counter tracked in `WorldManager.turn_number`

### Global Access Pattern
```gdscript
# Access core systems via Def singleton
Def.get_world()          # WorldManager
Def.get_world_map()      # WorldGen
Def.get_player_manager() # PlayerManager
Def.get_world_canvas()   # UI Canvas
```

### Persistence Pattern
All persistent objects implement:
```gdscript
func on_save_data() -> Dictionary
func on_load_data(_data: Dictionary) -> void
```

### Input Handling
- WorldManager handles tile selection via `WorldSelector`
- Units respond to drag-and-drop for movement
- Combat input handled in `CombatManager._unhandled_input()`

## Key Gameplay Features

1. **Colony Management** - Found colonies, build structures, manage economy
2. **Unit Movement** - NavigationAgent2D-based pathfinding with terrain costs
3. **Fog of War** - Reveals around units (configurable: `Def.FOG_OF_WAR_ENABLED`)
4. **Resource Economy** - Buildings produce/consume resources tracked by Bank
5. **Combat System** - Grid-based tactical combat with unit types (Infantry, Cavalry, Artillery)
6. **Research** - Military research system (Offensive, Defensive, Leadership)
7. **Diplomacy & Trade** - Trade routes and NPC villages

## File Naming Conventions

- Scripts: `snake_case.gd`
- Classes: `PascalCase` in `class_name`
- Scenes: `snake_case.tscn`
- UI components: Prefixed with `ui_`
- Combat components: Prefixed with `combat_`

## Testing & Debugging

- Debug mode spawns units via `Player.debug()` method
- Use `Print` singleton for standardized debug output
- Game saves to `user://conquest_save_01.ini` (typically `~/.local/share/godot/app_userdata/Conquest/`)

## Git Workflow

- `.gitignore` excludes: `.godot/`, `addons/`, `exports/`, `.DS_Store`
- Git plugin enabled: `version_control/plugin_name="GitPlugin"`

## Editor Plugins

- **Gaea** plugin enabled (`addons/gaea/`) - Terrain/map generation tooling
- **FantasyNameGenerator** - Character name generation

## Known Configuration

- Target Resolution: 960x640 (viewport), scales to 2880x1920 (window override)
- VSync Mode: 2 (Adaptive)
- Pixel-perfect rendering: `textures/canvas_textures/default_texture_filter=0`
- Physics layers: Layer 1 = Object, Layer 2 = Carrier
- Navigation layers: Layer 1 = Land, Layer 2 = Sea

## When Making Changes

1. **Adding New Buildings/Units**: Update JSON metadata in `assets/metadata/`, add scene/script in appropriate folder, register in `Preload` and `Def`
2. **Adding New Enums**: Update `scripts/term.gd` and add conversion methods in `Def`
3. **Modifying Turn Logic**: Update cascade through WorldManager → PlayerManager → Player → entities
4. **Changing Persistence**: Update both `on_save_data()` and `on_load_data()` methods
5. **UI Changes**: Update corresponding canvas classes (WorldCanvas, CombatCanvas)
