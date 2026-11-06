class_name ResultsScreen
extends CanvasLayer

## End-of-Day Shift Results Modal.
## Displays final 4-bus rankings, winner declaration, and restart button.

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var standings_container: VBoxContainer = %StandingsContainer
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton
@onready var modal_panel: PanelContainer = %ModalPanel

func _ready() -> void:
	visible = false
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func show_results(standings: Array[Dictionary]) -> void:
	visible = true
	
	# Determine player rank
	var player_rank: int = 1
	var player_won: bool = false
	for i in range(standings.size()):
		if standings[i]["is_player"]:
			player_rank = i + 1
			player_won = (player_rank == 1)
			break
			
	if title_label:
		if player_won:
			title_label.text = "🏆 YOU WIN — LAGOS ROAD KING!"
			title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.05, 1.0))
		else:
			title_label.text = "DAY OVER — SHIFT ENDED"
			title_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
			
	if subtitle_label:
		subtitle_label.text = "You finished #%d out of 4 drivers!" % player_rank

	# Build standings entries
	if standings_container:
		for child in standings_container.get_children():
			child.queue_free()
			
		for i in range(standings.size()):
			var entry: Dictionary = standings[i]
			var row: HBoxContainer = HBoxContainer.new()
			row.add_theme_constant_override("separation", 16)
			
			var rank_lbl: Label = Label.new()
			rank_lbl.text = "#%d" % (i + 1)
			rank_lbl.add_theme_font_size_override("font_size", 18)
			rank_lbl.add_theme_color_override("font_color", entry["color"])
			
			var name_lbl: Label = Label.new()
			name_lbl.text = entry["name"] + (" (YOU)" if entry["is_player"] else "")
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_lbl.add_theme_font_size_override("font_size", 18)
			name_lbl.add_theme_color_override("font_color", entry["color"])
			
			var fare_lbl: Label = Label.new()
			fare_lbl.text = "₦%d" % entry["fare"]
			fare_lbl.add_theme_font_size_override("font_size", 18)
			fare_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
			
			row.add_child(rank_lbl)
			row.add_child(name_lbl)
			row.add_child(fare_lbl)
			standings_container.add_child(row)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
