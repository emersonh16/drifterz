# Miasma Isometric Rendering - Goal Definition

## The Problem
The miasma (fog) is not rendering isometrically. There's a checkerboard pattern of uncleared tiles appearing, which suggests either:
1. The diamond polygons aren't covering the full tile area
2. The clearing logic is missing some tiles
3. There's a coordinate system mismatch between clearing and rendering

## The Goal
**Render cleared miasma tiles as seamless isometric diamonds that perfectly tile with no gaps or checkerboard patterns.**

## Current System State

### Grid System
- **Miasma Grid**: 16x8 pixels per tile (4x denser than 64x32 ground tiles)
- **Tile Center Formula**: `(grid_x * 16 + 8, grid_y * 8 + 4)`
- **Grid → World**: `CoordConverter.miasma_to_world_center(grid_pos)`

### Clearing Logic (MiasmaManager.gd)
- Uses world-pixel distance checks with Y-axis 2.0x scaling for isometric elliptical clearing
- Stores cleared tiles in `cleared_tiles: Dictionary<Vector2i, int>`
- Loop ranges: `ceil(radius / 16.0)` for X, `ceil(radius / 8.0)` for Y
- Distance check: `(dx*dx + dy*dy) <= r_sq` where `dy` is scaled by 2.0

### Rendering Logic (FogPainter.gd)
- Currently draws diamonds with offsets: `(0, -4), (8, 0), (0, 4), (-8, 0)` from tile center
- Uses `draw_colored_polygon()` with these 4 points
- Converts grid → world center → viewport-relative coordinates

## The Question
**What exactly is causing the checkerboard pattern?**

### Hypothesis 1: Diamond Size Issue
- The 16x8 diamond (8px horizontal, 4px vertical from center) might not cover the full tile area
- **Test**: Are the diamonds too small? Do they need to extend to tile boundaries?

### Hypothesis 2: Clearing Logic Issue
- The clearing algorithm might be missing tiles due to the elliptical distance check
- **Test**: Are all tiles that should be cleared actually in `cleared_tiles` dictionary?

### Hypothesis 3: Coordinate Mismatch
- The viewport-relative coordinate conversion might be causing positioning errors
- **Test**: Are diamonds being drawn at the correct positions relative to cleared tiles?

## What We Need to Agree On

1. **Diamond Geometry**: 
   - Should diamonds be exactly 16x8 (current: 8px horizontal, 4px vertical from center)?
   - Or should they extend to tile boundaries (0-16 horizontally, 0-8 vertically)?
   - Do they need to overlap slightly to prevent gaps?

2. **Coverage Requirement**:
   - Should each cleared tile render a diamond that covers its entire 16x8 area?
   - Or should diamonds tile seamlessly at their edges?

3. **Debugging Approach**:
   - Should we first verify that all expected tiles are in `cleared_tiles`?
   - Should we add debug visualization to see where diamonds are being drawn?
   - Should we test with a simple rectangle first to verify coordinates are correct?

## Next Steps
1. **Agree on the exact diamond geometry** (size and offsets)
2. **Verify clearing logic** is marking all expected tiles
3. **Verify rendering coordinates** are correct
4. **Test incrementally** - start with rectangles, then move to diamonds

