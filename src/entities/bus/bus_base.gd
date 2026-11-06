class_name BusBase
extends CharacterBody2D

## Base class for Danfo Buses (Player and Rival Bots).
## Handles forward propulsion, lateral hustle steering, 14-seat capacity & weight,
## crash penalties, stun, invulnerability, and obstacle status effects.

signal speed_changed(current_speed: float)
signal boost_changed(energy_ratio: float, is_boosting: bool)
signal fare_changed(total_fare: int)
signal crashed(fare_lost: int)
signal crashed_event(source: String, penalty: int)
signal seats_changed(occupied: int, max_seats: int, multiplier: float)
signal passenger_dropped_off()
signal hazard_hit(hazard_type: String)

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
const FloatingTextScript = preload("res://src/effects/floating_text.gd")

# 14 Seats Economy
const MAX_SEATS: int = 14
var seats_occupied: int = 0
var passenger_timers: Array[float] = []

# Status & Hazard Effects
var is_stunned: bool = false
var _stun_timer: float = 0.0
var is_invulnerable: bool = false
var _enabled: bool = false
var _invuln_timer: float = 0.0
var is_slippery: bool = false
var _slippery_timer: float = 0.0
var _slowdown_timer: float = 0.0
var _slowdown_factor: float = 1.0

# Runtime Movement State
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
		visual.set("bus_color", bus_color)
	
	var pickup_area: Area2D = get_node_or_null("PickupArea") as Area2D
	if pickup_area:
		pickup_area.area_entered.connect(_on_pickup_area_entered)

func _on_pickup_area_entered(area: Area2D) -> void:
	if area and area.has_method("collect"):
		area.call("collect", self)

func _physics_process(delta: float) -> void:
	if not _enabled:
		return
	_update_timers(delta)
	_update_boost(delta)
	_update_movement(delta)
	_update_visuals(delta)
	
	# Emit telemetry
	speed_changed.emit(current_forward_speed)
	boost_changed.emit(boost_energy / max_boost_energy, is_boosting)

func _update_timers(delta: float) -> void:
	# 1. Stun timer
	if is_stunned:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			is_stunned = false
			
	# 2. Invulnerability timer
	if is_invulnerable:
		_invuln_timer -= delta
		if _invuln_timer <= 0.0:
			is_invulnerable = false
			
	# 3. Slippery puddle timer
	if is_slippery:
		_slippery_timer -= delta
		if _slippery_timer <= 0.0:
			is_slippery = false
			
	# 4. Pothole slowdown timer
	if _slowdown_timer > 0.0:
		_slowdown_timer -= delta
		if _slowdown_timer <= 0.0:
			_slowdown_factor = 1.0
			
	# 5. Rolling passenger drop-offs (8-12 seconds per passenger)
	var i: int = passenger_timers.size() - 1
	while i >= 0:
		passenger_timers[i] -= delta
		if passenger_timers[i] <= 0.0:
			passenger_timers.remove_at(i)
			seats_occupied = maxi(0, seats_occupied - 1)
			seats_changed.emit(seats_occupied, MAX_SEATS, get_fare_multiplier())
			passenger_dropped_off.emit()
		i -= 1

func _update_boost(delta: float) -> void:
	if is_stunned:
		is_boosting = false
		return
		
	if is_boosting and boost_energy > 0.0:
		boost_energy = maxf(0.0, boost_energy - boost_drain_rate * delta)
		if boost_energy <= 0.0:
			is_boosting = false
	elif not is_boosting and boost_energy < max_boost_energy:
		boost_energy = minf(max_boost_energy, boost_energy + boost_recharge_rate * delta)

func _update_movement(delta: float) -> void:
	# 1. Determine target forward speed
	var target_speed: float = base_speed
	if is_stunned:
		target_speed = brake_speed * 0.45
	elif is_boosting and boost_energy > 0.0:
		target_speed = boost_speed
	elif is_braking:
		target_speed = brake_speed
		
	target_speed *= _slowdown_factor
	current_forward_speed = move_toward(current_forward_speed, target_speed, acceleration * delta)
	
	# 2. Determine lateral speed scaled by passenger weight
	var weight_factor: float = 1.0 - (float(seats_occupied) / float(MAX_SEATS)) * 0.25
	var effective_steer_speed: float = steer_speed * weight_factor
	var target_lateral_speed: float = steer_input * effective_steer_speed
	
	# Slippery puddle physics: smooth drift, takes longer to change direction
	var lateral_accel: float = (effective_steer_speed * 1.5) if is_slippery else (effective_steer_speed * 6.0)
	current_lateral_speed = move_toward(current_lateral_speed, target_lateral_speed, lateral_accel * delta)
	
	# 3. Dynamic drift lean
	var target_rotation: float = steer_input * max_drift_angle
	rotation = lerpf(rotation, target_rotation, 14.0 * delta)
	
	# 4. Move and slide
	velocity = Vector2(current_lateral_speed, -current_forward_speed)
	move_and_slide()
	
	# 5. Bus-on-Bus Collisions check
	_check_bus_collisions()
	
	# 6. Road bounds enforcement
	var road_limit: float = GameGlobals.ROAD_HALF_WIDTH - 30.0
	if global_position.x < -road_limit:
		global_position.x = -road_limit
		current_lateral_speed = 0.0
	elif global_position.x > road_limit:
		global_position.x = road_limit
		current_lateral_speed = 0.0

func _check_bus_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider is BusBase and collider != self:
			var other: BusBase = collider as BusBase
			# Trigger crash on relative collision
			if not is_invulnerable:
				trigger_crash("Bus Collision with %s" % other.bus_name)
			if not other.is_invulnerable:
				other.trigger_crash("Bus Collision with %s" % bus_name)

func _update_visuals(delta: float) -> void:
	if visual:
		visual.set("is_boosting", is_boosting)
		visual.set("turn_lean", lerpf(float(visual.get("turn_lean")), steer_input, 15.0 * delta))
		visual.set("seats_occupied", seats_occupied)
		visual.set("is_invulnerable", is_invulnerable)

func get_fare_multiplier() -> float:
	if seats_occupied <= 4:
		return 1.0
	elif seats_occupied <= 9:
		return 1.25
	else:
		return 1.5

func add_fare(base_amount: int) -> void:
	var mult: float = get_fare_multiplier()
	var final_amount: int = int(round(float(base_amount) * mult))
	current_fare += final_amount
	
	if seats_occupied < MAX_SEATS:
		seats_occupied += 1
		passenger_timers.append(randf_range(8.0, 12.0))
		
	fare_changed.emit(current_fare)
	seats_changed.emit(seats_occupied, MAX_SEATS, get_fare_multiplier())

func trigger_crash(source_name: String = "Crash") -> void:
	if is_invulnerable:
		return
		
	var penalty: int = maxi(100, int(float(current_fare) * 0.20))
	apply_crash_penalty(penalty)
	
	is_stunned = true
	_stun_timer = 1.0
	is_invulnerable = true
	_invuln_timer = 1.5
	
	# Floating penalty feedback in red
	_spawn_penalty_text(penalty)
	crashed_event.emit(source_name, penalty)

func apply_crash_penalty(penalty_amount: int) -> void:
	var lost: int = mini(penalty_amount, current_fare)
	current_fare -= lost
	current_forward_speed = brake_speed * 0.5
	fare_changed.emit(current_fare)
	crashed.emit(lost)

func apply_puddle_slip(duration: float = 2.0) -> void:
	is_slippery = true
	_slippery_timer = duration
	hazard_hit.emit("puddle")

func apply_pothole_hit(duration: float = 0.8) -> void:
	_slowdown_timer = duration
	_slowdown_factor = 0.5
	hazard_hit.emit("pothole")

func refill_boost() -> void:
	boost_energy = max_boost_energy

func _spawn_penalty_text(penalty: int) -> void:
	var popup: Node2D = FloatingTextScript.new()
	popup.global_position = global_position + Vector2(0, -35.0)
	popup.call("setup", "-₦%d REPAIR!" % penalty, Color(1.0, 0.2, 0.2, 1.0))
	var tree_root: Window = get_tree().root
	if tree_root:
		tree_root.add_child(popup)

# Enable/disable bus (used for pre‑rush start)
func set_enabled(enable: bool) -> void:
	_enabled = enable
