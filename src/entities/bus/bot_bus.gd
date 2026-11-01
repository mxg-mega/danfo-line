class_name BotBus
extends "res://src/entities/bus/bus_base.gd"

## Autonomous Rival Danfo Driver ("Oshodi Rocket").
## Features greedy passenger interception, lane swerving, and dynamic rubberbanding.

const Trail2DScript = preload("res://src/effects/trail_2d.gd")

@export var player_target: Node2D
@export var scan_range: float = 1100.0
@export var target_passenger: Area2D

var _trail: Node2D
var _decision_timer: float = 0.0
var _desired_lane_x: float = 70.0 # Default mid-right lane

func _ready() -> void:
	bus_name = "Oshodi Rocket"
	bus_color = Color(0.0, 0.92, 1.0, 1.0) # Neon Cyan
	super._ready()
	_setup_trail()

func _setup_trail() -> void:
	_trail = Trail2DScript.new()
	_trail.call("set_color", bus_color)
	_trail.set("target_node", trail_mount if trail_mount else self)
	add_child(_trail)

func _process(delta: float) -> void:
	_decision_timer -= delta
	if _decision_timer <= 0.0:
		_decision_timer = 0.12 # Scan 8 times per second for responsive AI
		_update_ai_decisions()

func _update_ai_decisions() -> void:
	# 1. Scan for closest and most valuable upcoming passenger
	target_passenger = _find_best_passenger()
	
	if target_passenger and is_instance_valid(target_passenger):
		# Target the passenger's curb position (clamped safely within road bounds)
		var road_limit: float = GameGlobals.ROAD_HALF_WIDTH - 30.0
		_desired_lane_x = clampf(target_passenger.global_position.x, -road_limit, road_limit)
	else:
		# Cruise in mid-lanes when no passenger is immediately in sight
		if randf() < 0.05:
			_desired_lane_x = 70.0 if randf() < 0.5 else -70.0

	# 2. Determine lateral steering toward target X
	var x_diff: float = _desired_lane_x - global_position.x
	if absf(x_diff) > 16.0:
		steer_input = 1.0 if x_diff > 0 else -1.0
	else:
		steer_input = x_diff / 16.0 # Smooth center settling
		
	# 3. Dynamic Rubberbanding (Option A) & Boost Logic
	_update_pacing_and_boost()

func _find_best_passenger() -> Area2D:
	var passengers: Array[Node] = get_tree().get_nodes_in_group("passengers")
	var best_passenger: Area2D = null
	var best_score: float = -INF
	
	for node in passengers:
		if not (node is Area2D) or not is_instance_valid(node):
			continue
		var p: Area2D = node as Area2D
		if p.get("is_collected"):
			continue
			
		# Must be ahead of bot (-Y direction)
		var y_dist: float = global_position.y - p.global_position.y
		if y_dist > 40.0 and y_dist < scan_range:
			var fare_val: float = float(p.get("fare_value"))
			# Higher value and shorter distance yield higher score
			var score: float = (fare_val * 2.0) - (y_dist * 0.7)
			if score > best_score:
				best_score = score
				best_passenger = p
				
	return best_passenger

func _update_pacing_and_boost() -> void:
	if not player_target or not is_instance_valid(player_target):
		return
		
	var player_y: float = player_target.global_position.y
	var y_offset_from_player: float = global_position.y - player_y
	# If y_offset_from_player > 0, bot is behind player (larger Y)
	# If y_offset_from_player < 0, bot is ahead of player (smaller Y)
	
	# Rubberband pacing:
	if y_offset_from_player > 220.0:
		# Bot is lagging behind: boost to catch up!
		is_boosting = true
		base_speed = 580.0
	elif y_offset_from_player < -350.0:
		# Bot is too far ahead: ease off slightly so duel remains competitive
		is_boosting = false
		base_speed = 460.0
	else:
		base_speed = 520.0
		# Contesting a passenger near the player:
		if target_passenger and is_instance_valid(target_passenger):
			var dist_to_p: float = global_position.y - target_passenger.global_position.y
			if dist_to_p < 400.0 and boost_energy > 25.0:
				is_boosting = true
			else:
				is_boosting = false
		else:
			is_boosting = false
