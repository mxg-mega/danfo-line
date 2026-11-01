class_name RoadSegment
extends Node2D

## Procedural Neon 4-Lane Highway Segment.
## Vector-rendered with unshaded glowing curbs, dashed lane dividers, and shoulder markings.

const GameGlobals = preload("res://src/common/game_globals.gd")

@export var segment_length: float = 1200.0
@export var road_half_width: float = 280.0
@export var lane_width: float = 140.0

const DASH_LENGTH: float = 40.0
const GAP_LENGTH: float = 30.0

func _ready() -> void:
	z_index = 0 # Base road layer
	queue_redraw()

func _draw() -> void:
	# 1. Dark Asphalt Roadbed
	var road_rect: Rect2 = Rect2(-road_half_width, -segment_length, road_half_width * 2.0, segment_length)
	draw_rect(road_rect, GameGlobals.COLOR_ROAD_BG, true)
	
	# 2. Roadside Shoulders / Outer Borders
	var shoulder_width: float = 40.0
	draw_rect(Rect2(-road_half_width - shoulder_width, -segment_length, shoulder_width, segment_length), Color(0.008, 0.008, 0.012, 1.0), true)
	draw_rect(Rect2(road_half_width, -segment_length, shoulder_width, segment_length), Color(0.008, 0.008, 0.012, 1.0), true)
	
	# 3. Outer Glowing Curbs (Cyan Neon Halo + Core)
	_draw_glowing_curb(-road_half_width)
	_draw_glowing_curb(road_half_width)
	
	# Outer barrier hazard stripes
	_draw_shoulder_stripes(-road_half_width - shoulder_width * 0.5)
	_draw_shoulder_stripes(road_half_width + shoulder_width * 0.5)

	# 4. Dashed Lane Dividers (Separating the 4 lanes at X = -140, 0, 140)
	for i in range(1, GameGlobals.LANE_COUNT):
		var div_x: float = -road_half_width + (i * lane_width)
		_draw_dashed_divider(div_x)

func _draw_glowing_curb(x_pos: float) -> void:
	# Outer soft cyan halo
	var halo_color: Color = Color(GameGlobals.COLOR_CURB.r, GameGlobals.COLOR_CURB.g, GameGlobals.COLOR_CURB.b, 0.25)
	draw_line(Vector2(x_pos, 0.0), Vector2(x_pos, -segment_length), halo_color, 8.0)
	# Inner sharp neon core
	draw_line(Vector2(x_pos, 0.0), Vector2(x_pos, -segment_length), GameGlobals.COLOR_CURB, 2.5)

func _draw_dashed_divider(x_pos: float) -> void:
	var total_step: float = DASH_LENGTH + GAP_LENGTH
	var y: float = 0.0
	while y < segment_length:
		var y1: float = -y
		var y2: float = maxf(-segment_length, -(y + DASH_LENGTH))
		# Glowing yellow dashed line
		draw_line(Vector2(x_pos, y1), Vector2(x_pos, y2), GameGlobals.COLOR_LANE_DIVIDER, 2.5)
		y += total_step

func _draw_shoulder_stripes(x_pos: float) -> void:
	var step: float = 100.0
	var y: float = 0.0
	var stripe_color: Color = Color(0.0, 0.8, 1.0, 0.2)
	while y < segment_length:
		draw_line(Vector2(x_pos - 10.0, -y), Vector2(x_pos + 10.0, -y), stripe_color, 2.0)
		y += step
