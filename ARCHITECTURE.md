# ARCHITECTURE.md - The Holy Map (v1.1)

## 1. Coordinate System Registry
| Space | Unit | Resolution | Conversion Formula | Converter Function |
| :--- | :--- | :--- | :--- | :--- |
| **World** | `Vector2` | $1:1$ Pixels | N/A | N/A |
| **Ground Grid** | `Vector2i` | $64 \times 32$ | $f(W) = \text{floor}(W.x/64, W.y/32)$ | (Godot TileMapLayer) |
| **Miasma Grid** | `Vector2i` | $16 \times 8$ | $f(W) = \text{floor}(W.x/16.0, W.y/8.0)$ | `CoordConverter.world_to_miasma()` |
| **Miasma → World** | `Vector2` | Center point | $f(G) = (G.x \times 16 + 8, G.y \times 8 + 4)$ | `CoordConverter.miasma_to_world_center()` |
| **Isometric** | `Vector2` | Projected | $(x - y, (x + y) * 0.5)$ | `CoordConverter.to_isometric()` (unused) |

---

## 2. Node & System Hierarchy
### Core Singletons (Autoloads)
* **MiasmaManager.gd**: Data authority for cleared tiles (Persistent Sparse Dictionary). Uses world-pixel distance checks with isometric distance formula for elliptical fog clearing. Implements "Additive Miasma" - tiles are only added, never removed except by future Regrowth System.
* **SignalBus.gd**: Event bus for `derelict_moved` and `beam_fired`.
* **CoordConverter.gd**: Centralized coordinate conversion utilities:
  - `world_to_miasma(pos: Vector2) -> Vector2i`: Converts world pixels to 16x8 miasma grid
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
    * **MiasmaSheet (CanvasLayer)**: Full-screen ColorRect with `MiasmaHole.gdshader`. Fixed to screen (`follow_viewport_enabled = false`).

---

## 3. Systems Integration

### Miasma Engine
* **Granularity**: The Miasma grid is 4x denser than the ground grid ($16 \times 8$ pixels per sub-tile). **16 Miasma sub-tiles fit perfectly inside 1 Ground tile ($64 \times 32$)**.
* **Additive Miasma Rule**: The `cleared_tiles` dictionary is a **persistent sparse dictionary** that serves as the Source of Truth. Data is **only removed by the (future) Regrowth System**, never by frame-reset or clearing operations. This enables a "Persistent/Additive" Tactical Simulation where fog clearing is cumulative and persistent across frames.
* **Clearing Algorithm**: Uses absolute world-pixel distance checks with isometric Y-axis flattening (2.0x scaling) for elliptical clearing:
  - Calculates `r_sq = (radius + 4.0) * (radius + 4.0)` in world pixels (4px buffer prevents missing edge tiles due to 2:1 isometric ratio)
  - Sets loop ranges: X uses `ceil((radius + 4.0) / 16.0)`, Y uses `ceil((radius + 4.0) / 8.0)` to cover full ellipse
  - For each tile in the bounding box:
    - Gets tile's world center: `t_world = CoordConverter.miasma_to_world_center(tile_pos)`
    - Calculates world-pixel distance: `dx = t_world.x - world_pos.x`, `dy = (t_world.y - world_pos.y) * 2.0`
    - **Isometric Distance Formula**: Clears tile only if `(dx*dx + (dy*2.0)*(dy*2.0)) <= r_sq` (absolute world-pixel check with Y-axis 2.0x scaling)
  - This ensures solid elliptical clearing with no checkerboard pattern
* **Rendering**: 
  - **Miasma Grid Diamond Geometry**: FogPainter MUST draw isometric diamonds as polygons with exact offsets `(0, -4), (8, 0), (0, 4), (-8, 0)` relative to tile center to ensure seamless tiling. These offsets create perfect 16x8 diamonds that align with the isometric sub-tile grid.
  - FogPainter uses `draw_colored_polygon()` with pixel-perfect rounded coordinates to prevent sub-pixel gaps
  - FogPainter enforces SubViewport size parity: `get_parent().size = get_tree().root.size` (synced to window size)
  - FogMask SubViewport is a child of Camera2D, so it automatically inherits the camera's transform (position, zoom, offset)
  - This eliminates the need for MaskSync - the viewport naturally follows the camera
  - MiasmaSheet CanvasLayer is fixed to screen (`follow_viewport_enabled = false`)
  - MiasmaHole shader uses `SCREEN_UV` for screen-space sampling: ColorRect covers full screen, mask texture is camera-relative
  - With resolution parity and camera-relative viewport, SCREEN_UV provides correct screen-space alignment
* **3D Volume**: Achieved via a parallax-offset shader pass in `MiasmaHole.gdshader` to simulate height/volume.
* **Persistence**: `cleared_tiles` dictionary stores `Vector2i` keys representing Miasma sub-tiles. This is the persistent Source of Truth - entries are only removed by the future Regrowth System, never by clearing operations or frame-reset.

### The Lighthouse (Beam System)
* **Modes**: Supports **Bubble**, **Cone**, and **Laser** via state-based clearing logic.
* **Interaction**: The Beam emits "Stamp" requests to the `MiasmaManager`.
* **Signature**: Beam activity increases Heat/Sound, influencing enemy detection (Stealth Loop).

---

## 4. File Map & Dependencies
- `src/core/`: Global logic (MiasmaManager, SignalBus, CoordConverter).
- `src/vfx/`: Rendering (FogPainter, MiasmaHole.gdshader).
- `src/entities/`: Gameplay actors (DerelictLogic, BeamController).
- `src/scenes/`: Main World environment.