# Update for Gemini - Coordinate System Centralization & Fog Alignment Fix

## Context

We just completed a refactoring to centralize coordinate math and fix fog alignment. The goal was to simplify the complex coordinate system situation documented in ONBOARDING.md and ensure the fog rendering properly aligns with the isometric ground tiles.

## What Was Done

### Problem Statement
The codebase had 8 different coordinate systems with conversions scattered across multiple files. The fog system was using a 64x64 square tile assumption when the actual ground tiles are 64x32 isometric. This caused misalignment and complexity.

### Solution: Centralized Coordinate Conversion

**1. CoordConverter.gd - Added Centralized Conversion**
- Added `world_to_miasma(pos: Vector2) -> Vector2i` static function
- Converts world coordinates to miasma grid coordinates using a 16x8 grid
- Miasma tiles are now 1/4 the size of ground tiles (64x32 ground → 16x8 miasma)
- Uses proper GDScript syntax: `floor(pos.x / 16)` (not `.floor()` method)

**2. MiasmaManager.gd - Updated Tile Constants**
- Changed from single `TILE_SIZE = 64` to:
  - `TILE_SIZE_WIDTH = 16`
  - `TILE_SIZE_HEIGHT = 8`
- Refactored `clear_fog()` to use `CoordConverter.world_to_miasma()` instead of inline conversion
- Updated radius calculations to use average tile size for isometric approximation
- All coordinate conversions now go through the centralized converter

**3. FogPainter.gd - Isometric Diamond Rendering**
- Replaced circle drawing with proper 16x8 isometric diamond polygons
- Each cleared tile now draws a diamond shape that matches isometric proportions
- Diamonds are exactly 1/4 the size of ground tiles (16x8 vs 64x32)
- Uses `draw_colored_polygon()` with 4 points: top, right, bottom, left

**4. World.tscn - Added Missing Camera**
- Added `MaskSync` Camera2D node inside `FogMask` SubViewport
- Attached `src/vfx/MaskSync.gd` script to the camera
- This was previously missing and causing fog mask alignment issues

## Current State

### What's Working
- Coordinate conversion is now centralized in `CoordConverter.world_to_miasma()`
- Miasma tiles use proper 16x8 dimensions (1/4 of ground tiles)
- FogPainter draws isometric diamonds instead of circles
- MaskSync camera is properly set up in the scene

### Known Issues / Areas Needing Refinement

1. **Isometric Diamond Drawing**: The current diamond drawing uses simple rectangular offsets (top/right/bottom/left). For true isometric alignment, we may need to account for the isometric projection angle. The diamonds might not perfectly align with the visual isometric tiles.

2. **Radius Calculation**: The `clear_fog()` function uses an average tile size `(TILE_SIZE_WIDTH + TILE_SIZE_HEIGHT) / 2.0` for radius calculations. This is an approximation that might not be perfectly accurate for isometric tiles.

3. **Circle Check Logic**: The distance check in `clear_fog()` still uses standard Euclidean distance (`dx*dx + dy*dy <= r2`). For isometric tiles, this might need adjustment to account for the different aspect ratio.

4. **Coordinate System Alignment**: While we've centralized the conversion, we need to verify that the 16x8 grid properly aligns with the 64x32 ground tiles. There might be offset issues or alignment problems.

5. **Visual Verification Needed**: The user mentioned it's "a little buggy" - we need to visually verify:
   - Do the miasma diamonds align with ground tile boundaries?
   - Are the diamonds the correct size (exactly 1/4)?
   - Does the fog clearing radius feel correct?
   - Is the fog mask properly aligned with the camera view?

## Design Questions for You

1. **Isometric Diamond Shape**: Should the diamond points account for the isometric projection angle? Currently using simple rectangular offsets, but true isometric might need different math.

2. **Grid Alignment**: The 16x8 grid divides evenly into 64x32 (4x4), but we need to verify the origin alignment. Should miasma grid (0,0) align with ground grid (0,0), or is there an offset?

3. **Radius Calculation**: For isometric tiles, should we use:
   - Average tile size (current approach)
   - Separate width/height calculations
   - True isometric distance formula

4. **FogPainter Optimization**: Currently draws every cleared tile every frame. Should we optimize this, or is the current approach acceptable for now?

## Next Steps

Please analyze the current implementation and propose:
1. Any fixes needed for the isometric diamond alignment
2. Improvements to the radius/distance calculations for isometric tiles
3. Verification of the coordinate system alignment
4. Any other refinements to make the fog system work perfectly

The foundation is in place with centralized coordinate conversion, but we need your design expertise to refine the isometric math and ensure perfect visual alignment.

## Files Changed
- `src/core/CoordConverter.gd` - Added `world_to_miasma()` function
- `src/core/MiasmaManager.gd` - Updated constants and refactored to use CoordConverter
- `src/vfx/FogPainter.gd` - Changed to draw isometric diamonds
- `src/scenes/World.tscn` - Added MaskSync camera node

## Reference
See ONBOARDING.md "Coordinate Systems Audit" section for full context on the complexity we're addressing.

