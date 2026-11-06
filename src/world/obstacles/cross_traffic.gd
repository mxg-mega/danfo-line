class_name CrossTraffic
extends "res://src/world/obstacles/obstacle_base.gd"

## Broken Traffic Light Intersection.
## Flashes a red/yellow warning for 2.5s, then shoots horizontal neon speeders across lanes!

const GameGlobals = preload("res://src/common/game_globals.gd")

enum State { WARNING, STREAKING, FINISHED }
var state: State = State.WARNING

var _timer: float = 0.0
var _warning_duration: float = 2.5
var _traffic_cars: Array[Dictionary] = [] # {"pos": Vector2, "vel": Vector2, "col": Color, "size": Vector2}

func _ready() -> void:
	obstacle_name = "Cross-Traffic"
	super._ready()
	_setup_collision()
	_init_traffic_cars()

func _setup_collision() -> void:
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(GameGlobals.ROAD_HALF_WIDTH * 2.0, 60.0)
	col.shape = shape
	add_child(col)

func _init_traffic_cars() -> void:
	# Car 1: moving left-to-right
	_traffic_cars.append({
		"pos": Vector2(-GameGlobals.ROAD_HALF_WIDTH - 80.0, -12.0),
		"vel": Vector2(1100.0, 0.0),
		"col": Color(1.0, 0.15, 0.35, 1.0), # Neon red
		"size": Vector2(50.0, 24.0)
	})
	# Car 2: moving right-to-left with staggered start
	_traffic_cars.append({
		"pos": Vector2(GameGlobals.ROAD_HALF_WIDTH + 140.0, 12.0),
		"vel": Vector2(-1250.0, 0.0),
		"col": Color(1.0, 0.85, 0.0, 1.0), # Neon yellow
		"size": Vector2(50.0, 24.0)
	})

func _process(delta: float) -> void:
	_timer += delta
	match state:
		State.WARNING:
			if _timer >= _warning_duration:
				state = State.STREAKING
				_timer = 0.0
		State.STREAKING:
			for car in _traffic_cars:
				car["pos"] += car["vel"] * delta
			if _timer >= 2.0:
				state = State.FINISHED
				queue_free()
				
	queue_redraw()

func _draw() -> void:
	var hw: float = GameGlobals.ROAD_HALF_WIDTH
	
	if state == State.WARNING:
		# Flashing yellow/red intersection boundary lines
		var flash: bool = (int(_timer * 8.0) % 2 == 0)
		var warn_color: Color = Color(1.0, 0.2, 0.2, 0.9) if flash else Color(1.0, 0.85, 0.0, 0.9)
		draw_line(Vector2(-hw, -28.0), Vector2(hw, -28.0), warn_color, 3.0)
		draw_line(Vector2(-hw, 28.0), Vector2(hw, 28.0), warn_color, 3.0)
		
		# Traffic light indicator box at curbs
		for side in [-1.0, 1.0]:
			var lx: float = (hw - 10.0) * side
			draw_circle(Vector2(lx, -20.0), 6.0, warn_color)
			draw_circle(Vector2(lx, 20.0), 6.0, warn_color)
			
	elif state == State.STREAKING:
		# Draw horizontal streak lines and speeder cars
		for car in _traffic_cars:
			var cpos: Vector2 = car["pos"]
			var csize: Vector2 = car["size"]
			var col: Color = car["col"]
			var rect: Rect2 = Rect2(cpos.x - csize.x * 0.5, cpos.y - csize.y * 0.5, csize.x, csize.y)
			
			# Car body
			draw_rect(rect, Color(0.05, 0.05, 0.08, 0.95), true)
			draw_rect(rect, col, false, 2.0)
			
			# Light streaks
			var streak_dir: float = -1.0 if car["vel"].x > 0 else 1.0
			draw_line(cpos, cpos + Vector2(streak_dir * 120.0, 0.0), Color(col.r, col.g, col.b, 0.4), 2.5)

func _on_hit_bus(bus: Node) -> void:
	if state != State.STREAKING:
		return
	is_triggered = true
	if bus.has_method("trigger_crash"):
		bus.call("trigger_crash", "Cross-Traffic Collision")
		
	var am: Node = get_tree().root.find_child("AudioManager", true, false)
	if am and am.has_method("play_crash"):
		am.call("play_crash")
		
	var cam: Node = get_tree().root.find_child("FollowCamera2D", true, false)
	if cam and cam.has_method("apply_shake"):
		cam.call("apply_shake", 0.5, 16.0)
