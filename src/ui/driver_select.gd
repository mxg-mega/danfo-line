class_name DriverSelect
extends Control

## DANFO DRIVER SELECT — builds the four driver cards from Drivers.ROSTER.
## Adapted from the starter project's code-built UI layout for the game's 720x1280
## portrait viewport (2x2 card grid instead of the starter's wide horizontal row).

const BG: Color = Color("07060A")
const PANEL: Color = Color("100D16")
const INK: Color = Color("F4ECE4")
const MUTED: Color = Color("A79FB4")

const MAIN_MENU_SCENE: String = "res://src/ui/main_menu.tscn"
const GAME_SCENE: String = "res://src/scenes/main.tscn"

func _ready() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	margin.add_child(root)

	var header: HBoxContainer = HBoxContainer.new()
	var back: Button = Button.new()
	back.text = "< BACK"
	back.custom_minimum_size = Vector2(90, 40)
	back.pressed.connect(_on_back_pressed)
	header.add_child(back)
	var title: Label = _label("DANFO DRIVER SELECT", 32, Color("FFC400"))
	title.set("size_flags_horizontal", Control.SIZE_EXPAND_FILL)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)
	# Invisible spacer to keep the title visually centered between back button and edge
	var pad: Control = Control.new()
	pad.custom_minimum_size = Vector2(90, 0)
	header.add_child(pad)
	root.add_child(header)

	root.add_child(_centered_label("Choose your don.", 18, MUTED))

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.set("size_flags_vertical", Control.SIZE_EXPAND_FILL)
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	root.add_child(grid)
	for d: Dictionary in Drivers.ROSTER:
		grid.add_child(_make_card(d))

func _centered_label(text: String, size: int, color: Color) -> Label:
	var l: Label = _label(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _label(text: String, size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Let taps/clicks fall through to the parent card so the whole card selects.
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _style(accent: Color, selected: bool) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = PANEL
	s.border_color = accent if selected else accent.darkened(0.55)
	s.set_border_width_all(3 if selected else 2)
	s.set_corner_radius_all(10)
	s.shadow_color = Color(accent, 0.55 if selected else 0.0)
	s.shadow_size = 14
	s.set_content_margin_all(10)
	return s

func _make_card(d: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.set("size_flags_horizontal", Control.SIZE_EXPAND_FILL)
	card.add_theme_stylebox_override("panel", _style(d.accent, false))
	card.mouse_entered.connect(func() -> void: card.add_theme_stylebox_override("panel", _style(d.accent, true)))
	card.mouse_exited.connect(func() -> void: card.add_theme_stylebox_override("panel", _style(d.accent, false)))
	# The whole card is tappable — easier for mobile players than aiming at the button.
	card.gui_input.connect(_on_card_gui_input.bind(d.id))

	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)

	var accent: Color = d.accent
	var tex: TextureRect = TextureRect.new()
	tex.texture = load(d.portrait)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(0, 170)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tex)

	v.add_child(_label(str(d.name).to_upper(), 22, accent))

	var bio: Label = _label(d.bio, 12, INK)
	bio.set("size_flags_vertical", Control.SIZE_EXPAND_FILL)
	v.add_child(bio)
	v.add_child(_label("+ " + d.perk, 12, Color("7CFF4F")))
	v.add_child(_label("- " + d.flaw, 12, Color("FF6B6B")))

	var btn: Button = Button.new()
	btn.text = "Drive as " + d.name
	btn.pressed.connect(_on_choose.bind(d.id))
	v.add_child(btn)
	return card

## Tap / click anywhere on a card picks that driver and starts the race.
func _on_card_gui_input(event: InputEvent, id: String) -> void:
	var clicked_mouse: bool = event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var touched: bool = event is InputEventScreenTouch and event.pressed
	if clicked_mouse or touched:
		_on_choose(id)

func _on_choose(id: String) -> void:
	GameState.set_driver(id)
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)