# ARCHITECTURE V2.0 - The Physical Sandwich Strategy

## Current Status: WORKING FOUNDATION

**The Math is Perfect**: The world-space coordinate system is proven to work. The "white snake" diagnostic test confirmed that `FogPainter` correctly renders cleared tiles at fixed world coordinates with zero drift.

**The Rendering Method**: We are using the **Physical Sandwich** approach - simple z-index layering that draws grass-colored quads on top of the dark fog overlay.

---

## The Foundation: World-Space Truth

This architecture eliminates coordinate drift by anchoring all fog rendering to **world coordinates**. The fog clearing is permanent and world-space, not camera-relative.

---

## The Five Pillars

### 1. World-Space Truth
**Every fog diamond is stamped at a FIXED world coordinate.**

- Example: A cleared tile at grid position `(10, 5)` is rendered at world center `(168, 44)`.
- Formula: `world_center = Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)`
- **No camera math**: The position is absolute, never relative to the camera.
- **No screen-space conversion**: Tiles exist in world space, period.

### 2. The Iron Node
**FogPainter (MultiMeshInstance2D) is a DIRECT child of 'World'.**

- Location: `World/FogPainter` (NOT under Camera2D)
- Position: `(0, 0)` in world space
- Transform: All MultiMesh instances use world coordinates directly
- **No parent transforms**: FogPainter is not affected by camera movement

### 3. No Complex Systems
**We are using simple z-index layering. No shaders, no masks, no SubViewports.**

- No `FogMask` SubViewport
- No `ViewportTexture` resources
- No `BackBufferCopy` nodes
- No shader materials
- No `CanvasGroup` clipping
- No `Light2D` masking
- **Just z-index layering**: Draw grass-colored quads on top of fog

### 4. Physical Sandwich Rendering
**The fog system uses z-index layering to create the illusion of revealed ground.**

- **Layer -10**: `WorldGrid` (grass floor)
- **Layer -5**: `MiasmaOverlay` (dark fog ColorRect)
- **Layer 0**: `FogPainter` (grass-colored diamonds)
- **Layer 10**: `DerelictLogic` (player)

The `FogPainter` draws grass-colored quads on top of the dark fog, creating the visual effect of revealed ground without needing transparency or complex masking.

### 5. The Grid
**16x8 pixels per tile. Formula: Vector2i(floor(pos.x / 16.0), floor(pos.y / 8.0)).**

- **Tile Size**: 16 pixels wide × 8 pixels tall
- **Grid Conversion**: `Vector2i(floor(world_pos.x / 16.0), floor(world_pos.y / 8.0))`
- **World Center**: `Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)`
- **Alignment**: Miasma grid (0,0) = World (0,0) = Ground grid (0,0)

---

## Node Hierarchy

```
World (Node2D)
├─ WorldGrid (TileMapLayer, z_index: -10)
├─ MiasmaOverlay (ColorRect, z_index: -5)
├─ FogPainter (MultiMeshInstance2D, z_index: 0)
├─ DerelictLogic (CharacterBody2D, z_index: 10)
│   └─ Camera2D
```

**Key Points:**
- FogPainter is NOT under Camera2D
- FogPainter position is (0, 0) in world space
- All MultiMesh instances use world coordinates
- Simple z-index layering - no complex systems

---

## Coordinate System

### World → Grid
```gdscript
func world_to_miasma(world_pos: Vector2) -> Vector2i:
    return Vector2i(floor(world_pos.x / 16.0), floor(world_pos.y / 8.0))
```

### Grid → World Center
```gdscript
func miasma_to_world_center(grid_pos: Vector2i) -> Vector2:
    return Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)
```

**Note**: We use world **center** (not origin) to align the 16x8 mesh center with the grid cell center.

---

## Rendering Pipeline

### Step 1: Data Storage
- `MiasmaManager.cleared_tiles` stores `Vector2i` grid coordinates
- This is the **Source of Truth** - persistent, additive
- Player calls `MiasmaManager.clear_fog(global_position, 64.0)` every frame

### Step 2: World-Space Rendering
- `FogPainter` reads `cleared_tiles` dictionary in `_process()`
- For each cleared tile:
  - Convert grid → world center: `world_center = Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)`
  - Create transform: `Transform2D(0, world_center)` ← **NO CAMERA MATH**
  - Set MultiMesh instance transform
  - Render grass-colored quad (16x8 QuadMesh with green modulate)

### Step 3: Visual Layering
- Dark fog (`MiasmaOverlay`) covers everything at z-index -5
- Grass-colored diamonds (`FogPainter`) render on top at z-index 0
- Creates the illusion of revealed ground

---

## The Anti-Drift Guarantee

**Why this eliminates drift:**

1. **Fixed World Positions**: Every tile is rendered at its absolute world coordinate. It never moves.
2. **No Camera Dependency**: FogPainter is not a child of Camera2D, so camera movement doesn't affect it.
3. **No Screen-Space Conversion**: We never convert world → screen. The camera simply "looks at" the world-space fog.
4. **Single Coordinate System**: Everything uses world pixels. No mixing of coordinate spaces.

**The Result**: Fog clearing stays exactly where it is, forever. No jitter, no drift, no recalculation.

---

## Current Implementation

### MiasmaManager.gd
- Autoload singleton
- `cleared_tiles: Dictionary` - stores cleared grid positions
- `clear_fog(world_pos: Vector2, radius: float)` - adds tiles to cleared_tiles

### FogPainter.gd
- Extends `MultiMeshInstance2D`
- Direct child of `World` node
- Uses `QuadMesh` (16x8 size)
- `self_modulate = Color(0.4, 0.6, 0.3, 1.0)` - meadow green
- Renders at world coordinates (no camera math)

### World.tscn Structure
- `WorldGrid`: z_index -10 (grass floor)
- `MiasmaOverlay`: z_index -5 (dark fog ColorRect, 10000x10000)
- `FogPainter`: z_index 0 (grass-colored diamonds)
- `DerelictLogic`: z_index 10 (player)

---

## What We Tried (And Why We Abandoned)

### Failed Approaches:
1. **Shader Masking**: Tried using `SCREEN_TEXTURE` to sample and discard white pixels. Failed due to Godot's screen texture limitations.
2. **Light2D Masking**: Tried using `PointLight2D` in Mask mode. Failed due to complexity and inversion issues.
3. **CanvasGroup Clipping**: Tried using `Clip Only` mode. Failed because it clips to bounds, not pixel content.
4. **BackBufferCopy + Shaders**: Multiple attempts with different shader approaches. All failed due to screen texture sampling issues.

### What Works:
- **Physical Sandwich**: Simple z-index layering. Draw grass-colored quads on top of fog. No transparency needed, no complex systems.

---

## The Director's Summary

**The Old Way (Failed):**
- Complex shader systems trying to create transparent holes
- Screen texture sampling that never worked reliably
- Multiple layers of abstraction (SubViewports, BackBufferCopy, etc.)

**The New Way (Working):**
- Simple z-index layering
- World-space coordinates (proven to work)
- Grass-colored quads drawn on top of dark fog
- No transparency, no masks, just visual layering

**The Analogy:**
- **Old**: Trying to cut holes in glass using lasers and mirrors
- **New**: Painting green squares on a black sheet. Simple, effective, works.

---

## Next Steps (Future Improvements)

1. **Texture Matching**: Replace solid green color with actual `meadow2.png` texture for perfect visual match
2. **Diamond Shape**: Use `miasma_stamp.png` texture instead of solid quads for isometric diamond shape
3. **Performance**: Optimize MultiMesh rebuilding (only rebuild when cleared_tiles changes)
4. **Regrowth System**: Add fog regrowth over time using the timestamp stored in cleared_tiles

---

## Status: FOUNDATION COMPLETE

✅ World-space coordinate system working  
✅ Zero drift confirmed  
✅ Fog clearing data structure working  
✅ Basic rendering working (Physical Sandwich)  
⏳ Visual polish (texture matching, diamond shape)  
⏳ Performance optimization  
⏳ Regrowth system
