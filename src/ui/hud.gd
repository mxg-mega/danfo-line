class_name HUD
extends CanvasLayer

## Minimal Neon HUD for Danfo Line.
## Displays Day Timer, 4-way Leaderboard, Seats & Multiplier, Speedometer, Boost gauge,
## and reactive Lagos Conductor speech box.

@onready var timer_label: Label = %TimerLabel
@onready var seats_label: Label = %SeatsLabel
@onready var speed_label: Label = %SpeedLabel
@onready var boost_bar: ProgressBar = %BoostBar
@onready var boost_glow: Panel = %BoostGlow
@onready var boost_label: Label = %BoostLabel
@onready var leaderboard_container: VBoxContainer = %LeaderboardContainer
@onready var conductor_panel: PanelContainer = %ConductorPanel
@onready var conductor_label: Label = %ConductorLabel
@onready var horn_button: Button = %HornButton

## Emitted by the PAUSE button in the top HUD bar (mobile/web players have no Esc key).
signal pause_requested()
@onready var pause_button: Button = %PauseButton

var _conductor_fade_timer: float = 0.0
var _player_bus_ref: Node
var _leaderboard_rows: Array[Dictionary] = [] # {"name": Label, "fare": Label, "box": HBoxContainer}

@onready var boost_button: Button = %BoostButton

func _ready() -> void:
	_init_leaderboard_rows()
	update_seats(0, 14, 1.0)
	update_speed(0.0)
	update_boost(1.0, false)
	update_timer(90.0)
	if conductor_panel:
		conductor_panel.modulate.a = 0.0
	if horn_button:
		horn_button.pressed.connect(_on_horn_pressed)
	if boost_button:
		boost_button.pressed.connect(_on_boost_pressed)
		boost_button.button_up.connect(_on_boost_released)
	if pause_button:
		pause_button.pressed.connect(func() -> void: pause_requested.emit())

# Added timer and seat update helpers
func update_timer(time_left: float) -> void:
	# Display minutes:seconds countdown
	var minutes: int = int(time_left) / 60
	var seconds: int = int(time_left) % 60
	if timer_label:
		timer_label.text = "%02d:%02d" % [minutes, seconds]

func update_seats(occupied: int, max_seats: int, multiplier: float) -> void:
	# Show seats and optionally change color based on multiplier
	if seats_label:
		seats_label.text = "%d/%d" % [occupied, max_seats]
	# Adjust label color for multiplier tiers
	var col: Color = Color(1, 1, 1, 1)
	if multiplier >= 1.5:
		col = Color(0.2, 1.0, 0.2, 1) # green for high
	elif multiplier >= 1.25:
		col = Color(1.0, 0.9, 0.3, 1) # yellow
	else:
		col = Color(1, 1, 1, 1)
	seats_label.add_theme_color_override("font_color", col)

func _init_leaderboard_rows() -> void:
	if not leaderboard_container:
		return
	for child in leaderboard_container.get_children():
		child.queue_free()
	_leaderboard_rows.clear()
	for i in range(4):
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		
		var name_lbl: Label = Label.new()
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var fare_lbl: Label = Label.new()
		fare_lbl.add_theme_font_size_override("font_size", 14)
		fare_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
		
		hbox.add_child(name_lbl)
		hbox.add_child(fare_lbl)
		leaderboard_container.add_child(hbox)
		_leaderboard_rows.append({"box": hbox, "name": name_lbl, "fare": fare_lbl})

func update_standings(standings: Array[Dictionary]) -> void:
	if _leaderboard_rows.is_empty():
		return
		
	for i in range(mini(_leaderboard_rows.size(), standings.size())):
		var entry: Dictionary = standings[i]
		var row: Dictionary = _leaderboard_rows[i]
		var name_lbl: Label = row["name"]
		var fare_lbl: Label = row["fare"]
		
		name_lbl.text = entry["name"] + (" ★" if entry["is_player"] else "")
		name_lbl.add_theme_color_override("font_color", entry["color"])
		fare_lbl.text = "₦%d" % entry["fare"]

func show_conductor_line(text: String) -> void:
	if conductor_label and conductor_panel:
		conductor_label.text = "📢 \"%s\"" % text
		_conductor_fade_timer = 2.4
		conductor_panel.modulate.a = 1.0

func update_speed(speed_px_per_s: float) -> void:
	if speed_label:
		var kmh: int = int(speed_px_per_s * 0.22)
		speed_label.text = "%d KM/H" % kmh

func update_boost(ratio: float, is_boosting: bool) -> void:
	if boost_bar:
		boost_bar.value = ratio * 100.0
	if boost_label:
		boost_label.text = "BOOSTING!" if is_boosting else "BOOST [SPACE]"
	if boost_glow:
		var alpha: float = 0.8 if is_boosting else 0.3
		boost_glow.modulate = Color(0.0, 0.95, 1.0, alpha)

func connect_bus(bus: Node) -> void:
	if not bus:
		return
	_player_bus_ref = bus
	if bus.has_signal("speed_changed"):
		bus.connect("speed_changed", Callable(self, "update_speed"))
	if bus.has_signal("boost_changed"):
		bus.connect("boost_changed", Callable(self, "update_boost"))
	if bus.has_signal("seats_changed"):
		bus.connect("seats_changed", Callable(self, "update_seats"))

func _on_horn_pressed() -> void:
	if _player_bus_ref and _player_bus_ref.has_method("request_horn"):
		_player_bus_ref.call("request_horn")

func _on_boost_pressed() -> void:
	if _player_bus_ref and _player_bus_ref.has_method("start_boost"):
		_player_bus_ref.call("start_boost")

func _on_boost_released() -> void:
	if _player_bus_ref and _player_bus_ref.has_method("stop_boost"):
		_player_bus_ref.call("stop_boost")
