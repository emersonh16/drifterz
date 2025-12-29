# ARCHITECTURE.md - The Holy Map (v1.0)

## 1. Coordinate System Registry
| Space | Unit | Resolution | Conversion Formula | Converter Function |
| :--- | :--- | :--- | :--- | :--- |
| **World** | `Vector2` | $1:1$ Pixels | N/A | N/A |
| **Ground Grid** | `Vector2i` | $64 \times 32$ | $f(W) = \text{floor}(W.x/64, W.y/32)$ | (Godot TileMapLayer) |
| **Miasma Grid** | `Vector2i` | $16 \times 8$ | $f(W) = \text{floor}(W.x/16, W.y/8)$ | `CoordConverter.world_to_miasma()` |
| **Miasma → World** | `Vector2` | Center point | $f(G) = (G.x \times 16 + 8, G.y \times 8 + 4)$ | `CoordConverter.miasma_to_world_center()` |
| **Isometric** | `Vector2` | Projected | $(x - y, (x + y) * 0.5)$ | `CoordConverter.to_isometric()` (unused) |

---

## 2. Node & System Hierarchy
### Core Singletons (Autoloads)
* **MiasmaManager.gd**: Data authority for cleared tiles (Sparse Dictionary). Uses world-pixel distance checks for elliptical fog clearing.
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
                * **FogPainter (Node2D)**: Draws 16x8 rectangles for cleared Miasma. Handles SubViewport size syncing.
    * **MiasmaSheet (CanvasLayer)**: Full-screen ColorRect with `MiasmaHole.gdshader`. Fixed to screen (`follow_viewport_enabled = false`).

---

## 3. Systems Integration

### Miasma Engine
* **Granularity**: The Miasma grid is 4x denser than the ground grid ($16 \times 8$ pixels per sub-tile).
* **Clearing Algorithm**: Uses absolute world-pixel distance checks with isometric Y-axis flattening (2.0x scaling) for elliptical clearing:
  - Calculates `r_sq = radius * radius` in world pixels (no average tile size approximation)
  - Sets loop ranges: X uses `ceil(radius / 16.0)`, Y uses `ceil(radius / 8.0)` to cover full ellipse
  - For each tile in the bounding box:
    - Gets tile's world center: `t_world = CoordConverter.miasma_to_world_center(tile_pos)`
    - Calculates world-pixel distance: `dx = t_world.x - world_pos.x`, `dy = (t_world.y - world_pos.y) * 2.0`
    - Clears tile only if `(dx*dx + dy*dy) <= r_sq` (absolute world-pixel check)
  - This ensures solid elliptical clearing with no checkerboard pattern
* **Rendering**: 
  - FogPainter draws 16x8 rectangles using `draw_rect()` to ensure full coverage
  - FogPainter enforces SubViewport size parity: `get_parent().size = get_tree().root.size` (synced to window size)
  - FogMask SubViewport is a child of Camera2D, so it automatically inherits the camera's transform (position, zoom, offset)
  - This eliminates the need for MaskSync - the viewport naturally follows the camera
  - MiasmaSheet CanvasLayer is fixed to screen (`follow_viewport_enabled = false`)
  - MiasmaHole shader uses `SCREEN_UV` for screen-space sampling: ColorRect covers full screen, mask texture is camera-relative
  - With resolution parity and camera-relative viewport, SCREEN_UV provides correct screen-space alignment
* **3D Volume**: Achieved via a parallax-offset shader pass in `MiasmaHole.gdshader` to simulate height/volume.
* **Persistence**: `cleared_tiles` dictionary stores `Vector2i` keys representing Miasma sub-tiles.

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