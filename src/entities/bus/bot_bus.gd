class_name BotBus
extends BusBase

## Autonomous Rival Danfo Driver.
## Features distinct personalities (Greedy, Aggressive, Cautious),
## obstacle avoidance, human-like reaction latency, and dynamic rubberbanding.

const Trail2DScript = preload("res://src/effects/trail_2d.gd")

enum Personality { GREEDY, AGGRESSIVE, CAUTIOUS }

@export var personality: Personality = Personality.GREEDY
@export var bot_skill: float = 0.8
@export var player_target: Node2D
@export var scan_range: float = 1100.0
@export var target_passenger: Area2D

var _trail: Node2D
var _decision_timer: float = 0.0
var _desired_lane_x: float = 70.0

func _ready() -> void:
	super._ready()
	_setup_trail()

func configure_identity(p_name: String, p_color: Color, p_personality: Personality, p_skill: float = 0.8) -> void:
	bus_name = p_name
	bus_color = p_color
	personality = p_personality
	bot_skill = p_skill
	if visual:
		visual.set("bus_color", bus_color)
	if _trail:
		_trail.call("set_color", bus_color)

func _setup_trail() -> void:
	_trail = Trail2DScript.new()
	_trail.call("set_color", bus_color)
	_trail.set("target_node", trail_mount if trail_mount else self)
	add_child(_trail)

func _process(delta: float) -> void:
	_decision_timer -= delta
	if _decision_timer <= 0.0:
		# Reaction rate scaled slightly by skill
		_decision_timer = randf_range(0.10, 0.16) / bot_skill
		_update_ai_decisions()

func _update_ai_decisions() -> void:
	var road_limit: float = GameGlobals.ROAD_HALF_WIDTH - 30.0
	
	# 1. Obstacle Avoidance (High priority)
	var threat: Area2D = _find_immediate_obstacle_threat()
	if threat and is_instance_valid(threat) and randf() < bot_skill:
		# Swerve away from obstacle!
		var threat_x: float = threat.global_position.x
		if global_position.x < threat_x:
			_desired_lane_x = clampf(global_position.x - 120.0, -road_limit, road_limit)
		else:
			_desired_lane_x = clampf(global_position.x + 120.0, -road_limit, road_limit)
	else:
		# 2. Behavior based on personality
		match personality:
			Personality.GREEDY:
				_update_greedy_behavior(road_limit)
			Personality.AGGRESSIVE:
				_update_aggressive_behavior(road_limit)
			Personality.CAUTIOUS:
				_update_cautious_behavior(road_limit)

	# 3. Steering input interpolation
	var x_diff: float = _desired_lane_x - global_position.x
	if absf(x_diff) > 16.0:
		steer_input = 1.0 if x_diff > 0 else -1.0
	else:
		steer_input = x_diff / 16.0
		
	# 4. Rubberbanding & Boost logic
	_update_pacing_and_boost()

func _update_greedy_behavior(road_limit: float) -> void:
	target_passenger = _find_best_passenger()
	if target_passenger and is_instance_valid(target_passenger):
		_desired_lane_x = clampf(target_passenger.global_position.x, -road_limit, road_limit)
	else:
		if randf() < 0.08:
			_desired_lane_x = 70.0 if randf() < 0.5 else -70.0

func _update_aggressive_behavior(road_limit: float) -> void:
	target_passenger = _find_best_passenger()
	# Aggressive bot cuts in front of player if nearby!
	if player_target and is_instance_valid(player_target) and randf() < 0.4:
		var y_diff: float = global_position.y - player_target.global_position.y
		# If just ahead of player (0 to -250px), slide directly into player's lane to block!
		if y_diff < 0.0 and y_diff > -260.0:
			_desired_lane_x = player_target.global_position.x
			return
			
	if target_passenger and is_instance_valid(target_passenger):
		_desired_lane_x = clampf(target_passenger.global_position.x, -road_limit, road_limit)
	else:
		if randf() < 0.12:
			_desired_lane_x = -210.0 if randf() < 0.5 else 210.0

func _update_cautious_behavior(road_limit: float) -> void:
	target_passenger = _find_best_passenger()
	if target_passenger and is_instance_valid(target_passenger):
		# Only go for passenger if no immediate hazard in that lane
		_desired_lane_x = clampf(target_passenger.global_position.x, -road_limit, road_limit)
	else:
		# Stay in comfortable mid-lanes
		_desired_lane_x = 70.0 if randf() < 0.5 else -70.0

func _find_immediate_obstacle_threat() -> Area2D:
	var obstacles: Array[Node] = get_tree().get_nodes_in_group("obstacles")
	for node in obstacles:
		if not (node is Area2D) or not is_instance_valid(node):
			continue
		var obs: Area2D = node as Area2D
		var y_dist: float = global_position.y - obs.global_position.y
		# In front within 240px and in the same lateral corridor
		if y_dist > 15.0 and y_dist < 260.0:
			var x_dist: float = absf(global_position.x - obs.global_position.x)
			if x_dist < 55.0:
				return obs
	return null

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
			
		var y_dist: float = global_position.y - p.global_position.y
		if y_dist > 30.0 and y_dist < scan_range:
			var fare_val: float = float(p.get("fare_value"))
			var score: float = (fare_val * 2.0) - (y_dist * 0.7)
			if score > best_score:
				best_score = score
				best_passenger = p
				
	return best_passenger

func _update_pacing_and_boost() -> void:
	if not player_target or not is_instance_valid(player_target):
		return
		
	var player_y: float = player_target.global_position.y
	var y_offset: float = global_position.y - player_y
	
	# Rubberband pacing
	if y_offset > 240.0:
		is_boosting = true
		base_speed = 590.0
	elif y_offset < -360.0:
		is_boosting = false
		base_speed = 460.0
	else:
		base_speed = 520.0
		# Contesting passenger or aggressive boost
		if personality == Personality.AGGRESSIVE and randf() < 0.15 and boost_energy > 20.0:
			is_boosting = true
		elif target_passenger and is_instance_valid(target_passenger):
			var dist_to_p: float = global_position.y - target_passenger.global_position.y
			if dist_to_p < 400.0 and boost_energy > 25.0:
				is_boosting = true
			else:
				is_boosting = false
		else:
			is_boosting = false
