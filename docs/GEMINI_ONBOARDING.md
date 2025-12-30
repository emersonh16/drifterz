# DRIFTERZ - Gemini Onboarding Prompt

## Project Context
**DRIFTERZ** is a Godot 4.5 game featuring a dynamic fog-of-war system called "Miasma" that clears as the player moves. The fog system uses **Portal Rendering** - a shader-based approach that reveals the ground texture underneath the fog by calculating aligned UV coordinates.

## Current System Status: ✅ WORKING

The fog system is **fully functional** with:
- ✅ World-space coordinate system (zero drift confirmed)
- ✅ Portal rendering with texture alignment
- ✅ Performance optimization (only rebuilds when tiles change)
- ✅ Buffer management (removes distant tiles)

---

## Core Architecture: The Portal System

### The Foundation: World-Space Truth

**Every fog stamp is rendered at a FIXED world coordinate.**

- Formula: `world_center = Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)`
- **No camera math**: Positions are absolute, never relative to camera
- **No screen-space conversion**: Tiles exist in world space, period

### The Grid System

- **Miasma Tile Size**: 16 pixels wide × 8 pixels tall
- **World Tile Size**: 64 pixels wide × 32 pixels tall (isometric)
- **Relationship**: 4 miasma stamps fit in each world tile (4×4 grid)
- **Grid Conversion**: `Vector2i(floor(world_pos.x / 16.0), floor(world_pos.y / 8.0))`
- **World Center**: `Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)`

---

## Key Components

### 1. MiasmaManager (`src/core/MiasmaManager.gd`)

**Autoload singleton** - The Source of Truth for cleared fog tiles.

```gdscript
var cleared_tiles: Dictionary = {}  # Key: Vector2i, Value: int (timestamp)
```

**Functions:**
- `clear_fog(world_pos: Vector2, radius: float)` - Adds tiles to cleared_tiles
- `buffer_check(player_pos: Vector2)` - Removes distant tiles (every 60 frames)

**Key Behavior:**
- **Persistent & Additive**: Tiles are only added, never removed (except by buffer_check)
- **World-Space**: All calculations use world pixel coordinates
- **Grid Law**: Converts world → grid using `Vector2i(floor(pos.x / 16.0), floor(pos.y / 8.0))`

### 2. FogPainter (`src/vfx/FogPainter.gd`)

**Extends `MultiMeshInstance2D`** - Renders cleared fog using portal shader.

**Configuration:**
- **Mesh**: `QuadMesh` (16×8 size)
- **Transform Format**: `TRANSFORM_2D`
- **Texture Filter**: `TEXTURE_FILTER_NEAREST` (pixel-perfect)
- **Material**: `ShaderMaterial` with `FogPainterPortal.gdshader`

**Key Behavior:**
- **Performance**: Only rebuilds MultiMesh when `cleared_tiles.size()` changes
- **World-Space**: All instance transforms use absolute world coordinates
- **Portal Effect**: Uses shader to reveal ground texture with aligned UVs

**Important Constants:**
```gdscript
const WORLD_TILE_WIDTH: float = 64.0
const WORLD_TILE_HEIGHT: float = 32.0
const STAMP_WIDTH: float = 16.0
const STAMP_HEIGHT: float = 8.0
```

### 3. FogPainterPortal.gdshader (`src/vfx/FogPainterPortal.gdshader`)

**Portal Shader** - Reveals ground texture with perfect alignment.

**How It Works:**
1. Gets world position from `VERTEX.xy` (already in world space)
2. Calculates grid position: `floor(world_pos / stamp_size)`
3. Calculates quadrant offset: `(grid_pos % 4) * 0.25`
4. Samples texture at: `quadrant_offset + (UV * 0.25)`

**Key Points:**
- **INSTANCE_CUSTOM Not Available**: `INSTANCE_CUSTOM` doesn't exist in `canvas_item` shaders
- **Solution**: Calculate quadrant from world position directly in shader
- **UV Alignment**: Each stamp samples 1/4 of the 64×32 texture (0.25 scale)
- **Fallback**: Uses meadow green `Color(0.4, 0.6, 0.3)` if texture is missing/white

**Shader Uniforms:**
- `ground_texture` (sampler2D) - The meadow2.png texture
- `world_tile_width` (float) - 64.0
- `world_tile_height` (float) - 32.0
- `stamp_width` (float) - 16.0
- `stamp_height` (float) - 8.0

### 4. Beam System (`src/systems/beam/Beam.gd`)

**Located at**: `DerelictLogic/Beam`

**Function:**
- Calls `MiasmaManager.clear_fog(player_pos, clearing_radius)` every frame
- Calls `MiasmaManager.buffer_check(player_pos)` every 60 frames

**Configuration:**
- `clearing_radius: float = 64.0` (world pixels)

---

## Node Hierarchy

```
World (Node2D)
├─ WorldGrid (TileMapLayer, z_index: -10)
│  └─ Uses meadow2.png texture (64×32 tiles)
├─ MiasmaOverlay (ColorRect, z_index: -5)
│  └─ Dark fog color: #0f141a, size: 10000×10000
├─ FogPainter (MultiMeshInstance2D, z_index: 0)
│  └─ Portal rendering with shader
└─ DerelictLogic (CharacterBody2D, z_index: 10)
   ├─ Camera2D
   └─ Beam (Node2D)
      └─ Handles fog clearing input
```

**Key Points:**
- `FogPainter` is a **direct child of World** (NOT under Camera2D)
- `FogPainter` position is `(0, 0)` in world space
- All MultiMesh instances use world coordinates directly

---

## Coordinate System Reference

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

**Critical**: Always use explicit float division (`/ 16.0`, not `/ 16`) to prevent alignment bugs.

---

## Portal Rendering: How It Works

### The Quadrant System

Since 4 miasma stamps (16×8) fit in each world tile (64×32), each stamp needs to sample the correct **quadrant** of the texture:

- **Quadrant 0**: UV offset (0.0, 0.0) - Top-left
- **Quadrant 1**: UV offset (0.0, 0.25) - Top-right
- **Quadrant 2**: UV offset (0.25, 0.0) - Bottom-left
- **Quadrant 3**: UV offset (0.25, 0.25) - Bottom-right

**Calculation:**
```gdscript
var mod_x: int = grid_pos.x % 4
var mod_y: int = grid_pos.y % 4
if mod_x < 0: mod_x += 4  # Handle negative modulo
if mod_y < 0: mod_y += 4
var quadrant_offset := Vector2(mod_x * 0.25, mod_y * 0.25)
```

**In Shader:**
```glsl
float grid_x = floor(world_pos.x / stamp_width);
float grid_y = floor(world_pos.y / stamp_height);
float mod_x = mod(grid_x, 4.0);
float mod_y = mod(grid_y, 4.0);
if (mod_x < 0.0) mod_x += 4.0;
if (mod_y < 0.0) mod_y += 4.0;
vec2 quadrant_offset = vec2(mod_x * 0.25, mod_y * 0.25);
vec2 final_uv = quadrant_offset + (UV * 0.25);
```

---

## Common Tasks

### Adding a New Fog Clearing Source

1. Get world position: `var world_pos: Vector2 = global_position`
2. Call manager: `MiasmaManager.clear_fog(world_pos, radius)`
3. That's it! `FogPainter` will automatically render it.

### Modifying the Portal Shader

**Important Constraints:**
- `INSTANCE_CUSTOM` is **NOT available** in `canvas_item` shaders
- Must calculate quadrant from `VERTEX.xy` (world position)
- Use `mod()` not `fmod()` in GLSL
- Always handle negative modulo values

### Debugging Alignment Issues

1. **Check Grid Math**: Verify `world_to_miasma()` and `miasma_to_world_center()` formulas
2. **Check Shader UV**: Verify quadrant calculation matches GDScript logic
3. **Check Texture**: Ensure `meadow2.png` is 64×32 and imported correctly
4. **Check Transform**: Verify `FogPainter` position is `(0, 0)` in world space

---

## Performance Considerations

### Current Optimizations

1. **Rebuild Only on Change**: `FogPainter` only rebuilds MultiMesh when `cleared_tiles.size()` changes
2. **Buffer Management**: `MiasmaManager.buffer_check()` removes distant tiles every 60 frames
3. **MultiMesh Batching**: All stamps rendered in single draw call

### Future Optimizations

- Spatial partitioning for buffer check
- Regrowth system (remove old tiles based on timestamp)
- LOD system for distant fog

---

## Important Rules

### Law 1: World-Space Only
**All fog rendering MUST be world-space. Never subtract camera position from tile origins.**

### Law 2: The Iron Node
**FogPainter must extend MultiMeshInstance2D and stay positioned at World (0,0).**

### Law 3: No Camera Transforms
**No coordinate transforms involving the camera are permitted for the miasma grid.**

### Law 4: Portal Rendering
**Use shader-based portal rendering to reveal ground texture with aligned UVs.**

### Law 5: Physical Sandwich
**Use simple z-index layering. Avoid complex shaders, masks, or SubViewports.**

---

## File Structure

```
src/
├── core/
│   ├── MiasmaManager.gd          ✅ Source of Truth
│   └── CoordConverter.gd           ✅ Coordinate utilities
├── vfx/
│   ├── FogPainter.gd              ✅ Portal renderer
│   └── FogPainterPortal.gdshader  ✅ Portal shader
├── systems/
│   └── beam/
│       └── Beam.gd                ✅ Fog clearing input
├── scenes/
│   └── World.tscn                 ✅ Main scene
└── entities/
    └── DerelictLogic.gd            ✅ Player
```

---

## Current Status Summary

✅ **Working:**
- World-space coordinate system (zero drift)
- Portal rendering with texture alignment
- Performance optimization (rebuild on change)
- Buffer management (distant tile removal)

⏳ **Future Work:**
- Regrowth system (fog returns over time)
- Visual polish (diamond shape stamps)
- Additional performance optimizations

---

## Quick Reference

**Clear Fog:**
```gdscript
MiasmaManager.clear_fog(global_position, 64.0)
```

**Get Cleared Tiles:**
```gdscript
var tiles = MiasmaManager.cleared_tiles.keys()
```

**World → Grid:**
```gdscript
var grid = Vector2i(floor(world_pos.x / 16.0), floor(world_pos.y / 8.0))
```

**Grid → World Center:**
```gdscript
var center = Vector2(grid_pos.x * 16.0 + 8.0, grid_pos.y * 8.0 + 4.0)
```

---

**Last Updated**: Current Session  
**Status**: Portal Rendering System Complete ✅

