# Simple Fix Steps - One at a Time

## Step 1: Find FogMask SubViewport Settings

**In the Godot Editor:**

1. **Open the Scene**: Click `src/scenes/World.tscn` in FileSystem
2. **Find the Node**: In the Scene tree (left panel), look for:
   ```
   World
     └─ DerelictLogic
         └─ Camera2D
             └─ FogMask  ← CLICK THIS
   ```
3. **Click `FogMask`** node in the Scene tree
4. **Look at Inspector** (right panel):
   - Scroll down in Inspector
   - Look for section called **"SubViewport"**
   - You should see:
     - `Size` (Vector2i) - this is the size
     - `Render Target Update Mode` - this is what you need
     - `Transparent Bg` - checkbox

**If you don't see these:**
- Make sure you clicked the `FogMask` node (not FogPainter or FogMaskColorRect)
- The Inspector panel might be collapsed - look for a small arrow to expand sections

## Step 2: Check the Settings

Once you find the Inspector for FogMask:

1. **Render Target Update Mode**: Should be `4` (or "Always")
   - If it's not 4, click the dropdown and select "Always"
   
2. **Size**: Should match your window size
   - Default might be `(1152, 648)`
   - The code should sync this automatically, but check it's not `(0, 0)`

3. **Transparent Bg**: Should be **UNCHECKED** (we want black background)

## Step 3: Test if SubViewport is Rendering

**Quick visual test:**

1. In Scene tree, find `FogMaskColorRect` (inside FogMask)
2. Click it
3. In Inspector, find `Color` property
4. Change it from black `(0, 0, 0, 1)` to bright red `(1, 0, 0, 1)`
5. Run the game (F5)
6. **What you should see:**
   - If SubViewport is working: You'll see red background
   - If not working: Screen stays the same

**After test:**
- Change color back to black `(0, 0, 0, 1)`

## That's It For Now

Just do these 3 steps. Don't worry about anything else yet. Once you've checked these, let me know what you found.

