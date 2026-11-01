class_name FloatingText
extends Node2D

## Floating neon score popup (+₦200, +₦500 VIP) that rises and fades out.

@export var float_speed: float = 75.0
@export var lifetime: float = 0.85

var _time_alive: float = 0.0
var _label: Label

func _ready() -> void:
	z_index = 20 # Render above all buses and trails
	_setup_label()

func _setup_label() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 18)
	# Center the label over the node
	_label.position = Vector2(-80.0, -15.0)
	_label.custom_minimum_size = Vector2(160.0, 30.0)
	add_child(_label)

func setup(text_content: String, text_color: Color) -> void:
	if not _label:
		_setup_label()
	_label.text = text_content
	_label.add_theme_color_override("font_color", text_color)
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	scale = Vector2(0.8, 0.8)

func _process(delta: float) -> void:
	_time_alive += delta
	position.y -= float_speed * delta
	
	var progress: float = _time_alive / lifetime
	# Scale punch on start
	if progress < 0.2:
		var s: float = lerpf(0.8, 1.25, progress / 0.2)
		scale = Vector2(s, s)
	else:
		var s: float = lerpf(1.25, 1.0, (progress - 0.2) / 0.8)
		scale = Vector2(s, s)
		
	# Fade out near end
	if progress > 0.5:
		var alpha: float = 1.0 - ((progress - 0.5) / 0.5)
		modulate.a = maxf(0.0, alpha)
		
	if _time_alive >= lifetime:
		queue_free()
