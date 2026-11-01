class_name GameGlobals
extends Node

## Global configuration and palette for Danfo Line (Top-Down Neon Hustle)

# 4-Lane Road System (Centered on X = 0)
const LANE_WIDTH: float = 140.0
const LANE_COUNT: int = 4
const ROAD_HALF_WIDTH: float = 280.0 # 4 * 140 / 2
const LANE_POSITIONS: Array[float] = [-210.0, -70.0, 70.0, 210.0]

# Neon Color Palette (Clean Vector Lines on Pure Black)
const COLOR_BLACK: Color = Color(0.012, 0.012, 0.016, 1.0)
const COLOR_DANFO_YELLOW: Color = Color(1.0, 0.88, 0.05, 1.0)
const COLOR_DANFO_STRIPE: Color = Color(0.06, 0.06, 0.08, 1.0)
const COLOR_NEON_CYAN: Color = Color(0.0, 0.92, 1.0, 1.0)
const COLOR_NEON_MAGENTA: Color = Color(1.0, 0.08, 0.65, 1.0)
const COLOR_NEON_GREEN: Color = Color(0.22, 1.0, 0.28, 1.0)
const COLOR_NEON_WHITE: Color = Color(0.92, 0.95, 1.0, 1.0)
const COLOR_ROAD_BG: Color = Color(0.02, 0.02, 0.03, 1.0)
const COLOR_LANE_DIVIDER: Color = Color(1.0, 0.88, 0.05, 0.75)
const COLOR_CURB: Color = Color(0.0, 0.92, 1.0, 0.9)

static func get_lane_x(lane_index: int) -> float:
	var clamped_index: int = clampi(lane_index, 0, LANE_COUNT - 1)
	return LANE_POSITIONS[clamped_index]
