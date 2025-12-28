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
- **World.gd**: Main world script
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

## Project Structure
```
drifterz/
├── project.godot          # Godot project config
├── World.gd               # Main world script
├── src/
│   ├── core/              # Core systems (autoloads, utilities)
│   │   ├── MiasmaManager.gd
│   │   ├── SignalBus.gd
│   │   └── CoordConverter.gd
│   ├── entities/          # Game entities
│   │   ├── DerelictLogic.gd
│   │   └── DerelictLogic.tscn
│   ├── data/              # Data resources
│   │   ├── DerelictStats.gd
│   │   └── DefaultStats.tres
│   ├── sprites/           # Art assets
│   ├── vfx/               # Visual effects
│   │   ├── FogPainter.gd      # Fog visual rendering
│   │   ├── MaskSync.gd        # Camera sync for fog mask
│   │   └── MiasmaHole.gdshader # Fog shader
│   └── world.tscn         # Main scene
```

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

