# DRIFTERZ - Project Onboarding

## Project Overview
**DRIFTERZ** is a Godot 4.5 game featuring a dynamic fog-of-war system called "Miasma" that clears as the player moves through the world. The game uses isometric tile mapping and a shader-based fog rendering system.

## Core Systems

### 1. Miasma (Fog) System
- **MiasmaManager** (`src/core/MiasmaManager.gd`): Autoload singleton that manages the fog clearing system
  - Maintains a sparse dictionary of cleared tiles: `cleared_tiles: Dictionary` (key: Vector2i grid coordinates, value: int timestamp in msec)
  - Clears fog in a ~200px radius (roughly 3 tiles) around the player
  - Uses circle-based clearing logic (no square holes)
  - Tile size constant: `TILE_SIZE = 64`
  - Listens to `SignalBus.derelict_moved` signal to automatically clear fog when player moves

- **FogPainter** (`src/vfx/FogPainter.gd`): Draws the visual representation of cleared fog
  - Extends Node2D, draws white circles where fog has been cleared
  - Redraws every frame (optimization planned for later)
  - Uses `MiasmaManager.cleared_tiles` dictionary to determine what to draw

- **MiasmaHole.gdshader** (`src/vfx/MiasmaHole.gdshader`): Shader that applies the fog mask
  - Takes a `mask_texture` uniform (sampler2D)
  - Inverts the mask (1.0 - mask_sample.r) to control alpha/visibility
  - Applied to a ColorRect that covers the entire screen

- **MaskSync** (`src/vfx/MaskSync.gd`): Camera that syncs with the main player camera
  - Extends Camera2D
  - Copies position and zoom from the active camera each frame
  - Used in the FogMask SubViewport to keep the mask aligned with the game view

### 2. Player System
- **DerelictLogic** (`src/entities/DerelictLogic.gd`): The player character
  - Extends CharacterBody2D
  - Uses resource-based stats system (`DerelictStats`)
  - Movement via WASD/Arrow keys (using `Input.get_vector`)
  - Emits `SignalBus.derelict_moved` signal when moving
  - Default max speed: 300.0 (from `DerelictStats`)

- **DerelictStats** (`src/data/DerelictStats.gd`): Resource class for player stats
  - Currently has `max_speed: float = 300.0`
  - Loaded via `DefaultStats.tres` resource

### 3. World System
- **World.gd** (`src/scenes/World.gd`): Main world script
  - Generates a 80x80 tile ground layer
  - Sets up the fog rendering system with:
    - `MiasmaSheet` CanvasLayer with ColorRect (fog overlay)
    - `FogMask` SubViewport (renders the mask texture)
    - `MaskCamera` (syncs with player camera)
    - `FogPainter` (draws cleared areas)

### 4. Core Utilities
- **SignalBus** (`src/core/SignalBus.gd`): Autoload singleton for decoupled communication
  - Currently has: `signal derelict_moved(new_position: Vector2)`
  - Allows any system to listen/react to player movement without tight coupling

- **CoordConverter** (`src/core/CoordConverter.gd`): Utility for coordinate transformations
  - Static function: `to_isometric(vector: Vector2) -> Vector2`
  - Formula: `Vector2(vector.x - vector.y, (vector.x + vector.y) * 0.5)`
  - Note: Currently not actively used in fog system (FogPainter uses standard grid math)

## Technical Details

### Tile System
- **Tile Size**: 64x32 pixels (isometric)
- **Tile Shape**: Isometric (diamond-shaped)
- **Ground Texture**: `meadow2.png` (64x32 per tile)
- **World Grid**: 80x80 tiles (generated programmatically)

### Fog Rendering Pipeline
1. Player moves → `DerelictLogic` emits `SignalBus.derelict_moved`
2. `MiasmaManager` receives signal → clears tiles in radius → stores in `cleared_tiles` dict
3. `FogPainter` (in FogMask SubViewport) draws white circles for cleared tiles
4. `MaskSync` camera keeps FogMask viewport aligned with main camera
5. `MiasmaHole` shader reads FogMask texture → inverts it → controls fog ColorRect alpha
6. Result: Fog appears everywhere except where player has been

### Input System
- WASD keys for movement
- Arrow keys also supported
- Gamepad support configured (d-pad and analog sticks)

## Coordinate Systems Audit

**⚠️ COMPLEXITY WARNING: This project uses multiple overlapping coordinate systems that can cause confusion. This section documents all of them.**

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

### 2. Grid/Tile Coordinates (Vector2i)
- **Type**: `Vector2i` (integer-based, tile indices)
- **Origin**: Top-left tile (0, 0)
- **Units**: Tile indices (not pixels)
- **Tile Size**: 64 pixels per tile (defined in `MiasmaManager.TILE_SIZE`)
- **Used By**:
  - `MiasmaManager.cleared_tiles`: Dictionary keys are `Vector2i` grid coordinates
  - `World.gd`: `world_grid.set_cell(Vector2i(x, y), ...)` - places tiles at grid positions
  - `MiasmaManager.clear_fog()`: Converts world → grid, then stores grid coordinates
  - `FogPainter.gd`: Converts grid → world for drawing: `Vector2(grid_pos.x, grid_pos.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)`
- **Conversion**: 
  - World → Grid: `(world_pos / TILE_SIZE).floor()` → `Vector2i`
  - Grid → World: `Vector2(grid_pos.x, grid_pos.y) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)` (center of tile)
- **Location**: Core to fog system storage and tilemap operations

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
  - Size: `Vector2i(1152, 648)` (fixed resolution)
  - Location: `World/FogMask` SubViewport
  - Purpose: Renders the fog mask texture
  - Coordinate Space: World coordinates (via MaskSync camera)
- **MiasmaColorRect**:
  - Type: Screen-space ColorRect (anchors to full screen)
  - Location: `World/MiasmaSheet/MiasmaColorRect`
  - Coordinate Space: Screen coordinates (0,0 to screen width/height)
  - Uses shader with `mask_texture` uniform (UV coordinates 0.0-1.0)
- **Location**: `src/scenes/World.tscn`

### 6. Camera Coordinate Systems

#### Main Player Camera
- **Type**: `Camera2D`
- **Location**: `DerelictLogic/Camera2D` (child of player CharacterBody2D)
- **Coordinate Space**: World coordinates (follows player)
- **Position**: Inherits from player's `global_position`
- **Used By**: Main game viewport rendering

#### MaskSync Camera (FogMask SubViewport)
- **Type**: `Camera2D` (extends `MaskSync.gd`)
- **Location**: ⚠️ **MISSING FROM SCENE** - Should be in `World/FogMask/` but not present in `World.tscn`
- **Purpose**: Syncs with main camera to keep fog mask aligned
- **Sync Logic**: 
  - Finds main camera via `get_tree().root.get_camera_2d()`
  - Copies `global_position` and `zoom` each frame
  - Process priority: 100 (runs after player movement)
- **Coordinate Space**: World coordinates (synced to main camera)
- **Location**: `src/vfx/MaskSync.gd`
- **Status**: ⚠️ **NEEDS TO BE ADDED TO SCENE** - Code exists but camera node missing from scene tree

### 7. FogPainter Drawing Coordinates
- **Type**: `Vector2` (world coordinates for drawing)
- **Location**: `World/FogMask/FogPainter` (Node2D in FogMask SubViewport)
- **Coordinate Space**: World coordinates (drawn in FogMask viewport which uses world space via camera)
- **Conversion Logic**:
  - Reads grid coordinates from `MiasmaManager.cleared_tiles`
  - Converts to world: `Vector2(grid_pos.x, grid_pos.y) * tile_size + Vector2(tile_size * 0.5, tile_size * 0.5)`
  - Draws white circles at world positions
- **Issue**: Uses tile center calculation but doesn't account for isometric tile shape
- **Location**: `src/vfx/FogPainter.gd`

### 8. Shader UV Coordinates
- **Type**: `vec2` (normalized 0.0-1.0)
- **Location**: `MiasmaHole.gdshader`
- **Purpose**: Samples the mask texture
- **Input**: `mask_texture` uniform (ViewportTexture from FogMask SubViewport)
- **Coordinate Space**: Normalized UV (0,0 = top-left, 1,1 = bottom-right of texture)
- **Location**: `src/vfx/MiasmaHole.gdshader`

### Coordinate Conversion Summary

| From | To | Conversion | Location |
|------|-----|------------|----------|
| World (Vector2) | Grid (Vector2i) | `(world_pos / TILE_SIZE).floor()` | `MiasmaManager.clear_fog()` |
| Grid (Vector2i) | World (Vector2) | `Vector2(grid_pos) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)` | `FogPainter._draw()` |
| World (Vector2) | Isometric (Vector2) | `Vector2(x - y, (x + y) * 0.5)` | `CoordConverter.to_isometric()` (unused) |
| World | Screen | Camera transform | Godot Camera2D (automatic) |
| World | FogMask Viewport | MaskSync camera sync | `MaskSync._process()` |

### Known Issues & Complexity Problems

1. **Multiple Unused Coordinate Systems**: 
   - `CoordConverter.to_isometric()` exists but is never called
   - Fog system uses standard grid math despite isometric visuals

2. **Inconsistent Tile Center Calculation**:
   - `FogPainter` adds `tile_size * 0.5` offset (assumes square tiles)
   - Isometric tiles are 64x32 (not square), so center calculation may be incorrect

3. **Missing Camera Node**:
   - `MaskSync.gd` script exists but camera node is not in `World.tscn` scene tree
   - Fog mask may not align properly without this camera

4. **Coordinate System Confusion**:
   - World coordinates used for movement (pixels)
   - Grid coordinates used for fog storage (tile indices)
   - Isometric coordinates defined but unused
   - Screen coordinates for UI overlay
   - Multiple conversions happening in different places

5. **Tile Size Mismatch**:
   - `MiasmaManager.TILE_SIZE = 64` (assumes square)
   - Actual tile is 64x32 (isometric diamond)
   - Grid calculations may not align perfectly with visual tiles

### Maps & Scenes

#### Main World Scene
- **File**: `src/scenes/World.tscn`
- **Root Node**: `World` (Node2D)
- **Children**:
  - `WorldGrid` (TileMapLayer) - 80x80 isometric tilemap
  - `DerelictLogic` (CharacterBody2D) - Player at position (500, 300)
  - `MiasmaSheet` (CanvasLayer) - Fog overlay layer
    - `MiasmaColorRect` - Full-screen fog with shader
  - `FogMask` (SubViewport) - 1152x648 render target
    - `FogMaskColorRect` - Black background
    - `FogPainter` (Node2D) - Draws cleared fog areas
    - ⚠️ **Missing**: `MaskSync` Camera2D node

#### Player Entity Scene
- **File**: `src/entities/DerelictLogic.tscn`
- **Root Node**: `DerelictLogic` (CharacterBody2D)
- **Children**:
  - `Sprite2D` - Player sprite
  - `Camera2D` - Main game camera (follows player)
  - `BeamController` (Node) - Beam system
    - `BeamVisualizer` (Node2D)
    - `BeamMiasmaEmitter` (Node)

### Important Coordinate-Related Constants

- `MiasmaManager.TILE_SIZE = 64` (pixels per tile - assumes square)
- Actual tile dimensions: 64x32 pixels (isometric)
- World grid size: 80x80 tiles
- FogMask viewport size: 1152x648 pixels
- Fog clearing radius: ~200 pixels (~3 tiles)

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
    └── vfx/               # Visual effects
        ├── FogPainter.gd      # Fog visual rendering
        ├── MaskSync.gd        # Camera sync for fog mask
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
- ✅ Fog clearing system working
- ✅ Shader-based fog rendering functional
- 🔄 FogPainter redraws every frame (optimization opportunity)
- 🔄 CoordConverter exists but not used in fog system yet
- 🔄 Future: Fog regrowth logic (timestamps stored for this purpose)

## Key Design Patterns
- **Autoload Singletons**: MiasmaManager, SignalBus
- **Signal-based Communication**: Decoupled systems via SignalBus
- **Resource-based Stats**: DerelictStats as a Resource
- **Shader-based Rendering**: Fog uses custom shader with mask texture
- **SubViewport Pattern**: Fog mask rendered to separate viewport for shader access

## Notes for Development
- The fog system is designed to be extensible (timestamps stored for regrowth)
- Isometric coordinate conversion utility exists but fog currently uses standard grid math
- Performance optimization needed: FogPainter redraws entire dictionary every frame
- The game uses Godot 4.5 with Forward Plus rendering

