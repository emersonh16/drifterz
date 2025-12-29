# Miasma Stamp Texture Creation Instructions

## Required Asset: `miasma_stamp.png`

**Location**: `src/vfx/miasma_stamp.png`

**Specifications**:
- **Size**: 16x8 pixels (exact)
- **Format**: PNG with transparency
- **Content**: Solid white isometric diamond shape
- **Purpose**: Used as a texture stamp for MultiMesh rendering to ensure watertight coverage

## Creation Steps

### Option 1: Using Image Editor (GIMP, Photoshop, etc.)

1. Create a new image: **16 pixels wide × 8 pixels tall**
2. Set background to **transparent**
3. Draw a white isometric diamond:
   - The diamond should fill the entire 16x8 rectangle
   - Top point at (8, 0)
   - Right point at (16, 4)
   - Bottom point at (8, 8)
   - Left point at (0, 4)
4. Fill the diamond with **solid white** (RGB: 255, 255, 255)
5. Save as PNG with transparency

### Option 2: Using Godot's Built-in Editor

1. Open Godot
2. Go to **Project → Tools → Create Image**
3. Set size to **16×8**
4. Use the **Polygon Tool** to draw the diamond:
   - Points: (8, 0), (16, 4), (8, 8), (0, 4)
5. Fill with white
6. Export as PNG

### Option 3: Quick Test (Solid Rectangle)

For immediate testing, you can temporarily use a **solid white 16×8 rectangle**:
- Create a 16×8 image
- Fill entirely with white (no transparency needed for testing)
- Save as `miasma_stamp.png` in `src/vfx/`

**Note**: The solid rectangle will work for testing, but the diamond shape is preferred for the final isometric aesthetic.

## Verification

After creating the texture:
1. Place it at `src/vfx/miasma_stamp.png`
2. Run the game
3. The MultiMesh should render without errors
4. Check that tiles interlock perfectly with zero gaps

