class_name MainMenu
extends Control

## Main Menu for Danfo Line. Entry scene: Drive → driver select, Settings overlay, Quit.
## All UI is built in code, matching the code-built UI pattern of ResultsScreen / DriverSelect.

const BG: Color = Color("07060A")
const INK: Color = Color("F4ECE4")
const MUTED: Color = Color("A79FB4")
const ACCENT: Color = Color("FFC400")

const DRIVER_SELECT_SCENE: String = "res://src/ui/driver_select.tscn"

var _settings: SettingsScreen
var _buttons_box: VBoxContainer

func _ready() -> void:
	_build_background()
	_build_layout()

	if OS.has_feature("web") or OS.has_feature("android"):
		# No meaningful quit target on Web / Android
		var quit_btn: Button = _buttons_box.get_node(^"QuitButton") as Button
		if quit_btn:
			quit_btn.visible = false

func _build_background() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _build_layout() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 120)
	margin.add_theme_constant_override("margin_bottom", 80)
	add_child(margin)

	var v: VBoxContainer = VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 18)
	margin.add_child(v)

	var title: Label = _label("DANFO LINE", 64, ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var subtitle: Label = _label("FIND PASSENGERS. DODGE TROUBLE. EARN THE BIGGEST FARE.", 16, MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(subtitle)

	if not GameState.driver_id.is_empty():
		var d: Dictionary = GameState.driver()
		var choose_lbl: Label = _label("DRIVER: %s" % str(d.get("name", "")).to_upper(), 18, d.accent)
		choose_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(choose_lbl)

	var spacer: Control = Control.new()
	spacer.set("size_flags_vertical", Control.SIZE_EXPAND_FILL)
	v.add_child(spacer)

	_buttons_box = VBoxContainer.new()
	_buttons_box.add_theme_constant_override("separation", 12)
	v.add_child(_buttons_box)

	_buttons_box.add_child(_menu_button("START SHIFT", _on_start_pressed))
	_buttons_box.add_child(_menu_button("SETTINGS", _on_settings_pressed))
	var quit_btn: Button = _menu_button("QUIT", _on_quit_pressed)
	quit_btn.name = "QuitButton"
	_buttons_box.add_child(quit_btn)

	var footer: Label = _label("HOMETOWN HUSTLE JAM BUILD", 12, Color(MUTED, 0.6))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.set("size_flags_vertical", Control.SIZE_SHRINK_END)
	v.add_child(footer)

func _menu_button(text: String, on_pressed: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(on_pressed)
	return b

func _label(text: String, size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(DRIVER_SELECT_SCENE)

func _on_settings_pressed() -> void:
	if is_instance_valid(_settings):
		return
	_settings = SettingsScreen.new()
	_settings.closed.connect(_remove_settings)
	add_child(_settings)

func _remove_settings() -> void:
	if is_instance_valid(_settings):
		_settings.queue_free()

func _on_quit_pressed() -> void:
	get_tree().quit()