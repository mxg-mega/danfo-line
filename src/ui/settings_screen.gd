class_name SettingsScreen
extends Control

## Shared Settings / Options overlay for Danfo Line.
## Embedded by the main menu and by the pause screen; removed when `closed` fires.
## Currently supports: Master bus volume and window fullscreen (hidden on Android).

signal closed

const BG: Color = Color(0.03, 0.02, 0.05, 0.94)
const PANEL: Color = Color("100D16")
const INK: Color = Color("F4ECE4")
const MUTED: Color = Color("A79FB4")
const ACCENT: Color = Color("FFC400")

var _volume_slider: HSlider
var _volume_value: Label
var _fullscreen_check: CheckButton

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_panel()

func _build_background() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _build_panel() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 72)
	margin.add_theme_constant_override("margin_top", 96)
	margin.add_theme_constant_override("margin_bottom", 96)
	add_child(margin)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)

	var title: Label = _label("SETTINGS", 30, ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	# Master volume row
	var volume_row: VBoxContainer = _row_box()
	var slider_row: HBoxContainer = HBoxContainer.new()
	slider_row.add_theme_constant_override("separation", 12)
	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 100.0
	_volume_slider.step = 1.0
	_volume_slider.value = GameState.master_volume * 100.0
	_volume_slider.set("size_flags_horizontal", Control.SIZE_EXPAND_FILL)
	_volume_slider.custom_minimum_size = Vector2(0, 24)
	_volume_slider.value_changed.connect(_on_volume_changed)
	slider_row.add_child(_volume_slider)

	_volume_value = _label("%d%%" % int(GameState.master_volume * 100.0), 16, ACCENT)
	_volume_value.custom_minimum_size = Vector2(56, 0)
	slider_row.add_child(_volume_value)

	volume_row.add_child(_label("MASTER VOLUME", 15, MUTED))
	volume_row.add_child(slider_row)
	v.add_child(volume_row)

	# Fullscreen row (not on Android — the OS handles fullscreen there)
	if not OS.has_feature("android"):
		var fullscreen_row: HBoxContainer = HBoxContainer.new()
		fullscreen_row.add_theme_constant_override("separation", 12)
		var fs_label: Label = _label("FULLSCREEN", 15, MUTED)
		fs_label.set("size_flags_horizontal", Control.SIZE_EXPAND_FILL)
		fullscreen_row.add_child(fs_label)
		_fullscreen_check = CheckButton.new()
		_fullscreen_check.button_pressed = _is_fullscreen()
		_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
		fullscreen_row.add_child(_fullscreen_check)
		v.add_child(fullscreen_row)

	var back: Button = Button.new()
	back.text = "BACK"
	back.pressed.connect(func() -> void: closed.emit())
	v.add_child(back)

func _row_box() -> VBoxContainer:
	var row: VBoxContainer = VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	return row

func _label(text: String, size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED

func _on_volume_changed(value: float) -> void:
	GameState.set_master_volume(value / 100.0)
	if _volume_value:
		_volume_value.text = "%d%%" % int(value)

func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED)

func _unhandled_input(event: InputEvent) -> void:
	# Let Esc close the overlay instead of reaching the pause toggle beneath it.
	if event.is_action_pressed("ui_cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()