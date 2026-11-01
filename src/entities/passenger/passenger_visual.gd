class_name PassengerVisual
extends Node2D

## Procedural Neon Line-Art Passenger.
## Commuter waving an arm to hail passing Danfo buses, with pulsing beacon.

@export var passenger_color: Color = Color(0.2, 1.0, 0.3, 1.0) # Green for standard
@export var is_vip: bool = false
@export var facing_road_dir: float = 1.0 # +1 if facing right (on left curb), -1 if facing left (on right curb)

var _pulse_phase: float = 0.0

func _ready() -> void:
	if is_vip:
		passenger_color = Color(1.0, 0.08, 0.65, 1.0) # Neon Magenta for VIP
	_pulse_phase = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	_pulse_phase += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var color: Color = passenger_color
	
	# 1. Pulsing Ground Beacon (Radar circle expanding and fading)
	var pulse_t: float = fmod(_pulse_phase, PI)
	var ring_radius: float = 8.0 + pulse_t * 12.0
	var ring_alpha: float = (1.0 - (pulse_t / PI)) * 0.5
	draw_arc(Vector2(0, 16.0), ring_radius, 0.0, TAU, 16, Color(color.r, color.g, color.b, ring_alpha), 1.5)
	
	# Ground marker dot
	draw_circle(Vector2(0, 16.0), 3.0, Color(color.r, color.g, color.b, 0.6))

	# 2. Stick Figure Body (Facing road)
	# Head
	draw_circle(Vector2(0, -12.0), 4.5, color)
	
	# Torso
	draw_line(Vector2(0, -7.0), Vector2(0, 7.0), color, 2.0)
	
	# Legs
	draw_line(Vector2(0, 7.0), Vector2(-4.0, 16.0), color, 2.0)
	draw_line(Vector2(0, 7.0), Vector2(4.0, 16.0), color, 2.0)
	
	# Passive Arm (draped by side)
	draw_line(Vector2(0, -4.0), Vector2(-facing_road_dir * 4.0, 4.0), color, 1.8)
	
	# Active Hailing Arm (waving outward toward road)
	var wave_offset_y: float = sin(_pulse_phase * 1.5) * 4.0
	var arm_end: Vector2 = Vector2(facing_road_dir * 12.0, -8.0 + wave_offset_y)
	draw_line(Vector2(0, -4.0), arm_end, color, 2.2)
	# Hand
	draw_circle(arm_end, 2.0, Color(1.0, 1.0, 1.0, 0.9))
	
	# 3. VIP Crown / Star Accent if VIP
	if is_vip:
		draw_line(Vector2(-5.0, -19.0), Vector2(0.0, -23.0), Color(1.0, 0.9, 0.2, 0.9), 1.5)
		draw_line(Vector2(0.0, -23.0), Vector2(5.0, -19.0), Color(1.0, 0.9, 0.2, 0.9), 1.5)
