class_name HUD
extends CanvasLayer

## Minimal Neon HUD for Danfo Line.
## Displays Fare earnings, digital Speedometer, Boost gauge, and control hints.

@onready var fare_label: Label = %FareLabel
@onready var speed_label: Label = %SpeedLabel
@onready var boost_bar: ProgressBar = %BoostBar
@onready var boost_glow: Panel = %BoostGlow
@onready var boost_label: Label = %BoostLabel
@onready var controls_hint: Label = %ControlsHint

func _ready() -> void:
	update_fare(0)
	update_speed(0.0)
	update_boost(1.0, false)

func update_fare(amount: int) -> void:
	if fare_label:
		fare_label.text = "FARE: ₦%d" % amount

func update_speed(speed_px_per_s: float) -> void:
	if speed_label:
		# Convert pixels/s to an arcade km/h readout (~ 1 px/s = 0.2 km/h)
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
		bus.connect("fare_changed", Callable(self, "update_fare"))
