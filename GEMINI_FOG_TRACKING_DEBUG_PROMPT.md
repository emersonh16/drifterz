# Critical Issue: Fog Tracking Still Broken - Need Architectural Analysis

## Situation

We've been trying to fix the fog-of-war (Miasma) tracking system for multiple iterations, but the cleared "hole" in the fog is still not staying locked to the player's position. Despite multiple attempts, we're not making progress. We need your design expertise to analyze the architecture and identify the root cause.

## Current System Architecture

### The Fog Rendering Pipeline

1. **MiasmaManager** clears tiles in world space using absolute world-pixel distance checks
2. **FogPainter** (inside FogMask SubViewport) draws 16x8 rectangles for each cleared tile
3. **MaskSync** (Camera2D in FogMask SubViewport) syncs with main camera
4. **MiasmaHole shader** (on MiasmaColorRect in CanvasLayer) samples the mask texture and inverts it

### Scene Hierarchy

```
World (Node2D)
├── WorldGrid (TileMapLayer) - Ground layer
├── DerelictLogic (CharacterBody2D) - Player with Camera2D
├── MiasmaSheet (CanvasLayer)
│   └── MiasmaColorRect (ColorRect) - Full screen, uses MiasmaHole shader
└── FogMask (SubViewport) - 1152x648, render_target_update_mode = 4 (Always)
    ├── MaskSync (Camera2D) - Syncs with main camera
    ├── FogMaskColorRect (ColorRect) - Black background
    └── FogPainter (Node2D) - Draws cleared tiles
```

## What We've Tried (Multiple Iterations)

### Attempt 1: Coordinate System Centralization
- Centralized coordinate conversions in `CoordConverter`
- Fixed fog clearing to use world-pixel distance checks
- Changed from circles to isometric diamonds
- **Result**: Still had checkerboard pattern

### Attempt 2: Geometry Fix
- Changed from diamond polygons to full 16x8 rectangles
- Hardcoded exact rectangle positions
- **Result**: Checkerboard fixed, but tracking still broken

### Attempt 3: MaskSync Camera Sync
- Made MaskSync copy `global_position`, `zoom`, and `offset` from main camera
- Added SubViewport size syncing to match window size
- **Result**: Still drifting/misaligned

### Attempt 4: Shader Alignment
- Changed shader to use `SCREEN_UV` instead of `UV`
- Set MiasmaColorRect to Full Rect layout
- Added mouse_filter = 2 (Ignore)
- **Result**: Still not tracking correctly

## Current Code State

### MaskSync.gd
```gdscript
extends Camera2D

func _ready() -> void:
	process_priority = 100

func _process(_delta: float) -> void:
	# Sync SubViewport size to match main window size
	var parent_viewport := get_parent() as SubViewport
	if parent_viewport:
		var main_viewport := get_tree().root.get_viewport()
		if main_viewport:
			parent_viewport.size = main_viewport.get_visible_rect().size
	
	# Get the main viewport's active camera
	var main_viewport := get_tree().root.get_viewport()
	if not main_viewport:
		return
	
	var main_camera: Camera2D = main_viewport.get_camera_2d()
	if not main_camera:
		return
	
	# Copy all camera properties from main camera
	global_position = main_camera.global_position
	zoom = main_camera.zoom
	offset = main_camera.offset
```

### MiasmaHole.gdshader
```glsl
shader_type canvas_item;
uniform sampler2D mask_texture;

void fragment() {
	vec4 base_color = COLOR;
	vec4 mask_sample = texture(mask_texture, SCREEN_UV);
	base_color.a = 1.0 - mask_sample.r;
	COLOR = base_color;
}
```

### FogPainter.gd
- Draws 16x8 rectangles using `draw_rect()`
- Uses `CoordConverter.miasma_to_world_center()` to get world positions
- Rect: `Rect2(world_center - Vector2(8, 4), Vector2(16, 8))`

## The Persistent Problem

**The cleared fog "hole" is not staying locked to the player's position on screen.** When the camera moves or the window resizes, the fog clearing drifts or becomes misaligned.

## Key Questions for You

1. **Coordinate Space Mismatch?**
   - FogPainter draws in world coordinates inside a SubViewport
   - MaskSync camera syncs with main camera
   - MiasmaHole shader uses SCREEN_UV on a CanvasLayer
   - Are these coordinate spaces properly aligned?

2. **SubViewport Rendering Issue?**
   - The SubViewport has a fixed size (1152x648) but we're syncing it to window size
   - The mask texture is sampled using SCREEN_UV
   - Is there a resolution/aspect ratio mismatch causing drift?

3. **Camera Sync Timing?**
   - MaskSync runs with process_priority = 100
   - Is it syncing at the right time in the frame?
   - Should it use `_process` or `_physics_process`?

4. **Shader Sampling Problem?**
   - Using SCREEN_UV on a CanvasLayer
   - The mask texture comes from a SubViewport
   - Is SCREEN_UV the right coordinate system for this setup?

5. **Fundamental Architecture Flaw?**
   - Is the SubViewport + CanvasLayer + Shader approach fundamentally misaligned?
   - Should we be using a different rendering strategy?

## What We Need From You

Please analyze the architecture and propose:

1. **Root Cause Analysis**: What is the fundamental issue causing the drift/misalignment?

2. **Architectural Solution**: Should we:
   - Change the coordinate system approach?
   - Modify the rendering pipeline?
   - Use a different synchronization method?
   - Restructure the scene hierarchy?

3. **Specific Fixes**: If the current architecture can work, what specific changes are needed?

4. **Alternative Approaches**: If the current approach is fundamentally flawed, what alternative architecture would work better?

## Constraints

- We're using Godot 4.5
- The fog clearing logic (MiasmaManager) is working correctly
- The issue is purely with the visual alignment/tracking
- We need the cleared area to stay locked to the player's screen position

## Success Criteria

The cleared elliptical "hole" in the fog must:
- Stay perfectly centered on the player sprite on screen
- Remain locked even when the camera moves
- Stay aligned when the window is resized
- Work consistently across different resolutions

We've tried multiple incremental fixes but haven't solved the core issue. We need your design expertise to identify the root cause and propose a solution that will actually work.

