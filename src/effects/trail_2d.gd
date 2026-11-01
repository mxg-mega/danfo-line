class_name Trail2D
extends Node2D

## Persistent glowing neon ribbon trail for Danfo Line
## Uses dual-layer Line2D (bright core + glowing halo) with lifetime fade.

@export var trail_color: Color = Color(1.0, 0.88, 0.05, 1.0)
@export var trail_lifetime: float = 3.5
@export var min_point_distance: float = 10.0
@export var core_width: float = 7.0
@export var halo_width: float = 20.0
@export var target_node: Node2D

var _halo_line: Line2D
var _core_line: Line2D

# Array of Dictionary: {"pos": Vector2, "time": float}
var _points_data: Array[Dictionary] = []

func _ready() -> void:
	# Ensure the trail renders in world coordinates, decoupled from parent transforms
	top_level = true
	z_index = 1 # Above road, below buses
	
	_setup_lines()

func _setup_lines() -> void:
	# Outer glowing halo
	_halo_line = Line2D.new()
	_halo_line.width = halo_width
	_halo_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_halo_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_halo_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_halo_line.default_color = Color(trail_color.r, trail_color.g, trail_color.b, 0.3)
	
	# Inner bright neon core
	_core_line = Line2D.new()
	_core_line.width = core_width
	_core_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_core_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_core_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_core_line.default_color = trail_color
	
	_update_gradients()
	
	add_child(_halo_line)
	add_child(_core_line)

func set_color(new_color: Color) -> void:
	trail_color = new_color
	if _halo_line and _core_line:
		_halo_line.default_color = Color(trail_color.r, trail_color.g, trail_color.b, 0.3)
		_core_line.default_color = trail_color
		_update_gradients()

func _update_gradients() -> void:
	# Create fade-out gradient from tail (0.0) to head (1.0)
	var halo_grad: Gradient = Gradient.new()
	halo_grad.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	halo_grad.set_color(1, Color(trail_color.r, trail_color.g, trail_color.b, 0.35))
	_halo_line.gradient = halo_grad

	var core_grad: Gradient = Gradient.new()
	core_grad.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	core_grad.set_color(1, Color(trail_color.r, trail_color.g, trail_color.b, 1.0))
	_core_line.gradient = core_grad

func _process(_delta: float) -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	
	# Sample new position from target node or parent
	var emit_pos: Vector2 = global_position
	if target_node and is_instance_valid(target_node):
		emit_pos = target_node.global_position
	elif get_parent() is Node2D:
		emit_pos = (get_parent() as Node2D).global_position
	
	# Check distance from last point
	var should_add: bool = false
	if _points_data.is_empty():
		should_add = true
	else:
		var last_pos: Vector2 = _points_data.back()["pos"]
		if emit_pos.distance_to(last_pos) >= min_point_distance:
			should_add = true
			
	if should_add:
		_points_data.append({
			"pos": emit_pos,
			"time": current_time
		})
	
	# Prune points exceeding lifetime
	var cutoff_time: float = current_time - trail_lifetime
	while not _points_data.is_empty() and _points_data.front()["time"] < cutoff_time:
		_points_data.pop_front()
	
	# Refresh Line2D points
	_update_line_points(emit_pos)

func _update_line_points(current_head_pos: Vector2) -> void:
	var count: int = _points_data.size()
	if count < 1:
		_halo_line.clear_points()
		_core_line.clear_points()
		return
	
	var pts: PackedVector2Array = PackedVector2Array()
	pts.resize(count + 1)
	for i in range(count):
		pts[i] = _points_data[i]["pos"]
	# The tip of the trail connects dynamically to the current emission point
	pts[count] = current_head_pos
	
	_halo_line.points = pts
	_core_line.points = pts
