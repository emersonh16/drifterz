# DRIFTERZ - AI ARCHITECTURAL CONSTITUTION

You are an expert Godot 4.5 Engine developer. You must adhere to the following PROJECT CONSTITUTION without deviation.

## 1. THE ISOMETRIC LAW (COORDINATES)
- [cite_start]**Miasma Grid**: 16x8 pixels per tile (4x denser than 64x32 ground tiles). 
- **Coordinate Integrity**: All world-to-grid conversions MUST use explicit float division and floor(): `Vector2i(floor(pos.x / 16.0), floor(pos.y / 8.0))`. [cite_start]Never use integer division. 
- [cite_start]**Isometric Distance**: Use the flattened formula for clearing: `(dx*dx + (dy*2.0)*(dy*2.0)) <= r_sq`. 
- [cite_start]**Clearing Buffer**: Always use a +4px radius buffer to prevent missing edge tiles due to the 2:1 isometric ratio. 

## 2. THE DATA AUTHORITY (MIASMA)
- [cite_start]**Additive Only**: The `cleared_tiles` dictionary in `MiasmaManager.gd` is the PERSISTENT SOURCE OF TRUTH. 
- [cite_start]**Never Clear**: Do not call `cleared_tiles.clear()` unless specifically instructed for a "Reset Game" feature. 
- **Persistence**: Tiles are only added. [cite_start]Future regrowth will handle removal based on timestamps. 

## 3. THE RENDERING HIERARCHY (VIEWPORTS)
- [cite_start]**Camera-Local Hierarchy**: The `FogMask` SubViewport MUST remain a child of `Camera2D` for automatic transform inheritance. 
- [cite_start]**Resolution Parity**: Always sync SubViewport size to window size: `get_parent().size = get_tree().root.size`. 
- [cite_start]**Diamond Geometry**: FogPainter MUST draw isometric diamonds using exact offsets: `(0, -4), (8, 0), (0, 4), (-8, 0)` from the tile center. 

## 4. WORKFLOW RULES
- [cite_start]**Plan First**: Reference `ARCHITECTURE.md` before every code change. [cite: 2]
- **Surgical Edits**: Only modify the specific function requested. [cite_start]Do not "optimize" or delete surrounding sync logic. 
- [cite_start]**Documentation**: Update `ARCHITECTURE.md` and `ONBOARDING.md` whenever a core logic change is finalized.