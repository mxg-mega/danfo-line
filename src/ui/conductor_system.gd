class_name ConductorSystem
extends Node

## Lagos Danfo Conductor Speech System.
## Triggers reactive Nigerian Pidgin commentary on gameplay events with cooldowns.

signal speech_triggered(text: String)

@export var cooldown_seconds: float = 2.0
var _cooldown_timer: float = 0.0

# Tracked player and rival buses for overtake detection
var _player_bus: Node2D
var _rival_buses: Array[Node2D] = []
var _prev_rival_rel_y: Dictionary = {} # rival_id -> y_offset (relative to player)

func setup(player: Node2D, rivals: Array[Node2D]) -> void:
	_player_bus = player
	_rival_buses = rivals
	
	if _player_bus:
		if _player_bus.has_signal("seats_changed"):
			_player_bus.connect("seats_changed", Callable(self, "_on_seats_changed"))
		if _player_bus.has_signal("crashed_event"):
			_player_bus.connect("crashed_event", Callable(self, "_on_crashed"))
		if _player_bus.has_signal("hazard_hit"):
			_player_bus.connect("hazard_hit", Callable(self, "_on_hazard_hit"))
		if _player_bus.has_signal("horn_honked"):
			_player_bus.connect("horn_honked", Callable(self, "_on_horn_honked"))
			
	for rival in _rival_buses:
		if is_instance_valid(rival) and _player_bus:
			_prev_rival_rel_y[rival.get_instance_id()] = rival.global_position.y - _player_bus.global_position.y

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		
	_check_overtakes()

func say(line: String) -> void:
	if _cooldown_timer > 0.0:
		return
	_cooldown_timer = cooldown_seconds
	speech_triggered.emit(line)

func _on_seats_changed(occupied: int, max_seats: int, _mult: float) -> void:
	if occupied >= max_seats:
		say("Full! Full! Driver, move!")
	else:
		var pickup_lines: Array[String] = [
			"Enter with your change!",
			"Oya enter, Oshodi straight!",
			"One more person, we dey go!",
			"Enter quickly, driver no dey wait!"
		]
		say(pickup_lines.pick_random())

func _on_crashed(_source: String, _penalty: int) -> void:
	var crash_lines: Array[String] = [
		"E don happen. We don jam!",
		"Ye! My bumper don bend!",
		"Driver, you no get eyes?!",
		"Wahala dey o, money don go!"
	]
	say(crash_lines.pick_random())

func _on_hazard_hit(hazard_type: String) -> void:
	match hazard_type:
		"pothole":
			say("Pit inside pit! Lagos road!")
		"puddle":
			say("Water plenty for road o! Hold steering!")

func _on_horn_honked() -> void:
	var horn_lines: Array[String] = [
		"Commot for road!",
		"Move body joor!",
		"Clear road, Danfo dey come!"
	]
	say(horn_lines.pick_random())

func _check_overtakes() -> void:
	if not _player_bus or not is_instance_valid(_player_bus):
		return
		
	var py: float = _player_bus.global_position.y
	for rival in _rival_buses:
		if not is_instance_valid(rival):
			continue
		var id: int = rival.get_instance_id()
		var current_rel_y: float = rival.global_position.y - py
		var prev_rel_y: float = _prev_rival_rel_y.get(id, current_rel_y)
		
		# Rival passed player: was behind (prev_rel_y > 0), now ahead (current_rel_y < 0)
		if prev_rel_y > 10.0 and current_rel_y < -10.0:
			say("Driver, you go let am do us like that?!")
		# Player cut off / passed rival: was ahead (prev_rel_y < 0), now behind (current_rel_y > 0)
		elif prev_rel_y < -10.0 and current_rel_y > 10.0:
			say("Na so! Dem no fit us!")
			
		_prev_rival_rel_y[id] = current_rel_y
