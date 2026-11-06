class_name ObstacleBase
extends Area2D

## Base class for Highway Obstacles in Danfo Line.
## Vector-rendered, collides with Danfo buses, and triggers custom impact effects.

@export var obstacle_name: String = "Obstacle"
var is_triggered: bool = false

func _ready() -> void:
	collision_layer = 8
	collision_mask = 3
	add_to_group("obstacles")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_triggered:
		return
	if body.has_method("trigger_crash") or body.has_method("apply_pothole_hit") or body.has_method("apply_puddle_slip"):
		_on_hit_bus(body)

func _on_area_entered(area: Area2D) -> void:
	if is_triggered:
		return
	var bus: Node = area.get_parent()
	if bus and (bus.has_method("trigger_crash") or bus.has_method("apply_pothole_hit") or bus.has_method("apply_puddle_slip")):
		_on_hit_bus(bus)

func _on_hit_bus(_bus: Node) -> void:
	# Subclasses override
	pass
