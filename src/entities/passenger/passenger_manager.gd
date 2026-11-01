class_name PassengerManager
extends Node2D

## Spawns and manages roadside passengers ahead of the race.
## Places passengers along left and right highway curbs.

const PassengerScene = preload("res://src/entities/passenger/passenger.tscn")

@export var spawn_interval_min: float = 240.0
@export var spawn_interval_max: float = 420.0
@export var spawn_lookahead: float = 2400.0
@export var cleanup_distance: float = 800.0
@export var vip_chance: float = 0.20 # 20% chance for ₦500 VIP passenger

# Curb positions
const LEFT_CURB_X: float = -260.0
const RIGHT_CURB_X: float = 260.0

var _next_spawn_y: float = -400.0
var _tracked_buses: Array[Node2D] = []

func register_bus(bus: Node2D) -> void:
	if bus and not _tracked_buses.has(bus):
		_tracked_buses.append(bus)

func _process(_delta: float) -> void:
	if _tracked_buses.is_empty():
		return
		
	# Find foremost (smallest Y) and rearmost (largest Y) bus positions
	var min_bus_y: float = INF
	var max_bus_y: float = -INF
	for bus in _tracked_buses:
		if is_instance_valid(bus):
			min_bus_y = minf(min_bus_y, bus.global_position.y)
			max_bus_y = maxf(max_bus_y, bus.global_position.y)
			
	if min_bus_y == INF:
		return
		
	# Spawn ahead of the lead bus
	var target_frontier_y: float = min_bus_y - spawn_lookahead
	while _next_spawn_y > target_frontier_y:
		_spawn_passenger(_next_spawn_y)
		var gap: float = randf_range(spawn_interval_min, spawn_interval_max)
		_next_spawn_y -= gap
		
	# Cleanup passengers trailing behind
	_cleanup_trailing(max_bus_y + cleanup_distance)

func _spawn_passenger(spawn_y: float) -> void:
	var passenger: Area2D = PassengerScene.instantiate() as Area2D
	
	# Alternate or randomize curb side (Left vs Right)
	var on_left_curb: bool = randf() < 0.5
	var curb_x: float = LEFT_CURB_X if on_left_curb else RIGHT_CURB_X
	var facing_dir: float = 1.0 if on_left_curb else -1.0
	
	passenger.position = Vector2(curb_x, spawn_y)
	passenger.set("facing_road_dir", facing_dir)
	
	# VIP check
	var is_vip: bool = randf() < vip_chance
	passenger.set("is_vip", is_vip)
	
	add_child(passenger)

func _cleanup_trailing(cutoff_y: float) -> void:
	for child in get_children():
		if child is Area2D and child.position.y > cutoff_y:
			child.queue_free()
