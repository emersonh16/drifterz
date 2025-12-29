# Prompt to Gemini: Fog Mask Alignment Solution

## Context
We successfully fixed the fog mask alignment issue in our Godot 4.5 isometric game. The fog mask (SubViewport) now perfectly tracks with the player camera, and the cleared "bubble" is centered on the player at all times.

## Problem We Solved
The fog mask was misaligned - the cleared area (bubble) was offset from the player position, appearing in the top-left corner instead of centered. Additionally, we needed to ensure the fog mask texture stayed perfectly synced with the camera movement.

## Solution Architecture

### 1. SubViewport Hierarchy
- **FogMask SubViewport** is now a **child of the main Camera2D** (`DerelictLogic/Camera2D/FogMask`)
- This allows the SubViewport to automatically inherit the camera's transform
- The SubViewport moves with the camera, eliminating drift issues

### 2. MaskSync Camera (Inside SubViewport)
- Added a `Camera2D` node (`MaskSync`) inside the SubViewport to render the fog mask
- **Position**: Set to viewport center (`viewport.size / 2.0`) in SubViewport coordinate space
- **Sync**: Copies `zoom` and `offset` from the main camera each frame
- **Purpose**: The camera at viewport center ensures the SubViewport's origin (camera world position) appears at the center of the rendered texture

### 3. FogPainter Drawing Logic
- Draws in **SubViewport-relative coordinates** with viewport center offset
- Formula: `viewport_relative = (world_center - camera_world_pos) + viewport_center`
- This ensures:
  - When player is at camera world position → draws at `(0, 0) + viewport_center` = **centered**
  - All cleared tiles are drawn relative to camera position
  - The cleared bubble stays locked to the player's screen position

### 4. Resolution Parity
- `FogPainter` syncs SubViewport size to window size: `get_parent().size = get_tree().root.size`
- Ensures 1:1 mapping between SubViewport texture and screen space

### 5. Shader Sampling
- `MiasmaHole.gdshader` uses `SCREEN_UV` for screen-space sampling
- With resolution parity and camera-relative viewport, this provides perfect alignment

## Key Technical Details

**Coordinate Space Understanding:**
- SubViewport as child of Camera2D → SubViewport's origin is at camera's world position
- Camera inside SubViewport at viewport center → looks at SubViewport origin at viewport center
- Drawing at `(world_pos - camera_world_pos) + viewport_center` → centers the drawing

**Why This Works:**
1. SubViewport moves with camera (no manual sync needed for transform)
2. Camera at viewport center ensures correct view alignment
3. Viewport center offset in drawing centers the cleared area on player
4. Resolution parity ensures texture-to-screen mapping is 1:1

## Files Modified
- `src/scenes/World.tscn`: Moved FogMask to be child of Camera2D, added MaskSync camera
- `src/vfx/MaskSync.gd`: Camera sync script (positioned at viewport center, syncs zoom/offset)
- `src/vfx/FogPainter.gd`: Drawing with viewport center offset
- `src/vfx/MiasmaHole.gdshader`: Uses SCREEN_UV for sampling

## Result
✅ Fog mask tracks perfectly with camera movement  
✅ Cleared bubble is centered on player at all times  
✅ No drift or misalignment issues  
✅ Works at all screen positions and window sizes  

## Next Steps / Questions
This solution is working well. Are there any optimizations or improvements you'd suggest for this architecture? Any edge cases we should consider (camera zoom changes, screen rotation, etc.)?

