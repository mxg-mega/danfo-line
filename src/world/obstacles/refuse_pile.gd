class_name RefusePile
extends "res://src/world/obstacles/obstacle_base.gd"

## Refuse Pile: Jagged cluster of neon trash lines. Counts as a full crash.

@export var pile_width: float = 64.0
@export var pile_height: float = 38.0

var _points: Array[Vector2] = []

func _ready() -> void:
	obstacle_name = "Refuse Pile"
	super._ready()
	_generate_jagged_points()
	_setup_collision()

func _generate_jagged_points() -> void:
	var half_w: float = pile_width * 0.5
	var half_h: float = pile_height * 0.5
	_points = [
		Vector2(-half_w, half_h),
		Vector2(-half_w * 0.6, -half_h * 0.4),
		Vector2(-half_w * 0.2, half_h * 0.2),
		Vector2(0.0, -half_h),
		Vector2(half_w * 0.3, -half_h * 0.5),
		Vector2(half_w * 0.7, half_h * 0.1),
		Vector2(half_w, half_h)
	]

func _setup_collision() -> void:
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(pile_width, pile_height)
	col.shape = shape
	add_child(col)

func _draw() -> void:
	# Jagged neon outline
	var color: Color = Color(1.0, 0.4, 0.1, 0.95) # Glowing toxic orange
	for i in range(_points.size() - 1):
		draw_line(_points[i], _points[i + 1], color, 2.5)
	draw_line(_points.back(), _points.front(), color, 2.0)
	
	# Debris cross lines
	draw_line(Vector2(-15, 0), Vector2(12, -8), Color(0.2, 1.0, 0.4, 0.8), 2.0)
	draw_line(Vector2(-8, -12), Vector2(18, 5), Color(1.0, 0.9, 0.2, 0.8), 1.8)

func _on_hit_bus(bus: Node) -> void:
	is_triggered = true
	if bus.has_method("trigger_crash"):
		bus.call("trigger_crash", "Refuse Pile")
		
	var am: Node = get_tree().root.find_child("AudioManager", true, false)
	if am and am.has_method("play_crash"):
		am.call("play_crash")
		
	var cam: Node = get_tree().root.find_child("FollowCamera2D", true, false)
	if cam and cam.has_method("apply_shake"):
		cam.call("apply_shake", 0.45, 14.0)
		
	queue_free()
