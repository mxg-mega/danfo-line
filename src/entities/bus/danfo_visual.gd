class_name DanfoVisual
extends Node2D

## Procedural Minimalist Neon Line-Art representation of a Lagos Danfo Bus
## Facing upward (-Y). Crisp vector drawing for Web and Mobile.

@export var bus_color: Color = Color(1.0, 0.88, 0.05, 1.0)
@export var bus_width: float = 46.0
@export var bus_length: float = 92.0
@export var is_boosting: bool = false
@export var turn_lean: float = 0.0 # -1.0 (left) to +1.0 (right)

const COLOR_BODY_FILL: Color = Color(0.08, 0.08, 0.1, 0.95)
const COLOR_WINDOW: Color = Color(0.0, 0.92, 1.0, 0.9)
const COLOR_TAILLIGHT: Color = Color(1.0, 0.15, 0.15, 1.0)
const COLOR_STRIPE: Color = Color(0.02, 0.02, 0.03, 1.0)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var half_w: float = bus_width * 0.5
	var half_l: float = bus_length * 0.5
	var rect: Rect2 = Rect2(-half_w, -half_l, bus_width, bus_length)
	
	# 1. Headlight Beams (Forward cones)
	_draw_headlights(half_w, half_l)
	
	# 2. Main Bus Body Fill & Border
	draw_rect(rect, COLOR_BODY_FILL, true)
	
	# Neon Glow Border (Thick semi-transparent outer + sharp inner)
	var glow_border_color: Color = Color(bus_color.r, bus_color.g, bus_color.b, 0.4 if not is_boosting else 0.7)
	draw_rect(rect.grow(2.0), glow_border_color, false, 3.5)
	draw_rect(rect, bus_color, false, 2.0)
	
	# 3. Signature Lagos Danfo Stripes (Twin dark stripes along the sides)
	var stripe_w: float = 6.0
	var stripe_left_x: float = -half_w + 5.0
	var stripe_right_x: float = half_w - 5.0 - stripe_w
	draw_rect(Rect2(stripe_left_x, -half_l + 8.0, stripe_w, bus_length - 16.0), COLOR_STRIPE, true)
	draw_rect(Rect2(stripe_right_x, -half_l + 8.0, stripe_w, bus_length - 16.0), COLOR_STRIPE, true)
	# Subtle accent line on stripes
	draw_line(Vector2(stripe_left_x + 3.0, -half_l + 10.0), Vector2(stripe_left_x + 3.0, half_l - 10.0), bus_color * 0.5, 1.0)
	draw_line(Vector2(stripe_right_x + 3.0, -half_l + 10.0), Vector2(stripe_right_x + 3.0, half_l - 10.0), bus_color * 0.5, 1.0)
	
	# 4. Windshield (Front) & Windows
	# Windshield: trapezoid near top
	var win_w: float = half_w - 9.0
	var win_front_y: float = -half_l + 12.0
	var win_back_y: float = -half_l + 28.0
	var windshield_pts: PackedVector2Array = [
		Vector2(-win_w + 2.0, win_front_y),
		Vector2(win_w - 2.0, win_front_y),
		Vector2(win_w + 1.0, win_back_y),
		Vector2(-win_w - 1.0, win_back_y)
	]
	draw_colored_polygon(windshield_pts, COLOR_WINDOW * 0.25)
	draw_polyline(windshield_pts + PackedVector2Array([windshield_pts[0]]), COLOR_WINDOW, 1.5)
	
	# Rear Window
	var rear_win_rect: Rect2 = Rect2(-win_w + 2.0, half_l - 20.0, (win_w - 2.0) * 2.0, 8.0)
	draw_rect(rear_win_rect, COLOR_WINDOW * 0.2, true)
	draw_rect(rear_win_rect, COLOR_WINDOW * 0.8, false, 1.5)
	
	# Side passenger windows
	for side in [-1.0, 1.0]:
		var sx: float = (half_w - 4.0) * side
		for i in range(3):
			var wy: float = -half_l + 36.0 + i * 15.0
			draw_line(Vector2(sx, wy), Vector2(sx, wy + 10.0), COLOR_WINDOW, 1.5)
	
	# 5. Taillights (Twin glowing red bars at rear)
	var tl_w: float = 7.0
	var tl_y: float = half_l - 2.0
	draw_line(Vector2(-half_w + 4.0, tl_y), Vector2(-half_w + 4.0 + tl_w, tl_y), COLOR_TAILLIGHT, 3.0)
	draw_line(Vector2(half_w - 4.0 - tl_w, tl_y), Vector2(half_w - 4.0, tl_y), COLOR_TAILLIGHT, 3.0)
	
	# 6. Roof Vent / Center Details (Abstract line hustle detail)
	draw_line(Vector2(-6.0, -5.0), Vector2(6.0, -5.0), bus_color * 0.7, 1.5)
	draw_line(Vector2(-6.0, 10.0), Vector2(6.0, 10.0), bus_color * 0.7, 1.5)

func _draw_headlights(half_w: float, half_l: float) -> void:
	var beam_length: float = 140.0 if not is_boosting else 220.0
	var beam_spread: float = 24.0 if not is_boosting else 32.0
	var beam_color: Color = Color(1.0, 0.98, 0.7, 0.08 if not is_boosting else 0.16)
	
	for side in [-1.0, 1.0]:
		var hx: float = (half_w - 9.0) * side
		var hy: float = -half_l
		
		# Glowing beam triangle
		var pts: PackedVector2Array = [
			Vector2(hx, hy),
			Vector2(hx + (side * beam_spread * 0.4) - beam_spread, hy - beam_length),
			Vector2(hx + (side * beam_spread * 0.4) + beam_spread, hy - beam_length)
		]
		draw_colored_polygon(pts, beam_color)
		
		# Headlight bulb glow
		draw_circle(Vector2(hx, hy), 3.0, Color(1.0, 1.0, 0.8, 0.9))
