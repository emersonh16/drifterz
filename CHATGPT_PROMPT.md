# DRIFTERZ Codebase Overview

I'm working on a Godot 4.5 game called DRIFTERZ with a fog-of-war system called "Miasma". Here's my codebase structure:

## Project Structure
```
drifterz/
├── World.gd                    # Main world script (generates 80x80 tile grid)
├── src/
│   ├── core/
│   │   ├── MiasmaManager.gd   # Autoload singleton - manages fog clearing
│   │   └── SignalBus.gd        # Autoload singleton - signal-based communication
│   ├── entities/
│   │   └── DerelictLogic.gd   # Player character (CharacterBody2D)
│   ├── data/
│   │   └── DerelictStats.gd   # Resource class for player stats
│   ├── vfx/
│   │   ├── FogPainter.gd      # Draws cleared fog areas
│   │   └── MiasmaHole.gdshader # Shader for fog mask
│   └── world.tscn             # Main scene
```

## Key Systems

### 1. MiasmaManager (Autoload Singleton)
Manages the fog clearing system:
- `cleared_tiles: Dictionary` - Key: `Vector2i` (grid coords), Value: `int` (timestamp)
- `TILE_SIZE = 64` constant
- `clear_fog(world_pos: Vector2, radius: float)` - Clears circular area using circle math (dx² + dy² ≤ r²)
- Listens to `SignalBus.derelict_moved` and auto-clears ~200px radius around player

**Code:**
```gdscript
extends Node
var cleared_tiles: Dictionary = {}
const TILE_SIZE: int = 64

func _ready() -> void:
	SignalBus.derelict_moved.connect(_on_derelict_moved)

func _on_derelict_moved(new_position: Vector2) -> void:
	clear_fog(new_position, 200.0)

func clear_fog(world_pos: Vector2, radius: float) -> void:
	var center_grid: Vector2i = (world_pos / TILE_SIZE).floor()
	var radius_in_tiles: int = ceil(radius / TILE_SIZE)
	var r2: float = (radius / TILE_SIZE) ** 2
	
	for x in range(center_grid.x - radius_in_tiles, center_grid.x + radius_in_tiles + 1):
		for y in range(center_grid.y - radius_in_tiles, center_grid.y + radius_in_tiles + 1):
			var tile_pos := Vector2i(x, y)
			var dx: float = x - (world_pos.x / TILE_SIZE)
			var dy: float = y - (world_pos.y / TILE_SIZE)
			
			if dx*dx + dy*dy <= r2:
				if not cleared_tiles.has(tile_pos):
					cleared_tiles[tile_pos] = Time.get_ticks_msec()
```

### 2. DerelictLogic (Player)
CharacterBody2D that moves with WASD/Arrow keys:
- Uses `DerelictStats` resource (max_speed: 300.0)
- Emits `SignalBus.derelict_moved(global_position)` when moving

**Code:**
```gdscript
extends CharacterBody2D
@export var stats: Resource = preload("res://src/data/DefaultStats.tres")

func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * stats.max_speed
	move_and_slide()
	
	if velocity != Vector2.ZERO:
		SignalBus.derelict_moved.emit(global_position)
```

### 3. SignalBus (Autoload Singleton)
Decoupled communication system:
```gdscript
extends Node
signal derelict_moved(new_position: Vector2)
```

### 4. FogPainter
Node2D that draws white circles where fog is cleared:
- Child of `FogMask` SubViewport
- Draws every frame
- Reads from `MiasmaManager.cleared_tiles` dictionary
- Draws white circles (shader inverts: white = transparent holes)

**Code:**
```gdscript
extends Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var hole_color = Color.WHITE
	var tile_size = MiasmaManager.TILE_SIZE
	
	for grid_pos in MiasmaManager.cleared_tiles:
		var draw_pos = Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)
		var center = draw_pos + Vector2(tile_size / 2.0, tile_size / 2.0)
		draw_circle(center, tile_size / 1.5, hole_color)
```

### 5. Scene Structure (world.tscn)
```
World (Node2D)
├── WorldGrid (TileMapLayer) - 80x80 isometric tiles (64x32 tile size)
├── DerelictLogic (CharacterBody2D) - Player at (500, 300)
├── MiasmaSheet (CanvasLayer)
│   └── MiasmaColorRect (ColorRect with MiasmaHole shader)
└── FogMask (SubViewport, 1152x648)
    ├── FogMaskColorRect (ColorRect, black background)
    ├── MaskCamera (Camera2D) - Syncs with main camera
    └── FogPainter (Node2D) - Draws cleared areas
```

### 6. Shader (MiasmaHole.gdshader)
Inverts mask texture: `base_color.a = 1.0 - mask_sample.r`
- White pixels → Alpha 0 (transparent holes)
- Black pixels → Alpha 1 (opaque fog)

## How It Works
1. Player moves → `DerelictLogic` emits `SignalBus.derelict_moved`
2. `MiasmaManager` receives signal → calls `clear_fog()` → stores cleared tiles in dictionary
3. `FogPainter` draws white circles for each cleared tile
4. Shader reads FogMask texture → inverts it → controls fog ColorRect alpha
5. Result: Fog everywhere except where player has been

## Design Patterns
- Autoload singletons (MiasmaManager, SignalBus)
- Signal-based communication (decoupled systems)
- Resource-based stats (DerelictStats)
- Shader-based fog rendering (mask texture inversion)
- SubViewport for fog mask rendering

## Technical Details
- Godot 4.5
- Isometric tiles (64x32 pixels)
- Tile size: 64 units
- Fog clearing uses circle math (no square holes)
- Timestamps stored for future regrowth logic

