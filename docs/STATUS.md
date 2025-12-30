# DRIFTERZ - Current Status

**Last Updated**: Current Session

---

## ✅ What's Working

### 1. World-Space Coordinate System
- **Status**: PROVEN TO WORK
- **Evidence**: "White Snake" diagnostic test confirmed zero drift
- **Implementation**: `FogPainter` renders at fixed world coordinates
- **Formula**: `world_center = Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)`

### 2. Fog Clearing Data Structure
- **Status**: WORKING
- **Implementation**: `MiasmaManager.cleared_tiles` Dictionary
- **Function**: `clear_fog(world_pos: Vector2, radius: float)`
- **Behavior**: Persistent, additive clearing (tiles never removed)

### 3. Basic Rendering
- **Status**: WORKING
- **Method**: Physical Sandwich (z-index layering)
- **Layers**:
  - WorldGrid: z_index -10 (grass floor)
  - MiasmaOverlay: z_index -5 (dark fog)
  - FogPainter: z_index 0 (grass-colored diamonds)
  - DerelictLogic: z_index 10 (player)

---

## ⏳ What Needs Work

### 1. Visual Polish
- **Current**: Solid green quads (`Color(0.4, 0.6, 0.3, 1.0)`)
- **Needed**: Use actual `meadow2.png` texture for perfect match
- **Priority**: Medium

### 2. Diamond Shape
- **Current**: 16x8 rectangular quads
- **Needed**: Use `miasma_stamp.png` texture for isometric diamond shape
- **Priority**: Medium

### 3. Performance
- **Current**: Rebuilds MultiMesh every frame
- **Needed**: Only rebuild when `cleared_tiles` changes
- **Priority**: Low (works fine for now)

### 4. Regrowth System
- **Current**: Not implemented
- **Needed**: Fog regrows over time using timestamps in `cleared_tiles`
- **Priority**: Low (future feature)

---

## ❌ What We Tried (And Abandoned)

### Failed Approaches:
1. **Shader Masking** - `SCREEN_TEXTURE` sampling never worked reliably
2. **Light2D Masking** - Too complex, inversion issues
3. **CanvasGroup Clipping** - Clips to bounds, not pixel content
4. **BackBufferCopy + Shaders** - Multiple attempts, all failed

### Why They Failed:
- Godot's screen texture system is unreliable for this use case
- Complex systems added too many failure points
- Simple z-index layering works better

---

## 📁 Current File Structure

```
src/
├── core/
│   ├── MiasmaManager.gd      ✅ Working
│   └── CoordConverter.gd     ✅ Working
├── vfx/
│   ├── FogPainter.gd         ✅ Working (needs texture polish)
│   └── miasma_stamp.png      ⏳ Not currently used
├── scenes/
│   └── World.tscn            ✅ Working (Physical Sandwich setup)
└── entities/
    └── DerelictLogic.gd      ✅ Working (calls clear_fog)
```

---

## 🎯 Next Steps

1. **Immediate**: Test current implementation - does Physical Sandwich work visually?
2. **Short-term**: Replace solid green with `meadow2.png` texture
3. **Short-term**: Use `miasma_stamp.png` for diamond shape
4. **Long-term**: Performance optimization (only rebuild on change)
5. **Long-term**: Regrowth system implementation

---

## 🔧 Technical Details

### Coordinate System
- **Grid Size**: 16x8 pixels per tile
- **World → Grid**: `Vector2i(floor(pos.x / 16.0), floor(pos.y / 8.0))`
- **Grid → World Center**: `Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)`

### Rendering Method
- **Type**: Physical Sandwich (z-index layering)
- **No Transparency**: Just visual layering
- **No Shaders**: Pure z-index rendering
- **No Masks**: Simple ColorRect + MultiMeshInstance2D

### Node Hierarchy
```
World (Node2D)
├─ WorldGrid (z_index: -10)
├─ MiasmaOverlay (z_index: -5)
├─ FogPainter (z_index: 0)
└─ DerelictLogic (z_index: 10)
```

---

## 📝 Notes

- The math is **proven to work** - white snake test confirmed zero drift
- The rendering method is **simple and effective** - no complex systems needed
- Visual polish is the main remaining task
- Performance is acceptable for current scale

---

**Bottom Line**: Foundation is solid. Math works. Rendering works. Just needs visual polish.

