# Miasma Stamp Texture Creation Instructions

## Required Asset: `miasma_stamp.png`

**Location:** `src/vfx/miasma_stamp.png`  
**Size:** 16x8 pixels (exact)  
**Format:** PNG with transparency  
**Content:** Solid white isometric diamond shape

## Creation Steps:

### Option 1: Using Godot's Built-in Editor
1. Open Godot Editor
2. Go to **Project → Tools → Create Image**
3. Set size to **16x8 pixels**
4. Use the drawing tools to create a white isometric diamond:
   - The diamond should fill the 16x8 rectangle
   - Top point at (8, 0)
   - Right point at (16, 4)
   - Bottom point at (8, 8)
   - Left point at (0, 4)
5. Fill the diamond with **white (RGB: 255, 255, 255)**
6. Background should be **transparent (alpha: 0)**
7. Export as PNG to `src/vfx/miasma_stamp.png`

### Option 2: Using External Image Editor (GIMP, Photoshop, etc.)
1. Create a new image: **16x8 pixels**, transparent background
2. Draw a white isometric diamond:
   - Vertices: (8, 0), (16, 4), (8, 8), (0, 4)
   - Fill with white (RGB: 255, 255, 255)
3. Save as PNG to `src/vfx/miasma_stamp.png`

### Option 3: Quick Python Script (if you have PIL/Pillow)
```python
from PIL import Image, ImageDraw

# Create 16x8 transparent image
img = Image.new('RGBA', (16, 8), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Draw white isometric diamond
diamond_points = [
    (8, 0),   # Top
    (16, 4),  # Right
    (8, 8),   # Bottom
    (0, 4)    # Left
]
draw.polygon(diamond_points, fill=(255, 255, 255, 255))

# Save
img.save('src/vfx/miasma_stamp.png')
```

## Visual Reference:
```
     (8,0)
       *
      / \
     /   \
(0,4) *---* (16,4)
     \   /
      \ /
       *
     (8,8)
```

## Important Notes:
- **Exact size is critical:** 16x8 pixels (no scaling)
- **White fill:** RGB(255, 255, 255) for proper mask sampling
- **Transparent background:** Alpha channel must be 0 outside the diamond
- **Pixel-perfect:** The diamond should touch all edges of the 16x8 rectangle

Once created, the MultiMesh system will automatically use this texture for watertight isometric coverage.

