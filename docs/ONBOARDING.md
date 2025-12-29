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
  - **✅ MULTIMESH RENDERING**: MultiMesh strategy with texture stamp provides watertight coverage and eliminates rendering issues

- **FogPainter** (`src/vfx/FogPainter.gd`): Renders the visual representation of cleared fog using MultiMesh
  - Extends `MultiMeshInstance2D` for efficient batch rendering
  - **MultiMesh Strategy**: Uses a 16x8 texture stamp (`miasma_stamp.png`) containing a white isometric diamond shape
  - **Texture Stamp**: `miasma_stamp.png` is a 16x8 pixel PNG with white diamond (vertices: Top(8,0), Right(16,4), Bottom(8,8), Left(0,4)) on transparent background. Generated programmatically via `texture_generator.gd` utility script.
  - **MultiMesh Configuration**: Uses `QuadMesh` (16x8 size) with `TRANSFORM_2D` format. Instance count dynamically set based on cleared tiles.
  - **Watertight Coverage**: The texture naturally interlocks with zero gaps, eliminating checkerboard patterns
  - **Pixel-Perfect Rendering**: Uses `TEXTURE_FILTER_NEAREST` for crisp, pixel-perfect rendering without blur
  - **Snapped Origin Logic**: Converts grid to world origin using `CoordConverter.miasma_to_world_origin()`, calculates screen space: `(tile_world_origin - camera_world_pos) + viewport_center`, then floors the origin to lock to pixel grid. Creates `Transform2D(0, snapped_origin)` for each instance.
  - **Blending**: Uses `CanvasItemMaterial` with `BLEND_MODE_MIX` for proper transparency handling
  - **Update Cycle**: Rebuilds MultiMesh instances every frame in `_process()` based on `MiasmaManager.cleared_tiles` dictionary
  - Handles SubViewport size syncing: `get_parent().size = get_tree().root.size`
  - **✅ STATUS**: Fully implemented and working - provides watertight coverage with no rendering issues

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

