# UV Fix Failed - Mask Texture Still Misaligned

## Current Situation

We tried changing the shader from `SCREEN_UV` to `UV` to fix the mask texture alignment, but it didn't work. The mask texture is still not aligned with the screen.

## What's Working

1. **Cleared Hole (FogPainter)**: ✅ **PERFECT**
   - The white rectangles drawn by FogPainter follow the player correctly
   - They stay centered on the player sprite on screen
   - No drift, works perfectly

2. **Fog Overlay (MiasmaSheet)**: ✅ **CORRECT**
   - The translucent blue fog layer is fixed to the screen
   - It's infinite and covers everything
   - Works as intended

3. **MaskSync Camera**: ✅ **SYNCING**
   - Copies `global_position`, `zoom`, and `offset` from main camera every frame
   - SubViewport size is synced to window size: `get_parent().size = get_tree().root.size`
   - Process priority = 100 (runs after player movement)

## What's Broken

**Mask Texture Alignment**: ❌ **STILL MISALIGNED**

The mask texture (from FogMask SubViewport) is:
- Not centered on the screen
- Remains stationary relative to the world when the player moves
- Doesn't spawn completely aligned

The fog overlay (MiasmaSheet) is correct, but the mask texture that makes it opaque is misaligned.

## Current Implementation

### MiasmaHole.gdshader
```glsl
shader_type canvas_item;
uniform sampler2D mask_texture;

void fragment() {
	vec4 base_color = COLOR;
	// Currently using UV (tried SCREEN_UV before, didn't work either)
	vec4 mask_sample = texture(mask_texture, UV);
	base_color.a = 1.0 - mask_sample.r;
	COLOR = base_color;
}
```

### MaskSync.gd
```gdscript
extends Camera2D

func _ready() -> void:
	process_priority = 100

func _process(_delta: float) -> void:
	# Sync SubViewport size to match actual window size (resolution parity)
	var parent_viewport := get_parent() as SubViewport
	if parent_viewport:
		parent_viewport.size = get_tree().root.size
	
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

### FogPainter.gd
```gdscript
func _draw() -> void:
	if MiasmaManager.cleared_tiles.is_empty():
		return

	# Draw 16x8 rectangles for each cleared tile
	for grid_pos in MiasmaManager.cleared_tiles.keys():
		var world_center := CoordConverter.miasma_to_world_center(grid_pos)
		var rect := Rect2(world_center - Vector2(8, 4), Vector2(16, 8))
		draw_rect(rect, Color.WHITE)
```

### World.tscn Structure
```
World (Node2D)
├── MiasmaSheet (CanvasLayer)
│   └── MiasmaColorRect (Full Rect, mouse_filter = Ignore)
│       └── MiasmaHole.gdshader (samples mask_texture)
└── FogMask (SubViewport, size synced to window, render_target_update_mode = 4)
    ├── MaskSync (Camera2D) - syncs with main camera
    ├── FogMaskColorRect (black background)
    └── FogPainter (Node2D) - draws cleared tiles in world space
```

## The Problem

**The mask texture is world-space, but we need it to be screen-space.**

- FogPainter draws in **world coordinates** (inside SubViewport with MaskSync camera)
- MaskSync camera syncs with main camera (so it renders the same world view)
- The mask texture is a **ViewportTexture** from the SubViewport
- The shader samples this texture on a **screen-space ColorRect** (in CanvasLayer)
- **UV coordinates don't align** because the texture is world-space but we're sampling it in screen-space

## What We've Tried

1. **SCREEN_UV**: Didn't work - mask was misaligned
2. **UV**: Didn't work - mask still misaligned
3. **follow_viewport_enabled = true**: Broke the fog overlay completely (made it disappear)
4. **Resolution parity**: SubViewport size = window size (this is correct but not enough)

## The Core Issue

The SubViewport renders a **world-space view** (via MaskSync camera), but we need to sample it as if it were **screen-space**. 

The mask texture should represent "what's cleared on screen" not "what's cleared in the world". But FogPainter draws in world coordinates, so the mask is inherently world-space.

## Questions for You

1. **Should FogPainter draw in screen coordinates instead of world coordinates?**
   - This would make the mask screen-space
   - But then how do we know what's cleared on screen vs in the world?

2. **Should we transform the UV coordinates in the shader?**
   - Account for camera position/zoom to map world-space texture to screen-space UVs?
   - This seems complex and error-prone

3. **Is there a fundamental architecture issue?**
   - Should the SubViewport render in screen-space, not world-space?
   - But then how does FogPainter know where to draw?

4. **Should we use a different approach entirely?**
   - Render the mask differently?
   - Use a different coordinate system?

## What We Need

The mask texture must align with the screen so that:
- When the player is at screen center, the cleared hole is at screen center
- When the camera moves, the mask moves with it (stays aligned)
- The mask represents "cleared areas visible on screen" not "cleared areas in world"

## Current State Summary

- ✅ Fog clearing logic works (MiasmaManager)
- ✅ Cleared hole rendering works (FogPainter draws correctly)
- ✅ Camera sync works (MaskSync mirrors main camera)
- ✅ Resolution parity works (SubViewport size = window size)
- ❌ Mask texture sampling doesn't align (UV/SCREEN_UV both fail)
- ❌ Mask texture is world-space but needs to be screen-space

We need your design expertise to solve this coordinate space mismatch. The mask texture needs to align with the screen, but it's being rendered in world space. How do we bridge this gap?

