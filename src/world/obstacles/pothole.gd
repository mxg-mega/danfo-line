class_name Pothole
extends "res://src/world/obstacles/obstacle_base.gd"

## Pothole: Dark crater with pulsating neon rim. Slows down bus on hit.

const GameGlobals = preload("res://src/common/game_globals.gd")

@export var radius: float = 24.0
var _pulse: float = 0.0

func _ready() -> void:
	obstacle_name = "Pothole"
	super._ready()
	_setup_collision()

func _setup_collision() -> void:
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	col.shape = shape
	add_child(col)

func _process(delta: float) -> void:
	_pulse += delta * 5.0
	queue_redraw()

func _draw() -> void:
	# Dark inner void
	draw_circle(Vector2.ZERO, radius, Color(0.005, 0.005, 0.008, 0.95))
	
	# Jagged rim lines
	var rim_color: Color = Color(1.0, 0.85, 0.05, 0.7 + sin(_pulse) * 0.25)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 16, rim_color, 2.0)
	draw_arc(Vector2.ZERO, radius * 0.7, 0.0, TAU, 12, Color(rim_color.r, rim_color.g, rim_color.b, 0.3), 1.5)

func _on_hit_bus(bus: Node) -> void:
	is_triggered = true
	if bus.has_method("apply_pothole_hit"):
		bus.call("apply_pothole_hit", 0.8)
	
	# Play sound if audio manager present
	var am: Node = get_tree().root.find_child("AudioManager", true, false)
	if am and am.has_method("play_pothole"):
		am.call("play_pothole")
		
	# Subtle shake on camera
	var cam: Node = get_tree().root.find_child("FollowCamera2D", true, false)
	if cam and cam.has_method("apply_shake"):
		cam.call("apply_shake", 0.25, 6.0)
