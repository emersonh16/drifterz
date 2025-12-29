# Fog Mask Rendering Diagnostic Guide

## What We're Trying To Do

**The Goal**: Create a fog-of-war system where:
1. **FogMask SubViewport** renders white diamonds on black background (the "mask")
2. **FogPainter** draws white diamonds where fog is cleared
3. **MiasmaHole shader** samples this mask and cuts holes in the fog overlay

**The Pipeline**:
```
MiasmaManager.cleared_tiles (data)
    ↓
FogPainter (MultiMeshInstance2D) draws white diamonds
    ↓
FogMask SubViewport captures this as texture
    ↓
ViewportTexture feeds to MiasmaHole shader
    ↓
Shader cuts holes in fog overlay (MiasmaColorRect)
```

## Diagnostic Checklist

### Step 1: Verify Data Exists
**Check**: Are tiles being cleared?
- Move the player around
- Check Output panel for any errors
- **Quick Test**: Add a print statement in `FogPainter._rebuild_multimesh()`:
  ```gdscript
  print("Cleared tiles count: ", MiasmaManager.cleared_tiles.size())
  ```

### Step 2: Verify FogPainter is Drawing
**Check**: Is the MultiMesh rendering?
- In editor, select `FogPainter` node
- Check Inspector - does it have a `multimesh` resource?
- Check Inspector - does it have a `texture` assigned?
- **Quick Test**: Temporarily change `FogMaskColorRect` color to RED - if you see red, SubViewport is rendering

### Step 3: Verify SubViewport Settings
**Check**: Is FogMask SubViewport configured correctly?
- Select `FogMask` SubViewport node
- Inspector should show:
  - `size`: Should match window size (or be synced by code)
  - `render_target_update_mode`: Should be `4` (ALWAYS)
  - `transparent_bg`: Should be `false` (we want black background)

### Step 4: Verify ViewportTexture Connection
**Check**: Is ViewportTexture pointing to the right path?
- Select `MiasmaColorRect` node
- In Inspector, find the `Material` property
- Expand the ShaderMaterial
- Check `mask_texture` parameter
- Should point to: `DerelictLogic/Camera2D/FogMask`
- **Critical**: Make sure `Local to Scene` is enabled on the ShaderMaterial

### Step 5: Verify Shader is Applied
**Check**: Is the shader actually running?
- Select `MiasmaColorRect` node
- Inspector should show `Material` with `MiasmaHole.gdshader`
- **Quick Test**: Change fog color in `MiasmaColorRect` - if color changes, shader is running

## Common Issues & Fixes

### Issue 1: FogMask is Black (No White Diamonds)
**Cause**: FogPainter isn't drawing or has no cleared tiles
**Fix**:
- Verify `MiasmaManager.cleared_tiles` has entries
- Check that `miasma_stamp.png` exists and is loaded
- Verify MultiMesh has instances: `multimesh.instance_count > 0`

### Issue 2: ViewportTexture Shows Nothing
**Cause**: ViewportTexture path is wrong or SubViewport isn't rendering
**Fix**:
- Check `viewport_path` in ViewportTexture resource
- Should be: `DerelictLogic/Camera2D/FogMask`
- Verify SubViewport `render_target_update_mode = 4` (ALWAYS)

### Issue 3: Shader Not Cutting Holes
**Cause**: Shader not sampling correctly or alpha logic wrong
**Fix**:
- Verify shader uses `SCREEN_UV` for sampling
- Check alpha logic: `COLOR.a = 1.0 - mask_sample.r`
- Verify `mask_texture` uniform is connected in material

### Issue 4: Everything is Black/Transparent
**Cause**: SubViewport size mismatch or coordinate issues
**Fix**:
- Check SubViewport size matches window size
- Verify `FogPainter` is syncing size: `parent_viewport.size = get_tree().root.size`

## Quick Visual Test

**Test 1: See the Mask Directly**
1. Temporarily change `FogMaskColorRect` color to bright RED
2. Run game - if you see red, SubViewport is rendering
3. Change back to black

**Test 2: See FogPainter Output**
1. In `FogPainter.gd`, temporarily change texture to a bright color
2. Or draw a test rectangle in `_draw()` function
3. Check if it appears in SubViewport

**Test 3: See Shader Output**
1. Temporarily change shader to: `COLOR = vec4(1.0, 0.0, 0.0, 1.0);` (solid red)
2. If fog becomes red, shader is running
3. Change back to mask sampling

## Step-by-Step Fix Process

1. **First**: Verify data exists - print `MiasmaManager.cleared_tiles.size()`
2. **Second**: Verify FogPainter is drawing - check MultiMesh instance count
3. **Third**: Verify SubViewport is rendering - test with colored background
4. **Fourth**: Verify ViewportTexture connection - check path in material
5. **Fifth**: Verify shader is working - test with solid color

Start with Step 1 and work through each step until you find where it breaks.

