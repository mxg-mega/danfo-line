class_name FollowCamera2D
extends Camera2D

## Top-Down Chase Camera for Danfo Line.
## Smoothly tracks the player bus, keeps the forward road visible, and applies dynamic speed zoom.

@export var target: Node2D
@export var look_ahead_offset_y: float = -180.0
@export var smooth_follow_speed_y: float = 12.0
@export var smooth_follow_speed_x: float = 8.0
@export var base_zoom: float = 1.0
@export var boost_zoom: float = 0.92
@export var zoom_speed: float = 4.0

var _shake_amount: float = 0.0
var _shake_timer: float = 0.0

func _ready() -> void:
	# Enable camera
	enabled = true
	zoom = Vector2(base_zoom, base_zoom)

func _process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		return
	
	_update_position(delta)
	_update_zoom(delta)
	_update_shake(delta)

func _update_position(delta: float) -> void:
	var target_pos: Vector2 = target.global_position
	var target_cam_y: float = target_pos.y + look_ahead_offset_y
	var target_cam_x: float = target_pos.x * 0.35 # Mild horizontal swing to stay centered on road
	
	global_position.y = lerpf(global_position.y, target_cam_y, smooth_follow_speed_y * delta)
	global_position.x = lerpf(global_position.x, target_cam_x, smooth_follow_speed_x * delta)

func _update_zoom(delta: float) -> void:
	var is_boosting: bool = false
	if "is_boosting" in target:
		is_boosting = bool(target.get("is_boosting"))
		
	var target_zoom_val: float = boost_zoom if is_boosting else base_zoom
	var current_zoom_val: float = lerpf(zoom.x, target_zoom_val, zoom_speed * delta)
	zoom = Vector2(current_zoom_val, current_zoom_val)

func _update_shake(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		offset = Vector2(
			randf_range(-_shake_amount, _shake_amount),
			randf_range(-_shake_amount, _shake_amount)
		)
		if _shake_timer <= 0.0:
			offset = Vector2.ZERO

func apply_shake(duration: float, intensity: float) -> void:
	_shake_timer = duration
	_shake_amount = intensity
