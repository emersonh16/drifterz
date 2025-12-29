# Gemini Prompt: FogMask SubViewport Not Rendering - Diagnostic Request

## Context
The DRIFTERZ project has a fog-of-war system that uses a SubViewport to render a mask texture. The SubViewport is not rendering anything (tested by changing background color to red - no red appears).

## Current Architecture

### Scene Structure
- **DerelictLogic.tscn** (Player scene):
  - `DerelictLogic` (CharacterBody2D)
    - `Camera2D` (main player camera)
      - `FogMask` (SubViewport) ← **NOT RENDERING**
        - `FogMaskColorRect` (ColorRect, full screen, black background)
        - `MaskSync` (Camera2D with script)
        - `FogPainter` (MultiMeshInstance2D with script)

- **World.tscn** (Main scene):
  - `World` (Node2D)
    - `DerelictLogic` (instanced from DerelictLogic.tscn)
    - `MiasmaSheet` (CanvasLayer)
      - `MiasmaColorRect` (ColorRect with MiasmaHole shader)
        - Shader uses ViewportTexture pointing to `DerelictLogic/Camera2D/FogMask`

### SubViewport Configuration (DerelictLogic.tscn)
- `size = Vector2i(1152, 648)`
- `render_target_update_mode = 4` (ALWAYS)
- `transparent_bg = false` (black background)

### FogMaskColorRect Configuration
- `anchors_preset = 15` (full screen)
- `anchor_right = 1.0`
- `anchor_bottom = 1.0`
- `grow_horizontal = 2`
- `grow_vertical = 2`
- `color = Color(0, 0, 0, 1)` (black)

### MaskSync Camera2D
- Script: `MaskSync.gd`
- Positioned at viewport center
- Syncs zoom/offset with parent camera

### FogPainter (MultiMeshInstance2D)
- Script: `FogPainter.gd`
- Uses MultiMesh with 16x8 texture stamp
- Rebuilds instances every frame based on `MiasmaManager.cleared_tiles`

## The Problem
**SubViewport is not rendering anything.** When `FogMaskColorRect` color is changed to red, no red appears on screen. This means the SubViewport render target is not being captured/displayed.

## What We've Verified
- ✅ SubViewport settings: `render_target_update_mode = 4` (ALWAYS)
- ✅ SubViewport size: `(1152, 648)` - matches window size
- ✅ FogMaskColorRect is full screen (anchors_preset = 15)
- ✅ No duplicate FogMask nodes (removed from World.tscn)
- ✅ ViewportTexture path is correct: `DerelictLogic/Camera2D/FogMask`
- ✅ Structure is correct: FogMask is child of Camera2D in DerelictLogic.tscn

## What We Haven't Checked
- ❓ Is MaskSync Camera2D enabled and set as current?
- ❓ Does SubViewport need a Camera2D to render 2D content?
- ❓ Is the SubViewport actually being processed/updated?
- ❓ Are there any errors preventing rendering?
- ❓ Does SubViewport need specific settings for 2D rendering?
- ❓ Is the render target actually being created?

## Key Questions for Gemini
1. **Does a SubViewport need a Camera2D to render 2D CanvasItems?** Or can it render without a camera?
2. **If Camera2D is needed, does it need to be "Current" or just "Enabled"?**
3. **What are the minimum requirements for a SubViewport to render 2D content?**
4. **Could the issue be that FogMask is inside an instanced scene (DerelictLogic.tscn)?**
5. **Are there any Godot 4.5 specific requirements for SubViewport rendering?**
6. **Should we test with a simple ColorRect first to verify SubViewport works at all?**

## Diagnostic Steps Needed
1. Verify MaskSync Camera2D is enabled and set as current
2. Test if SubViewport renders with a simple test (solid color rectangle)
3. Check if instanced scenes can have SubViewports that render correctly
4. Verify render target is actually being created
5. Check for any hidden errors or warnings

## Expected Behavior
- FogMask SubViewport should render black background
- FogPainter should draw white diamonds where fog is cleared
- ViewportTexture should capture this and feed it to the shader
- Shader should cut holes in fog overlay based on mask

## Current State
- Code is correct (FogPainter.gd, MaskSync.gd)
- Scene structure is correct (FogMask under Camera2D)
- Settings appear correct (render_target_update_mode = 4)
- **But SubViewport is not rendering anything**

## Your Task
Help diagnose why the SubViewport isn't rendering. Focus on:
1. **Camera2D requirements** - Does MaskSync need to be "Current"?
2. **SubViewport rendering prerequisites** - What's needed for 2D rendering?
3. **Instanced scene considerations** - Can SubViewports work inside instanced scenes?
4. **Simple test approach** - How to verify SubViewport works at all?

Provide step-by-step diagnostic steps and potential fixes. Be specific about what to check in the Godot editor.

