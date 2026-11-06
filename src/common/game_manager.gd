class_name GameManager
extends Node

## Rush Hour Match Manager.
## Manages day countdown timer (90s), live 4-driver standings, and game over state.

signal time_updated(time_remaining: float)
signal match_ended(standings: Array[Dictionary])
signal rush_started

@export var match_duration: float = 90.0
@export var pre_rush_duration: float = 3.0
var time_remaining: float = 90.0
var pre_rush_remaining: float = 0.0
var is_match_active: bool = false

var _buses: Array[Node2D] = []

func _ready() -> void:
	time_remaining = match_duration
	pre_rush_remaining = pre_rush_duration

func register_buses(buses_list: Array[Node2D]) -> void:
	_buses = buses_list
	# Disable all buses until rush starts
	for bus in _buses:
		if bus and bus.has_method("set_enabled"):
			bus.call("set_enabled", false)

func _process(delta: float) -> void:
	if not is_match_active:
		# Pre‑rush countdown
		pre_rush_remaining -= delta
		if pre_rush_remaining <= 0.0:
			# Start match
			is_match_active = true
			time_remaining = match_duration
			rush_started.emit()
			# Enable all buses
			for bus in _buses:
				if bus and bus.has_method("set_enabled"):
					bus.call("set_enabled", true)
			time_updated.emit(time_remaining)
		else:
			time_updated.emit(pre_rush_remaining)
		return
	# Match active logic
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		is_match_active = false
		time_updated.emit(0.0)
		_conclude_match()
	else:
		time_updated.emit(time_remaining)

func get_standings() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for b in _buses:
		if is_instance_valid(b):
			list.append({
				"name": str(b.get("bus_name")),
				"fare": int(b.get("current_fare")),
				"color": Color(b.get("bus_color")),
				"is_player": (b is PlayerBus)
			})
	# Sort descending by fare
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["fare"] > b["fare"]
	)
	return list

func _conclude_match() -> void:
	var final_standings: Array[Dictionary] = get_standings()
	match_ended.emit(final_standings)
