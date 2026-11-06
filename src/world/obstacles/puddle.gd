class_name Puddle
extends "res://src/world/obstacles/obstacle_base.gd"

## Leaking Pipe Puddle: Pulsing blue ellipse that makes steering slippery for 2 seconds.

@export var radius_x: float = 45.0
@export var radius_y: float = 24.0

var _ripple_phase: float = 0.0

func _ready() -> void:
	obstacle_name = "Puddle"
	super._ready()
	_setup_collision()

func _setup_collision() -> void:
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(radius_x * 2.0, radius_y * 2.0)
	col.shape = shape
	add_child(col)

func _process(delta: float) -> void:
	_ripple_phase += delta * 3.5
	queue_redraw()

func _draw() -> void:
	var puddle_color: Color = Color(0.0, 0.75, 1.0, 0.3)
	var rim_color: Color = Color(0.0, 0.95, 1.0, 0.8)
	
	# Translucent body
	_draw_ellipse(Vector2.ZERO, radius_x, radius_y, puddle_color, true)
	_draw_ellipse(Vector2.ZERO, radius_x, radius_y, rim_color, false, 2.0)
	
	# Expanding inner ripple
	var ripple_t: float = fmod(_ripple_phase, 1.0)
	var rx: float = radius_x * ripple_t
	var ry: float = radius_y * ripple_t
	var ripple_alpha: float = (1.0 - ripple_t) * 0.6
	_draw_ellipse(Vector2.ZERO, rx, ry, Color(0.0, 0.95, 1.0, ripple_alpha), false, 1.5)

func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color, filled: bool, line_width: float = 1.0) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 24
	for i in range(segments):
		var angle: float = (float(i) / float(segments)) * TAU
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	if filled:
		draw_colored_polygon(points, col)
	else:
		points.append(points[0])
		draw_polyline(points, col, line_width)

func _on_hit_bus(bus: Node) -> void:
	if bus.has_method("apply_puddle_slip"):
		bus.call("apply_puddle_slip", 2.0)
		
	var am: Node = get_tree().root.find_child("AudioManager", true, false)
	if am and am.has_method("play_puddle"):
		am.call("play_puddle")
