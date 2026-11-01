class_name BusBase
extends CharacterBody2D

## Base class for Danfo Buses (Player and Rival Bots).
## Handles forward propulsion, lateral hustle steering, drift lean, and boost.

signal speed_changed(current_speed: float)
signal boost_changed(energy_ratio: float, is_boosting: bool)
signal fare_changed(total_fare: int)
signal crashed(fare_lost: int)

@export_group("Speed & Physics")
@export var base_speed: float = 520.0
@export var boost_speed: float = 860.0
@export var brake_speed: float = 280.0
@export var acceleration: float = 900.0
@export var steer_speed: float = 480.0
@export var max_drift_angle: float = deg_to_rad(14.0)

@export_group("Boost")
@export var max_boost_energy: float = 100.0
@export var boost_drain_rate: float = 35.0
@export var boost_recharge_rate: float = 18.0

@export_group("Identity & Visuals")
@export var bus_name: String = "Danfo 01"
@export var bus_color: Color = Color(1.0, 0.88, 0.05, 1.0)

const GameGlobals = preload("res://src/common/game_globals.gd")
const DanfoVisualScript = preload("res://src/entities/bus/danfo_visual.gd")

# Runtime State
var current_forward_speed: float = 520.0
var current_lateral_speed: float = 0.0
var boost_energy: float = 100.0
var is_boosting: bool = false
var is_braking: bool = false
var steer_input: float = 0.0 # -1.0 to 1.0
var current_fare: int = 0

@onready var visual: Node2D = $DanfoVisual
@onready var trail_mount: Marker2D = $TrailMount

func _ready() -> void:
	boost_energy = max_boost_energy
	current_forward_speed = base_speed
	if visual:
		visual.bus_color = bus_color

func _physics_process(delta: float) -> void:
	_update_boost(delta)
	_update_movement(delta)
	_update_visuals(delta)
	
	# Emit telemetry signals
	speed_changed.emit(current_forward_speed)
	boost_changed.emit(boost_energy / max_boost_energy, is_boosting)

func _update_boost(delta: float) -> void:
	if is_boosting and boost_energy > 0.0:
		boost_energy = maxf(0.0, boost_energy - boost_drain_rate * delta)
		if boost_energy <= 0.0:
			is_boosting = false
	elif not is_boosting and boost_energy < max_boost_energy:
		boost_energy = minf(max_boost_energy, boost_energy + boost_recharge_rate * delta)

func _update_movement(delta: float) -> void:
	# 1. Determine target forward speed
	var target_speed: float = base_speed
	if is_boosting and boost_energy > 0.0:
		target_speed = boost_speed
	elif is_braking:
		target_speed = brake_speed
		
	current_forward_speed = move_toward(current_forward_speed, target_speed, acceleration * delta)
	
	# 2. Determine lateral speed (Option A: continuous steering with snappy acceleration)
	var target_lateral_speed: float = steer_input * steer_speed
	current_lateral_speed = move_toward(current_lateral_speed, target_lateral_speed, steer_speed * 6.0 * delta)
	
	# 3. Dynamic drift lean (bus rotates slightly into the turn)
	var target_rotation: float = steer_input * max_drift_angle
	rotation = lerpf(rotation, target_rotation, 14.0 * delta)
	
	# 4. Set velocity: -Y is forward driving, X is lateral steering
	velocity = Vector2(current_lateral_speed, -current_forward_speed)
	move_and_slide()
	
	# 5. Enforce road boundary containment
	var road_limit: float = GameGlobals.ROAD_HALF_WIDTH - 30.0
	if global_position.x < -road_limit:
		global_position.x = -road_limit
		current_lateral_speed = 0.0
	elif global_position.x > road_limit:
		global_position.x = road_limit
		current_lateral_speed = 0.0

func _update_visuals(delta: float) -> void:
	if visual:
		visual.is_boosting = is_boosting
		visual.turn_lean = lerpf(visual.turn_lean, steer_input, 15.0 * delta)

func add_fare(amount: int) -> void:
	current_fare += amount
	fare_changed.emit(current_fare)

func apply_crash_penalty(penalty_amount: int) -> void:
	var lost: int = mini(penalty_amount, current_fare)
	current_fare -= lost
	current_forward_speed = brake_speed * 0.5
	fare_changed.emit(current_fare)
	crashed.emit(lost)
