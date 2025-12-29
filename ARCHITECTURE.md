# ARCHITECTURE.md - The Holy Map (v1.2)

## 1. Coordinate System Registry
| Space | Unit | Resolution | Conversion Formula | Converter Function |
| :--- | :--- | :--- | :--- | :--- |
| **World** | `Vector2` | $1:1$ Pixels | N/A | N/A |
| **Ground Grid** | `Vector2i` | $64 \times 32$ | $f(W) = \text{floor}(W.x/64, W.y/32)$ | (Godot TileMapLayer) |
| **Miasma Grid** | `Vector2i` | $16 \times 8$ | $f(W) = \text{floor}(W.x/16.0, W.y/8.0)$ | `CoordConverter.world_to_miasma()` |
| **Miasma → World Origin** | `Vector2` | Origin/top-left | $f(G) = (G.x \times 16.0, G.y \times 8.0)$ | `CoordConverter.miasma_to_world_origin()` |
| **Miasma → World Center** | `Vector2` | Center point | $f(G) = (G.x \times 16.0 + 8.0, G.y \times 8.0 + 4.0)$ | `CoordConverter.miasma_to_world_center()` |
| **Isometric** | `Vector2` | Projected | $(x - y, (x + y) * 0.5)$ | `CoordConverter.to_isometric()` (unused) |

---

## 2. Node & System Hierarchy
### Core Singletons (Autoloads)
* **MiasmaManager.gd**: Data authority for cleared tiles (Persistent Sparse Dictionary). Uses world-pixel distance checks with isometric distance formula for elliptical fog clearing. Implements "Additive Miasma" - tiles are only added, never removed except by future Regrowth System.
* **SignalBus.gd**: Event bus for `derelict_moved` and `beam_fired`.
* **CoordConverter.gd**: Centralized coordinate conversion utilities:
  - `world_to_miasma(pos: Vector2) -> Vector2i`: Converts world pixels to 16x8 miasma grid using explicit float division
  - `miasma_to_world_origin(grid_pos: Vector2i) -> Vector2`: Converts miasma grid to world origin/top-left position (aligned so miasma (0,0) = ground (0,0) = world (0,0))
  - `miasma_to_world_center(grid_pos: Vector2i) -> Vector2`: Converts miasma grid to world center position
  - `to_isometric(vector: Vector2) -> Vector2`: Isometric projection (currently unused)

### World Scene Structure
* **World (Node2D)**
    * **WorldGrid (TileMapLayer)**: Ground layer (64x32 isometric).
    * **DerelictLogic (CharacterBody2D)**: Player entity and Lighthouse controller.
        * **Camera2D**: Main player camera (follows player).
            * **FogMask (SubViewport)**: Dynamic size render target (synced to window size) for the fog mask. Child of Camera2D for automatic transform inheritance.
                * **FogMaskColorRect**: Black background.
                * **FogPainter (Node2D)**: Draws 16x8 isometric diamond polygons for cleared Miasma using exact offsets `(0, -4), (8, 0), (0, 4), (-8, 0)`. Handles SubViewport size syncing.
        * **BeamController (Node)**: Lighthouse beam system controller (`src/systems/beam/BeamController.gd`).
            * **BeamVisualizer (Node2D)**: Visual debug representation container.
                * **BeamDebugVisualizer**: Debug visualization script instance.
            * **BeamMiasmaEmitter (Node)**: Routes beam actions to MiasmaManager (`src/systems/beam/BeamMiasmaEmitter.gd`).
    * **MiasmaSheet (CanvasLayer)**: Full-screen ColorRect with `MiasmaHole.gdshader`. Fixed to screen (`follow_viewport_enabled = false`).

---

## 3. Systems Integration

### Miasma Engine
* **Granularity**: The Miasma grid is 4x denser than the ground grid ($16 \times 8$ pixels per sub-tile). **16 Miasma sub-tiles fit perfectly inside 1 Ground tile ($64 \times 32$)**.
* **Additive Miasma Rule**: The `cleared_tiles` dictionary is a **persistent sparse dictionary** that serves as the Source of Truth. Data is **only removed by the (future) Regrowth System**, never by frame-reset or clearing operations. This enables a "Persistent/Additive" Tactical Simulation where fog clearing is cumulative and persistent across frames.
* **Clearing Algorithm**: Uses absolute world-pixel distance checks with isometric Y-axis flattening (2.0x scaling) for elliptical clearing:
  - Calculates `r_sq = radius * radius` in world pixels
  - Sets loop ranges with generous buffer: X uses `ceil((radius + 16.0) / 16.0)`, Y uses `ceil((radius + 16.0) / 8.0)` to ensure all overlapping tiles are checked
  - For each tile in the bounding box:
    - Gets tile's world origin and center: `t_origin = CoordConverter.miasma_to_world_origin(tile_pos)`, `t_center = CoordConverter.miasma_to_world_center(tile_pos)`
    - Finds nearest point on tile to clearing center: Clamps clearing center to tile bounds `[origin.x, origin.x+16] x [origin.y, origin.y+8]`
    - Calculates isometric distance from clearing center to nearest point: `dx = nearest_x - world_pos.x`, `dy = (nearest_y - world_pos.y) * 2.0`
    - **Isometric Distance Formula**: Clears tile if `(dx*dx + dy*dy) <= r_sq` (checks nearest point, not center, to ensure all overlapping tiles are cleared)
  - **✅ CLEARING LOGIC WORKS**: Debug output confirms tiles are being correctly added to `cleared_tiles` dictionary
  - **⚠️ RENDERING ISSUE**: Despite correct clearing, visual checkerboard pattern persists - this is a rendering/coordinate alignment problem, not a clearing logic problem
* **Rendering**: 
  - **Miasma Grid Diamond Geometry**: FogPainter draws isometric diamonds as polygons with exact offsets `(0, -4), (8, 0), (0, 4), (-8, 0)` relative to tile center. These offsets create 16x8 diamonds that should align with the isometric sub-tile grid.
  - **⚠️ KNOWN ISSUE - CHECKERBOARD PATTERN**: Visual checkerboard pattern persists despite tiles being correctly cleared in data. This indicates a rendering/coordinate alignment issue, not a clearing logic problem.
  - **⚠️ KNOWN ISSUE - ALIGNMENT**: Miasma tiles are not properly aligned with ground tiles. There is a consistent offset between miasma diamonds and ground tile boundaries.
  - FogPainter uses `draw_colored_polygon()` with pixel-perfect rounded coordinates
  - FogPainter converts grid positions to world origin using `CoordConverter.miasma_to_world_origin()`, then adds center offset (8, 4) for diamond drawing
  - FogPainter enforces SubViewport size parity: `get_parent().size = get_tree().root.size` (synced to window size)
  - FogMask SubViewport is a child of Camera2D, so it automatically inherits the camera's transform (position, zoom, offset)
  - Coordinate conversion: Uses parent Camera2D's `global_position` to convert world coordinates to SubViewport coordinates: `(world_pos - camera_world_pos) + viewport_center`
  - MiasmaSheet CanvasLayer is fixed to screen (`follow_viewport_enabled = false`)
  - MiasmaHole shader uses `SCREEN_UV` for screen-space sampling: ColorRect covers full screen, mask texture is camera-relative
  - With resolution parity and camera-relative viewport, SCREEN_UV provides correct screen-space alignment
* **3D Volume**: Achieved via a parallax-offset shader pass in `MiasmaHole.gdshader` to simulate height/volume.
* **Persistence**: `cleared_tiles` dictionary stores `Vector2i` keys representing Miasma sub-tiles. This is the persistent Source of Truth - entries are only removed by the future Regrowth System, never by clearing operations or frame-reset.

### The Lighthouse (Beam System)
* **Location**: `src/systems/beam/` directory
* **Components**:
  - **BeamController.gd**: Main brain - handles mode switching and input. Located at `DerelictLogic/BeamController`.
  - **BeamMiasmaEmitter.gd**: Routes beam mode actions to appropriate `MiasmaManager` functions. Located at `DerelictLogic/BeamController/BeamMiasmaEmitter`.
  - **BeamModel.gd**: Data model for beam descriptors (bubble, cone, laser).
  - **BeamDebugVisualizer.gd**: Visual debug representation of beam modes.
* **Modes**: `BeamMode` enum with 5 modes: `OFF`, `BUBBLE_MIN` (32px radius), `BUBBLE_MAX` (128px radius), `CONE` (placeholder), `LASER` (persistent tunnel).
* **Input**:
  - Mouse wheel: Cycles through modes (OFF → BUBBLE_MIN → BUBBLE_MAX → CONE → LASER → OFF).
  - Left Mouse Button: Instantly snaps to `LASER` mode when pressed.
* **Clearing Logic**:
  - **Bubble Modes**: Continuous clearing via `MiasmaManager.clear_fog()` with specified radius.
  - **Laser Mode**: Creates persistent wide tunnel using `MiasmaManager.clear_laser_path()` with 8px stride and ±12px halos.
  - **Cone Mode**: Currently placeholder (clears bubble at tip only).
* **Additive Miasma**: All beam clearing operations are additive and permanent - tiles persist forever (only removed by future Regrowth System).
* **Future**: Beam activity will increase Heat/Sound, influencing enemy detection (Stealth Loop) - not yet implemented.

---

## 4. File Map & Dependencies
- `src/core/`: Global logic (MiasmaManager, SignalBus, CoordConverter).
- `src/vfx/`: Rendering (FogPainter, MiasmaHole.gdshader).
- `src/entities/`: Gameplay actors (DerelictLogic).
- `src/systems/beam/`: Beam system components (BeamController, BeamMiasmaEmitter, BeamModel, BeamDebugVisualizer, BeamTypes).
- `src/scenes/`: Main World environment.