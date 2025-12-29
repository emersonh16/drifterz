# Gemini Takeover Prompt: MultiMesh Fog System Setup Completion

## Context
The DRIFTERZ project has implemented a MultiMesh-based fog-of-war rendering system. The code is complete and working, but the user needs help completing the final setup steps in the Godot editor.

## Current Status
- ✅ **Code Complete**: `FogPainter.gd` is fully implemented as `MultiMeshInstance2D`
- ✅ **Texture Created**: User has created `misama_stamp.png` (16x8 isometric diamond) in LibreSprite and saved it to `src/vfx/`
- ⚠️ **Filename Mismatch**: File is named `misama_stamp.png` but code expects `miasma_stamp.png` (typo: missing 'i')
- ⚠️ **Import Settings**: User cannot find the Import tab to set Lossless compression and Nearest filter
- ⚠️ **Node Type**: User mentioned manually changing FogPainter to MultiMeshInstance2D in editor (should be verified)

## Immediate Tasks

### 1. Fix Filename (Critical)
The code in `FogPainter.gd` line 27 loads: `"res://src/vfx/miasma_stamp.png"`
But the file is named: `misama_stamp.png` (missing 'i' in "miasma")

**Options:**
- **Option A (Recommended)**: Rename file in FileSystem to `miasma_stamp.png`
- **Option B**: Update code to match current filename

### 2. Set Import Settings (Critical)
The texture needs specific import settings for pixel-perfect rendering:
- **Compress Mode**: `Lossless` (not Lossy or VRAM Compressed)
- **Filter**: `Nearest` (not Linear)

**How to Access Import Settings:**
- Select the PNG file in FileSystem dock
- Look for "Import" tab in bottom panel (may be hidden or need to be opened)
- Alternative: Project → Reimport menu option
- Alternative: Right-click file → Reimport

### 3. Verify Node Type
- Open `src/scenes/World.tscn`
- Navigate to `DerelictLogic/Camera2D/FogMask/FogPainter`
- Verify node type is `MultiMeshInstance2D` (not `Node2D`)

## Technical Details

### File Locations
- Texture file: `src/vfx/miasma_stamp.png` (or `misama_stamp.png` if not renamed)
- FogPainter script: `src/vfx/FogPainter.gd`
- Main scene: `src/scenes/World.tscn`

### Code Reference
The `FogPainter.gd` script:
- Extends `MultiMeshInstance2D`
- Loads texture in `_ready()`: `load("res://src/vfx/miasma_stamp.png")`
- Uses `TEXTURE_FILTER_NEAREST` for pixel-perfect rendering
- Rebuilds MultiMesh instances every frame based on `MiasmaManager.cleared_tiles`

### Expected Behavior
Once setup is complete:
- No errors about missing texture file
- Fog clearing should show isometric diamond shapes (not rectangles)
- Diamonds should interlock perfectly with zero gaps
- No checkerboard patterns or visual artifacts

## User's Current Situation
- User is in Godot 4.5.1 editor
- Has the texture file created but can't find Import settings
- May have filename typo issue
- Needs step-by-step guidance through editor UI

## Your Role
1. **Guide the user** through finding and setting Import settings in Godot editor
2. **Help resolve** the filename mismatch issue
3. **Verify** the setup is complete and working
4. **Troubleshoot** any remaining issues
5. **Be patient** - user is learning the Godot editor interface

## Key Principles
- **Don't modify code** unless absolutely necessary (user preference)
- **Focus on editor steps** - this is an editor configuration task
- **Explain what each setting does** - user wants to understand
- **Provide alternatives** if standard methods don't work
- **Verify success** - make sure it actually works after setup

## Success Criteria
- ✅ Texture file exists with correct name (`miasma_stamp.png`)
- ✅ Import settings: Lossless + Nearest
- ✅ No errors in Output panel when running game
- ✅ Fog rendering shows diamond shapes correctly
- ✅ No visual artifacts or checkerboard patterns

## Files to Reference
- `src/vfx/FogPainter.gd` - Main rendering script
- `src/scenes/World.tscn` - Scene file (verify node types)
- `ARCHITECTURE.md` - System documentation
- `ONBOARDING.md` - Project documentation

## Notes
- User prefers visual/editor-based solutions over code changes when possible
- User is actively learning Godot editor interface
- Be clear and concise with instructions
- If Import tab is truly inaccessible, suggest alternative methods (Project menu, etc.)

Good luck! Help the user complete this setup so the MultiMesh fog system works perfectly.

