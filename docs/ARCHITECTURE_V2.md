# ARCHITECTURE V2.0 - The Stencil Strategy

## The Foundation: World-Space Truth

This architecture eliminates coordinate drift by anchoring all fog rendering to **world coordinates**. The fog mask is a permanent "stencil" cut into the world, not a moving overlay.

---

## The Five Pillars

### 1. World-Space Truth
**Every fog diamond is stamped at a FIXED world coordinate.**

- Example: A cleared tile at grid position `(10, 5)` is rendered at world position `(160, 80)`.
- Formula: `world_pos = Vector2(grid_pos.x * 16.0, grid_pos.y * 8.0)`
- **No camera math**: The position is absolute, never relative to the camera.
- **No screen-space conversion**: Tiles exist in world space, period.

### 2. The Iron Node
**FogPainter (MultiMeshInstance2D) is a DIRECT child of 'World'.**

- Location: `World/FogPainter` (NOT under Camera2D)
- Position: `(0, 0)` in world space
- Transform: All MultiMesh instances use world coordinates directly
- **No parent transforms**: FogPainter is not affected by camera movement

### 3. No SubViewports
**We are removing all SubViewport/ViewportTexture logic.**

- No `FogMask` SubViewport
- No `ViewportTexture` resources
- No `MaskSync` Camera2D
- Fog rendering happens directly in world space
- The fog overlay uses a simple blend mode or direct subtraction shader

### 4. Blend Mode
**The fog overlay will use a simple "Screen" blend mode or a direct subtraction shader.**

- Option A: CanvasLayer with Screen blend mode (simple, built-in)
- Option B: Custom shader that subtracts fog mask from fog overlay
- No complex ViewportTexture sampling
- No SCREEN_UV coordinate conversion

### 5. The Grid
**16x8 pixels per tile. Formula: Vector2i(floor(pos.x / 16.0), floor(pos.y / 8.0)).**

- **Tile Size**: 16 pixels wide × 8 pixels tall
- **Grid Conversion**: `Vector2i(floor(world_pos.x / 16.0), floor(world_pos.y / 8.0))`
- **World Origin**: `Vector2(grid_pos.x * 16.0, grid_pos.y * 8.0)`
- **Alignment**: Miasma grid (0,0) = World (0,0) = Ground grid (0,0)

---

## Node Hierarchy

```
World (Node2D)
├─ WorldGrid (TileMapLayer)
├─ DerelictLogic (CharacterBody2D)
│   └─ Camera2D
└─ FogPainter (MultiMeshInstance2D) ← DIRECT CHILD OF WORLD
```

**Key Points:**
- FogPainter is NOT under Camera2D
- FogPainter position is (0, 0) in world space
- All MultiMesh instances use world coordinates

---

## Coordinate System

### World → Grid
```gdscript
func world_to_miasma(world_pos: Vector2) -> Vector2i:
    return Vector2i(floor(world_pos.x / 16.0), floor(world_pos.y / 8.0))
```

### Grid → World Origin
```gdscript
func miasma_to_world_origin(grid_pos: Vector2i) -> Vector2:
    return Vector2(grid_pos.x * 16.0, grid_pos.y * 8.0)
```

### Grid → World Center
```gdscript
func miasma_to_world_center(grid_pos: Vector2i) -> Vector2:
    var origin = miasma_to_world_origin(grid_pos)
    return Vector2(origin.x + 8.0, origin.y + 4.0)
```

---

## Rendering Pipeline

### Step 1: Data Storage
- `MiasmaManager.cleared_tiles` stores `Vector2i` grid coordinates
- This is the **Source of Truth** - persistent, additive

### Step 2: World-Space Rendering
- `FogPainter` reads `cleared_tiles` dictionary
- For each cleared tile:
  - Convert grid → world origin: `world_origin = miasma_to_world_origin(grid_pos)`
  - Create transform: `Transform2D(0, world_origin)` ← **NO CAMERA MATH**
  - Set MultiMesh instance transform

### Step 3: Fog Overlay
- CanvasLayer with fog ColorRect covers screen
- Uses Screen blend mode OR subtraction shader
- No ViewportTexture needed

---

## The Anti-Drift Guarantee

**Why this eliminates drift:**

1. **Fixed World Positions**: Every tile is rendered at its absolute world coordinate. It never moves.
2. **No Camera Dependency**: FogPainter is not a child of Camera2D, so camera movement doesn't affect it.
3. **No Screen-Space Conversion**: We never convert world → screen. The camera simply "looks at" the world-space fog.
4. **Single Coordinate System**: Everything uses world pixels. No mixing of coordinate spaces.

**The Result**: Fog holes stay exactly where they are cut, forever. No jitter, no drift, no recalculation.

---

## Implementation Checklist

- [ ] Create `FogPainter.gd` extending `MultiMeshInstance2D`
- [ ] Add `FogPainter` node to `World.tscn` as direct child of `World`
- [ ] Set `FogPainter` position to `(0, 0)`
- [ ] Implement `_rebuild_multimesh()` using world coordinates only
- [ ] Create fog overlay CanvasLayer with Screen blend mode
- [ ] Remove all SubViewport/ViewportTexture logic
- [ ] Update `CoordConverter` to use world-space formulas
- [ ] Test: Move camera, verify fog holes stay fixed in world

---

## Migration Notes

**What Changed:**
- FogPainter moved from `Camera2D/FogMask/FogPainter` → `World/FogPainter`
- Removed SubViewport architecture
- Removed camera-relative coordinate math
- Simplified fog overlay (no ViewportTexture)

**What Stayed:**
- Grid system (16x8 tiles)
- `MiasmaManager.cleared_tiles` dictionary
- MultiMesh rendering strategy
- Texture stamp (`miasma_stamp.png`)

---

## The Director's Summary

**The Old Way (Failed):**
- FogPainter was a child of Camera2D
- Every frame, we calculated: `screen_pos = (world_pos - camera_pos) + viewport_center`
- This caused drift because camera position changed every frame

**The New Way (Zero Drift):**
- FogPainter is a child of World
- Every frame, we use: `world_pos = grid_pos * tile_size`
- Camera just "looks at" the world. Fog doesn't move.

**The Analogy:**
- **Old**: Cutting holes in a sheet of paper taped to a moving spotlight
- **New**: Cutting holes in a table. The spotlight just moves over it.

