class_name PlayerBus
extends "res://src/entities/bus/bus_base.gd"

## Player-controlled Danfo Bus.
## Listens to keyboard (A/D, arrows, Space) and touch inputs, and manages the glowing trail.

const Trail2DScript = preload("res://src/effects/trail_2d.gd")

var _trail: Node2D
var _touch_steer: float = 0.0
var _is_touch_boosting: bool = false

func _ready() -> void:
	super._ready()
	_setup_trail()

func _setup_trail() -> void:
	_trail = Trail2DScript.new()
	_trail.trail_color = bus_color
	_trail.target_node = trail_mount if trail_mount else self
	add_child(_trail)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			var vp_size: Vector2 = get_viewport_rect().size
			if touch.position.y < vp_size.y * 0.35:
				_is_touch_boosting = true
			else:
				var center_x: float = vp_size.x * 0.5
				_touch_steer = -1.0 if touch.position.x < center_x else 1.0
		else:
			_touch_steer = 0.0
			_is_touch_boosting = false
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		var vp_size: Vector2 = get_viewport_rect().size
		var center_x: float = vp_size.x * 0.5
		_touch_steer = -1.0 if drag.position.x < center_x else 1.0

func _process(_delta: float) -> void:
	_read_inputs()

func _read_inputs() -> void:
	# 1. Lateral Steering Input (-1.0 to 1.0)
	var left: bool = Input.is_action_pressed("steer_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var right: bool = Input.is_action_pressed("steer_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	
	var k_steer: float = 0.0
	if left:
		k_steer -= 1.0
	if right:
		k_steer += 1.0
		
	steer_input = k_steer if absf(k_steer) > 0.01 else _touch_steer
	
	# 2. Boost Input
	var k_boost: bool = Input.is_action_pressed("boost") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	is_boosting = k_boost or _is_touch_boosting
	
	# 3. Brake Input
	var k_brake: bool = Input.is_action_pressed("brake") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	is_braking = k_brake
