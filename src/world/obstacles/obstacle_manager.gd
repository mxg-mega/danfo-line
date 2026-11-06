class_name ObstacleManager
extends Node2D

## Spawns hazards (potholes, refuse piles, puddles, cross-traffic) along the 4 lanes.
## Ensures at least one lane is guaranteed safe at any given stretch of road.

const GameGlobals = preload("res://src/common/game_globals.gd")
const PotholeScript = preload("res://src/world/obstacles/pothole.gd")
const RefusePileScript = preload("res://src/world/obstacles/refuse_pile.gd")
const PuddleScript = preload("res://src/world/obstacles/puddle.gd")
const CrossTrafficScript = preload("res://src/world/obstacles/cross_traffic.gd")

@export var spawn_interval_min: float = 300.0
@export var spawn_interval_max: float = 500.0
@export var spawn_lookahead: float = 2400.0
@export var cleanup_distance: float = 800.0
@export var cross_traffic_interval: float = 30.0

var _next_spawn_y: float = -600.0
var _cross_traffic_timer: float = 20.0 # First intersection at 20s
var _tracked_buses: Array[Node2D] = []

func register_bus(bus: Node2D) -> void:
	if bus and not _tracked_buses.has(bus):
		_tracked_buses.append(bus)

func _process(delta: float) -> void:
	if _tracked_buses.is_empty():
		return
		
	var min_bus_y: float = INF
	var max_bus_y: float = -INF
	for bus in _tracked_buses:
		if is_instance_valid(bus):
			min_bus_y = minf(min_bus_y, bus.global_position.y)
			max_bus_y = maxf(max_bus_y, bus.global_position.y)
			
	if min_bus_y == INF:
		return
		
	# 1. Cross-traffic timer
	_cross_traffic_timer -= delta
	if _cross_traffic_timer <= 0.0:
		_cross_traffic_timer = cross_traffic_interval
		_spawn_cross_traffic(min_bus_y - 1200.0)

	# 2. Standard Obstacles Spawning (Potholes, Refuse, Puddles)
	var target_frontier_y: float = min_bus_y - spawn_lookahead
	while _next_spawn_y > target_frontier_y:
		_spawn_hazard_cluster(_next_spawn_y)
		var gap: float = randf_range(spawn_interval_min, spawn_interval_max)
		_next_spawn_y -= gap
		
	# 3. Cleanup trailing hazards
	_cleanup_trailing(max_bus_y + cleanup_distance)

func _spawn_hazard_cluster(spawn_y: float) -> void:
	# Guarantee at least 1 safe lane! Choose 1 or 2 lanes to place obstacles
	var lanes: Array[int] = [0, 1, 2, 3]
	lanes.shuffle()
	
	# Pick 1 or 2 obstacle lanes, leaving at least 2 safe lanes
	var obstacle_count: int = 1 if randf() < 0.65 else 2
	for i in range(obstacle_count):
		var lane_idx: int = lanes[i]
		var lane_x: float = GameGlobals.get_lane_x(lane_idx)
		
		var roll: float = randf()
		var node: Area2D
		if roll < 0.40:
			node = PotholeScript.new()
		elif roll < 0.70:
			node = PuddleScript.new()
		else:
			node = RefusePileScript.new()
			
		node.position = Vector2(lane_x, spawn_y)
		add_child(node)

func _spawn_cross_traffic(spawn_y: float) -> void:
	var ct: Area2D = CrossTrafficScript.new()
	ct.position = Vector2(0.0, spawn_y)
	add_child(ct)

func _cleanup_trailing(cutoff_y: float) -> void:
	for child in get_children():
		if child is Area2D and child.position.y > cutoff_y:
			child.queue_free()
