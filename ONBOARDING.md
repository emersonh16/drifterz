# DRIFTERZ - Project Onboarding

## Project Overview
**DRIFTERZ** is a Godot 4.5 game featuring a dynamic fog-of-war system called "Miasma" that clears as the player moves through the world. The game uses isometric tile mapping and a shader-based fog rendering system.

## Core Systems

### 1. Miasma (Fog) System
- **MiasmaManager** (`src/core/MiasmaManager.gd`): Autoload singleton that manages the fog clearing system
  - **Persistent Clearing (Additive Miasma)**: Maintains a persistent sparse dictionary of cleared tiles: `cleared_tiles: Dictionary` (key: Vector2i grid coordinates, value: int timestamp in msec)
  - **Source of Truth**: The `cleared_tiles` dictionary is the persistent data model. Tiles are only added, never removed except by the (future) Regrowth System. This enables cumulative, frame-persistent fog clearing.
  - Clears fog using world-pixel distance checks with isometric distance formula for elliptical clearing
  - Tile size constants: `TILE_SIZE_WIDTH = 16`, `TILE_SIZE_HEIGHT = 8` (miasma tiles are 1/4 size of ground tiles)
  - **16 Miasma sub-tiles fit perfectly inside 1 Ground tile (64x32)**
  - Uses `CoordConverter.world_to_miasma()` and `CoordConverter.miasma_to_world_center()` for centralized coordinate conversion
  - **Isometric Distance Formula**: Checks distance to nearest point on tile, not center: `(dx*dx + dy*dy) <= r_sq` where `dy` is scaled by 2.0 for isometric space
  - Uses +16px radius buffer in loop ranges to ensure all overlapping tiles are checked: X uses `ceil((radius + 16.0) / 16.0)`, Y uses `ceil((radius + 16.0) / 8.0)`
  - **✅ CLEARING LOGIC CONFIRMED WORKING**: Debug output shows tiles are correctly added to `cleared_tiles` dictionary
  - **⚠️ RENDERING ISSUE**: Despite correct clearing, visual checkerboard pattern persists - this is a rendering/coordinate alignment problem

- **FogPainter** (`src/vfx/FogPainter.gd`): Draws the visual representation of cleared fog
  - Extends Node2D, draws 16x8 isometric diamond polygons for each cleared tile
  - **Diamond Geometry**: Uses exact diamond polygon offsets: `(0, -4), (8, 0), (0, 4), (-8, 0)` from tile center
  - **⚠️ KNOWN ISSUE - CHECKERBOARD PATTERN**: Visual checkerboard pattern persists despite tiles being correctly cleared. Debug confirms tiles are in `cleared_tiles` dictionary, indicating a rendering/coordinate alignment issue.
  - **⚠️ KNOWN ISSUE - ALIGNMENT**: Miasma tiles are not properly aligned with ground tiles. There is a consistent offset between miasma diamonds and ground tile boundaries.
  - Uses `CoordConverter.miasma_to_world_origin()` to get tile origin, then adds center offset (8, 4) for diamond drawing
  - Converts world coordinates to SubViewport coordinates: `(world_pos - camera_world_pos) + viewport_center`
  - Uses pixel-perfect rounded coordinates to prevent sub-pixel gaps
  - Redraws every frame (optimization planned for later)
  - Uses `MiasmaManager.cleared_tiles` persistent dictionary to determine what to draw

- **MiasmaHole.gdshader** (`src/vfx/MiasmaHole.gdshader`): Shader that applies the fog mask
  - Takes a `mask_texture` uniform (sampler2D)
  - Uses `SCREEN_UV` to sample the mask texture for screen-space alignment
  - Since FogMask is a child of Camera2D, the SubViewport output aligns 1:1 with screen space
  - With resolution parity (SubViewport size = window size), SCREEN_UV provides correct alignment
  - Inverts the mask (1.0 - mask_sample.r) to control alpha/visibility
  - Applied to a ColorRect that covers the entire screen

- **FogMask SubViewport Architecture (Camera-Local Hierarchy)**: The FogMask SubViewport is a child of the main Camera2D
  - **Definitive Solution for Tracking Drift**: This architecture eliminates coordinate tracking drift by leveraging automatic transform inheritance
  - The viewport naturally follows the camera - no separate sync script needed
  - The camera's transform (position, zoom, offset) is automatically applied to all children
  - FogPainter handles SubViewport size syncing: `get_parent().size = get_tree().root.size` (matches window size)
  - This is the **definitive fix** for camera-relative fog mask rendering

### 2. Player System
- **DerelictLogic** (`src/entities/DerelictLogic.gd`): The player character
  - Extends CharacterBody2D
  - Uses resource-based stats system (`DerelictStats`)
  - Movement via WASD/Arrow keys (using `Input.get_vector`)
  - Emits `SignalBus.derelict_moved` signal when moving
  - Default max speed: 300.0 (from `DerelictStats`)
  - Contains `BeamController` node for lighthouse beam system

- **DerelictStats** (`src/data/DerelictStats.gd`): Resource class for player stats
  - Currently has `max_speed: float = 300.0`
  - Loaded via `DefaultStats.tres` resource

### 2b. Lighthouse Beam System
- **BeamController** (`src/systems/beam/BeamController.gd`): Main brain for beam mode switching
  - Located at `DerelictLogic/BeamController`
  - **BeamMode Enum**: `OFF`, `BUBBLE_MIN` (32px radius), `BUBBLE_MAX` (128px radius), `CONE` (placeholder), `LASER` (persistent tunnel)
  - **Input Handling**:
    - Mouse wheel up/down: Cycles through all modes
    - Left Mouse Button: Instantly snaps to `LASER` mode
  - **Mode Behavior**:
    - `OFF`: No clearing
    - `BUBBLE_MIN`/`BUBBLE_MAX`: Continuous clearing around player (always active)
    - `CONE`: Placeholder implementation (clears bubble at tip only)
    - `LASER`: Creates persistent wide tunnel on left-click (8px stride, ±12px halos)
  - Uses `BeamModel` for data descriptors and `BeamDebugVisualizer` for visual feedback

- **BeamMiasmaEmitter** (`src/systems/beam/BeamMiasmaEmitter.gd`): Routes beam actions to MiasmaManager
  - Located at `DerelictLogic/BeamController/BeamMiasmaEmitter`
  - **Functions**:
    - `apply_bubble(bubble: Dictionary)`: Routes bubble clearing to `MiasmaManager.clear_fog()`
    - `apply_laser(origin, direction, length)`: Routes laser clearing to `MiasmaManager.clear_laser_path()`
    - `apply_cone(origin, direction, angle, length)`: Placeholder - currently clears bubble at tip
  - **Additive Miasma Rule**: Never resets or clears `cleared_tiles` dictionary - all operations are additive and permanent

- **BeamModel** (`src/systems/beam/BeamModel.gd`): Data model for beam descriptors
  - `get_bubble_descriptor(origin, radius)`: Returns dictionary with origin and radius

- **BeamDebugVisualizer** (`src/systems/beam/BeamDebugVisualizer.gd`): Visual debug representation
  - Shows current beam mode and clearing area visualization

### 3. World System
- **World.gd** (`src/scenes/World.gd`): Main world script
  - Generates a 80x80 tile ground layer
  - Sets up the fog rendering system with:
    - `MiasmaSheet` CanvasLayer fixed to screen (`follow_viewport_enabled = false`)
    - `MiasmaColorRect` (Full Rect, mouse_filter = Ignore) with `MiasmaHole.gdshader`
    - `FogMask` SubViewport (child of Camera2D, dynamic size synced to window) renders the mask texture
    - `FogPainter` (draws 16x8 rectangles for cleared areas, handles size syncing)

### 4. Core Utilities
- **SignalBus** (`src/core/SignalBus.gd`): Autoload singleton for decoupled communication
  - Currently has: `signal derelict_moved(new_position: Vector2)`
  - Allows any system to listen/react to player movement without tight coupling

- **CoordConverter** (`src/core/CoordConverter.gd`): Centralized utility for coordinate transformations
  - `world_to_miasma(pos: Vector2) -> Vector2i`: Converts world pixel coordinates to 16x8 miasma grid coordinates
    - **Pixel-Perfect Formula**: `Vector2i(floor(pos.x / 16.0), floor(pos.y / 8.0))` - **MUST use explicit float division** to prevent alignment bugs
    - Used by `MiasmaManager.clear_fog()` for coordinate conversion
  - `miasma_to_world_origin(grid_pos: Vector2i) -> Vector2`: Converts miasma grid coordinates to world origin/top-left position
    - **Alignment**: Formula `Vector2(grid_pos.x * 16.0, grid_pos.y * 8.0)` ensures miasma (0,0) = ground (0,0) = world (0,0)
    - Used by `MiasmaManager.clear_fog()` for overlap checking and `FogPainter._draw()` for rendering
  - `miasma_to_world_center(grid_pos: Vector2i) -> Vector2`: Converts miasma grid coordinates to world center position
    - Formula: `Vector2(origin.x + 8.0, origin.y + 4.0)` where origin is from `miasma_to_world_origin()`
    - Used by `MiasmaManager.clear_fog()` for distance calculations
  - `to_isometric(vector: Vector2) -> Vector2`: Isometric projection utility
    - Formula: `Vector2(vector.x - vector.y, (vector.x + vector.y) * 0.5)`
    - Note: Currently not actively used in fog system

## Technical Details

### Tile System
- **Tile Size**: 64x32 pixels (isometric)
- **Tile Shape**: Isometric (diamond-shaped)
- **Ground Texture**: `meadow2.png` (64x32 per tile)
- **World Grid**: 80x80 tiles (generated programmatically)

### Fog Rendering Pipeline
1. Player moves → `DerelictLogic` emits `SignalBus.derelict_moved`
2. `MiasmaManager.clear_fog(world_pos, radius)` receives world position and radius:
   - Converts world position to miasma grid: `center_grid = CoordConverter.world_to_miasma(world_pos)`
   - Defines `r_sq = radius * radius` (absolute world pixels, no average tile size)
   - Sets loop ranges: X uses `ceil(radius / 16.0)`, Y uses `ceil(radius / 8.0)` to cover full ellipse
   - For each tile in bounding box:
     - Gets tile's world center: `t_world = CoordConverter.miasma_to_world_center(tile_pos)`
     - Calculates world-pixel distance: `dx = t_world.x - world_pos.x`, `dy = (t_world.y - world_pos.y) * 2.0` (isometric flattening)
     - Clears tile only if `(dx*dx + (dy*2.0)*(dy*2.0)) <= r_sq` (isometric distance formula with Y-axis 2.0x scaling)
   - Stores cleared tiles in `cleared_tiles` dictionary
   - **Result**: Solid elliptical clearing with no checkerboard pattern
3. `FogPainter` (in FogMask SubViewport) draws 16x8 isometric diamond polygons for each cleared tile:
   - Converts grid positions to world origin using `CoordConverter.miasma_to_world_origin()`
   - Converts world coordinates to SubViewport coordinates: `(world_pos - camera_world_pos) + viewport_center`
   - Adds center offset (8, 4) to get diamond center position
   - Draws isometric diamonds using exact polygon offsets: `(0, -4), (8, 0), (0, 4), (-8, 0)` relative to tile center
   - Uses pixel-perfect rounded coordinates to prevent sub-pixel gaps
   - Enforces resolution parity: SubViewport size = window size (`get_tree().root.size`)
   - Since FogMask is a child of Camera2D, the camera's transform is automatically applied
   - **⚠️ KNOWN ISSUE**: Visual checkerboard pattern and alignment issues persist despite correct data clearing
4. `MiasmaHole` shader:
   - Samples FogMask texture using `SCREEN_UV` (screen-space sampling)
   - Since FogMask is camera-relative, the SubViewport output aligns 1:1 with screen space
   - With resolution parity, SCREEN_UV provides correct screen-space alignment
   - Inverts the mask → controls fog ColorRect alpha
5. `MiasmaSheet` CanvasLayer is fixed to screen (fog overlay stays on screen, mask moves with camera view)
6. Result: Fog appears everywhere except where player has been (solid elliptical clearing area that stays locked to player position on screen)

### Input System
- WASD keys for movement
- Arrow keys also supported
- Gamepad support configured (d-pad and analog sticks)

## Coordinate Systems Audit

**⚠️ COMPLEXITY WARNING: This project uses multiple overlapping coordinate systems that can cause confusion. This section documents all of them.**

**⚠️ COORDINATE INTEGRITY RULE**: All world-to-grid conversions **MUST use explicit float division with floor()** to prevent the "50% Checkerboard" alignment bug. Example: `floor(pos.x / 16.0)` not `floor(pos.x / 16)`. This ensures pixel-perfect alignment of the $16 \times 8$ isometric grid.

### 1. World/Global Coordinates (Vector2)
- **Type**: `Vector2` (float-based, pixel coordinates)
- **Origin**: Top-left of the world (0, 0)
- **Units**: Pixels
- **Used By**:
  - `DerelictLogic.gd`: `global_position` (player position in world space)
  - `SignalBus.derelict_moved`: Emits `new_position: Vector2` in world coordinates
  - `MiasmaManager.clear_fog()`: Takes `world_pos: Vector2` parameter
  - `BeamController.gd`: Uses `get_parent().global_position` to get player world position
  - `BeamModel.get_bubble_descriptor()`: Takes `origin: Vector2` in world coordinates
- **Conversion**: World → Grid: `(world_pos / TILE_SIZE).floor()` → `Vector2i`
- **Location**: Used throughout movement, fog clearing, and beam systems

### 2. Miasma Grid Coordinates (Vector2i)
- **Type**: `Vector2i` (integer-based, tile indices)
- **Origin**: Top-left tile (0, 0)
- **Units**: Tile indices (not pixels)
- **Tile Size**: 16x8 pixels per miasma tile (defined in `MiasmaManager.TILE_SIZE_WIDTH` and `TILE_SIZE_HEIGHT`)
- **Used By**:
  - `MiasmaManager.cleared_tiles`: Dictionary keys are `Vector2i` miasma grid coordinates
  - `MiasmaManager.clear_fog()`: Converts world → miasma grid using `CoordConverter.world_to_miasma()`, then stores grid coordinates
  - `FogPainter.gd`: Converts grid → world for drawing using `CoordConverter.miasma_to_world_center()`
- **Conversion** (via CoordConverter):
  - World → Miasma Grid: `CoordConverter.world_to_miasma(pos)` → `Vector2i(floor(pos.x / 16), floor(pos.y / 8))`
  - Miasma Grid → World Center: `CoordConverter.miasma_to_world_center(grid_pos)` → `Vector2(grid_pos.x * 16 + 8, grid_pos.y * 8 + 4)`
- **Location**: Core to fog system storage and rendering

### 2b. Ground Grid Coordinates (Vector2i)
- **Type**: `Vector2i` (integer-based, tile indices)
- **Origin**: Top-left tile (0, 0)
- **Units**: Tile indices (not pixels)
- **Tile Size**: 64x32 pixels per ground tile
- **Used By**:
  - `World.gd`: `world_grid.set_cell(Vector2i(x, y), ...)` - places tiles at grid positions
  - Godot's TileMapLayer handles isometric rendering automatically
- **Location**: `src/scenes/World.tscn` and `src/scenes/World.gd`

### 3. Isometric Coordinates (Vector2 - Defined but Unused)
- **Type**: `Vector2` (float-based)
- **Purpose**: Convert standard 2D coordinates to isometric projection
- **Formula**: `Vector2(vector.x - vector.y, (vector.x + vector.y) * 0.5)`
- **Defined In**: `CoordConverter.to_isometric()`
- **Status**: ⚠️ **NOT ACTIVELY USED** - Utility exists but fog system uses standard grid math
- **Location**: `src/core/CoordConverter.gd`
- **Note**: The tilemap is isometric (64x32 diamond tiles), but coordinate conversions use standard grid math, not isometric math

### 4. TileMap Coordinates (Isometric Tile System)
- **Type**: `Vector2i` (tile indices in isometric space)
- **Tile Shape**: Isometric (diamond-shaped)
- **Tile Size**: 64x32 pixels (width x height)
- **TileSet**: Defined in `World.tscn` with `tile_shape = 1` (isometric)
- **World Grid**: 80x80 tiles (5120x2560 pixels total)
- **Used By**:
  - `WorldGrid` (TileMapLayer): `set_cell(Vector2i(x, y), 0, Vector2i(0, 0))`
  - Godot's TileMapLayer handles isometric rendering automatically
- **Location**: `src/scenes/World.tscn` and `src/scenes/World.gd`
- **Note**: Despite being isometric visually, the coordinate system used in code is standard grid-based

### 5. Screen/Viewport Coordinates
- **Type**: `Vector2i` (integer pixels)
- **FogMask SubViewport**: 
  - Size: Dynamic (synced to window size via `get_tree().root.size`)
  - Location: `World/DerelictLogic/Camera2D/FogMask` SubViewport (child of Camera2D)
  - Purpose: Renders the fog mask texture
  - Coordinate Space: World coordinates (automatically transformed by parent Camera2D)
  - Architecture: Child of Camera2D for automatic transform inheritance (no sync script needed)
- **MiasmaColorRect**:
  - Type: Screen-space ColorRect (anchors to full screen)
  - Location: `World/MiasmaSheet/MiasmaColorRect`
  - Coordinate Space: Screen coordinates (0,0 to screen width/height)
  - Uses shader with `mask_texture` uniform (SCREEN_UV coordinates for screen-space sampling)
- **Location**: `src/scenes/World.tscn`

### 6. Camera Coordinate Systems

#### Main Player Camera
- **Type**: `Camera2D`
- **Location**: `DerelictLogic/Camera2D` (child of player CharacterBody2D)
- **Coordinate Space**: World coordinates (follows player)
- **Position**: Inherits from player's `global_position`
- **Used By**: Main game viewport rendering

#### FogMask SubViewport (Camera-Relative Architecture)
- **Type**: `SubViewport` (child of Camera2D)
- **Location**: `World/DerelictLogic/Camera2D/FogMask` (SubViewport node as child of main Camera2D)
- **Purpose**: Renders fog mask texture, automatically aligned with camera view
- **Architecture**: 
  - SubViewport is a child of Camera2D, so it automatically inherits the camera's transform
  - No separate sync script needed - transform inheritance handles alignment
  - FogPainter handles size syncing: `get_parent().size = get_tree().root.size`
- **Coordinate Space**: World coordinates (automatically transformed by parent Camera2D)
- **Status**: ✅ **IMPLEMENTED** - Camera-relative architecture eliminates sync complexity

### 7. FogPainter Drawing Coordinates
- **Type**: `Vector2` (world coordinates for drawing)
- **Location**: `World/DerelictLogic/Camera2D/FogMask/FogPainter` (Node2D in FogMask SubViewport)
- **Coordinate Space**: World coordinates (drawn in FogMask viewport, automatically transformed by parent Camera2D)
- **Conversion Logic**:
  - Reads grid coordinates from `MiasmaManager.cleared_tiles`
  - Converts to world center using `CoordConverter.miasma_to_world_center(grid_pos)`
  - Draws 16x8 rectangles using `draw_rect()` for full coverage
  - Handles SubViewport size syncing: `get_parent().size = get_tree().root.size`
- **Location**: `src/vfx/FogPainter.gd`

### 8. Shader UV Coordinates
- **Type**: `vec2` (screen-space coordinates)
- **Location**: `MiasmaHole.gdshader`
- **Purpose**: Samples the mask texture in screen space
- **Input**: `mask_texture` uniform (ViewportTexture from FogMask SubViewport)
- **Coordinate Space**: `SCREEN_UV` (screen-space coordinates, 0,0 = top-left of screen, 1,1 = bottom-right)
- **Rationale**: Since FogMask is camera-relative, the SubViewport output aligns 1:1 with screen space
- **Location**: `src/vfx/MiasmaHole.gdshader`

### Coordinate Conversion Summary

| From | To | Conversion | Location |
|------|-----|------------|----------|
| World (Vector2) | Miasma Grid (Vector2i) | `CoordConverter.world_to_miasma(pos)` | `MiasmaManager.clear_fog()`, centralized |
| Miasma Grid (Vector2i) | World Center (Vector2) | `CoordConverter.miasma_to_world_center(grid_pos)` | `MiasmaManager.clear_fog()`, `FogPainter._draw()`, centralized |
| World (Vector2) | Isometric (Vector2) | `CoordConverter.to_isometric(vector)` | `CoordConverter.to_isometric()` (unused) |
| World | Screen | Camera transform | Godot Camera2D (automatic) |
| World | FogMask Viewport | Camera transform inheritance | SubViewport as child of Camera2D (automatic) |

### Known Issues & Complexity Problems

1. **Isometric Projection Utility Unused**: 
   - `CoordConverter.to_isometric()` exists but is never called
   - May be useful for future features but not currently needed

2. **Performance Optimization Opportunity**:
   - `FogPainter` redraws every frame (optimization planned for later)
   - Could use dirty rectangles or incremental updates

3. **Coordinate System Status**:
   - ✅ **FIXED**: Coordinate conversions are now centralized in `CoordConverter`
   - ✅ **FIXED**: Miasma grid uses proper 16x8 tile dimensions with pixel-perfect floor division
   - ✅ **FIXED**: World-pixel distance checks with isometric distance formula ensure consistent coordinate space
   - ✅ **FIXED**: FogMask SubViewport is now a child of Camera2D for automatic transform inheritance (Camera-Local Hierarchy)
   - ✅ **FIXED**: Persistent Clearing (Additive Miasma) - `cleared_tiles` is persistent, only removed by future Regrowth System
   - ✅ **FIXED**: Clearing logic correctly adds tiles to `cleared_tiles` dictionary (confirmed via debug output)
   - ⚠️ **UNRESOLVED**: Visual checkerboard pattern persists despite correct data clearing - rendering/coordinate alignment issue
   - ⚠️ **UNRESOLVED**: Miasma tiles not properly aligned with ground tiles - consistent offset issue
   - ⚠️ **INVESTIGATING**: FogPainter coordinate conversion from world to SubViewport space may have alignment issues

### Maps & Scenes

#### Main World Scene
- **File**: `src/scenes/World.tscn`
- **Root Node**: `World` (Node2D)
- **Children**:
  - `WorldGrid` (TileMapLayer) - 80x80 isometric tilemap
  - `DerelictLogic` (CharacterBody2D) - Player at position (500, 300)
    - `Camera2D` - Main player camera
      - `FogMask` (SubViewport) - Dynamic size render target (synced to window)
        - `FogMaskColorRect` - Black background
        - `FogPainter` (Node2D) - Draws cleared fog areas (16x8 rectangles, handles size syncing)
  - `MiasmaSheet` (CanvasLayer) - Fog overlay layer
    - `MiasmaColorRect` - Full-screen fog with shader

#### Player Entity Scene
- **File**: `src/entities/DerelictLogic.tscn`
- **Root Node**: `DerelictLogic` (CharacterBody2D)
- **Children**:
  - `Sprite2D` - Player sprite
  - `Camera2D` - Main game camera (follows player)
  - `BeamController` (Node) - Lighthouse beam system controller
    - Script: `src/systems/beam/BeamController.gd`
    - `BeamVisualizer` (Node2D) - Visual debug representation
      - Contains `BeamDebugVisualizer` script instance
    - `BeamMiasmaEmitter` (Node) - Routes beam actions to MiasmaManager
      - Script: `src/systems/beam/BeamMiasmaEmitter.gd`

### Important Coordinate-Related Constants

- `MiasmaManager.TILE_SIZE_WIDTH = 16` (miasma tile width in pixels)
- `MiasmaManager.TILE_SIZE_HEIGHT = 8` (miasma tile height in pixels)
- Miasma tiles are 1/4 the size of ground tiles (16x8 vs 64x32)
- Ground tile dimensions: 64x32 pixels (isometric)
- World grid size: 80x80 ground tiles
- FogMask viewport size: 1152x648 pixels
- Fog clearing radius: ~200 pixels (uses world-pixel distance checks)

## Project Structure

The project follows a clean, organized structure with all source code under `src/`:

```
drifterz/
├── LICENSE
├── ONBOARDING.md
├── project.godot          # Godot project config
└── src/
    ├── assets/            # All game assets
    │   └── sprites/       # Sprite images
    │       ├── Derelict-sprite.png
    │       └── meadow2.png
    ├── core/              # Core systems (autoloads, utilities)
    │   ├── MiasmaManager.gd
    │   ├── SignalBus.gd
    │   └── CoordConverter.gd
    ├── data/              # Data resources
    │   ├── DerelictStats.gd
    │   └── DefaultStats.tres
    ├── entities/          # Game entities (scripts + scenes together)
    │   ├── DerelictLogic.gd
    │   └── DerelictLogic.tscn
    ├── scenes/            # Main game scenes
    │   ├── World.gd       # Main world script
    │   └── World.tscn     # Main scene (entry point)
    ├── systems/           # Gameplay systems
    │   └── beam/          # Lighthouse beam system
    │       ├── BeamController.gd
    │       ├── BeamMiasmaEmitter.gd
    │       ├── BeamModel.gd
    │       ├── BeamDebugVisualizer.gd
    │       └── BeamTypes.gd
    └── vfx/               # Visual effects
        ├── FogPainter.gd      # Fog visual rendering
        └── MiasmaHole.gdshader # Fog shader
```

**Structure Notes:**
- All source code is organized under `src/` for consistency
- Scenes are grouped in `scenes/` directory (main game scenes)
- Entities keep their scripts and scene files together in `entities/`
- Assets are organized under `assets/` with subdirectories by type (`sprites/`)
- Core systems (autoloads) are in `core/`
- Visual effects (shaders, VFX scripts) are in `vfx/`

## Current State & Next Steps
- ✅ Basic player movement implemented
- ✅ **Persistent Clearing (Additive Miasma)**: Fog clearing system uses persistent sparse dictionary - tiles are only added, never removed except by future Regrowth System
- ✅ Fog clearing logic working correctly - tiles are properly added to `cleared_tiles` dictionary (confirmed via debug)
- ✅ Shader-based fog rendering functional
- ✅ Coordinate conversions centralized in CoordConverter with pixel-perfect floor division
- ✅ **Camera-Local Hierarchy**: FogMask SubViewport as child of Camera2D eliminates tracking drift
- ✅ **Lighthouse Beam System**: BeamController with 5 modes (OFF, BUBBLE_MIN, BUBBLE_MAX, CONE, LASER)
- ✅ **BeamMiasmaEmitter**: Routes beam actions to MiasmaManager with additive clearing
- ✅ **Laser Mode**: Creates persistent wide tunnels (8px stride, ±12px halos) that stay forever
- ⚠️ **CRITICAL ISSUE - CHECKERBOARD PATTERN**: Visual checkerboard pattern persists despite correct data clearing. This is a rendering/coordinate alignment issue, not a clearing logic problem.
- ⚠️ **CRITICAL ISSUE - ALIGNMENT**: Miasma tiles are not properly aligned with ground tiles. There is a consistent offset between miasma diamonds and ground tile boundaries.
- 🔄 **INVESTIGATING**: FogPainter coordinate conversion from world to SubViewport space - may need to use different coordinate system or transform
- 🔄 FogPainter redraws every frame (optimization opportunity)
- 🔄 **Cone Mode**: Currently placeholder - needs proper cone clearing implementation
- 🔄 Future: Fog regrowth logic (timestamps stored for this purpose)
- 🔄 Future: Beam activity Heat/Sound system for enemy detection (Stealth Loop)

## Key Design Patterns
- **Autoload Singletons**: MiasmaManager, SignalBus
- **Signal-based Communication**: Decoupled systems via SignalBus
- **Resource-based Stats**: DerelictStats as a Resource
- **Shader-based Rendering**: Fog uses custom shader with mask texture
- **SubViewport Pattern**: Fog mask rendered to separate viewport for shader access

## Notes for Development
- **Persistent Clearing Standard**: The fog system uses "Additive Miasma" - `cleared_tiles` is persistent and cumulative. Tiles are only removed by the future Regrowth System, never by frame-reset or clearing operations.
- The fog system is designed to be extensible (timestamps stored for regrowth)
- Coordinate conversions are centralized in `CoordConverter` for consistency
- **Coordinate Integrity**: All world-to-grid conversions MUST use explicit float division: `floor(pos.x / 16.0)` not `floor(pos.x / 16)` to prevent checkerboard alignment bugs
- Fog clearing uses isometric distance formula: `(dx*dx + (dy*2.0)*(dy*2.0)) <= r_sq` with +4px radius buffer to prevent missing edge tiles
- **Camera-Local Hierarchy**: FogMask SubViewport as child of Camera2D is the definitive solution for eliminating tracking drift
- Performance optimization needed: FogPainter redraws entire dictionary every frame
- The game uses Godot 4.5 with Forward Plus rendering
- **Visual Alignment**: 16 Miasma sub-tiles (16x8 each) fit perfectly inside 1 Ground tile (64x32)

