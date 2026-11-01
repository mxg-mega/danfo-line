class_name HUD
extends CanvasLayer

## Minimal Neon HUD for Danfo Line.
## Displays competitive Player vs Rival Fare leaderboard, Speedometer, Boost gauge, and lead status.

@onready var player_fare_label: Label = %PlayerFareLabel
@onready var rival_fare_label: Label = %RivalFareLabel
@onready var lead_status_label: Label = %LeadStatusLabel
@onready var speed_label: Label = %SpeedLabel
@onready var boost_bar: ProgressBar = %BoostBar
@onready var boost_glow: Panel = %BoostGlow
@onready var boost_label: Label = %BoostLabel
@onready var controls_hint: Label = %ControlsHint

var player_fare: int = 0
var rival_fare: int = 0
var rival_name: String = "OSHODI ROCKET"

func _ready() -> void:
	update_player_fare(0)
	update_rival_fare(0)
	update_speed(0.0)
	update_boost(1.0, false)

func update_player_fare(amount: int) -> void:
	player_fare = amount
	if player_fare_label:
		player_fare_label.text = "YOU: ₦%d" % player_fare
	_update_lead_status()

func update_rival_fare(amount: int) -> void:
	rival_fare = amount
	if rival_fare_label:
		rival_fare_label.text = "%s: ₦%d" % [rival_name, rival_fare]
	_update_lead_status()

func _update_lead_status() -> void:
	if not lead_status_label:
		return
	if player_fare > rival_fare:
		lead_status_label.text = "YOU LEAD!"
		lead_status_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.05, 1.0)) # Gold
	elif rival_fare > player_fare:
		lead_status_label.text = "RIVAL LEADS!"
		lead_status_label.add_theme_color_override("font_color", Color(0.0, 0.92, 1.0, 1.0)) # Cyan
	else:
		lead_status_label.text = "TIED"
		lead_status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.8))

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
	if bus.has_signal("speed_changed"):
		bus.connect("speed_changed", Callable(self, "update_speed"))
	if bus.has_signal("boost_changed"):
		bus.connect("boost_changed", Callable(self, "update_boost"))
	if bus.has_signal("fare_changed"):
		bus.connect("fare_changed", Callable(self, "update_player_fare"))

func connect_rival(rival_bus: Node) -> void:
	if not rival_bus:
		return
	if "bus_name" in rival_bus:
		rival_name = str(rival_bus.get("bus_name")).to_upper()
	if rival_bus.has_signal("fare_changed"):
		rival_bus.connect("fare_changed", Callable(self, "update_rival_fare"))
