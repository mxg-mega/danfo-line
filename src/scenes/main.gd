class_name Main
extends Node2D

## Main Game Arena for Danfo Line.
## Orchestrates Player, 3 Rival Bots, Obstacles, Passengers, Audio, Conductor, and Game Loop.

const BotBusScene = preload("res://src/entities/bus/bot_bus.tscn")
const BotBusScript = preload("res://src/entities/bus/bot_bus.gd")

@onready var audio_manager: Node = $AudioManager
@onready var game_manager: Node = $GameManager
@onready var road_manager: Node2D = $RoadManager
@onready var passenger_manager: Node2D = $PassengerManager
@onready var obstacle_manager: Node2D = $ObstacleManager
@onready var conductor_system: Node = $ConductorSystem
@onready var player_bus: Node2D = $PlayerBus
@onready var camera: Camera2D = $FollowCamera2D
@onready var hud: CanvasLayer = $HUD
@onready var results_screen: CanvasLayer = $ResultsScreen
@onready var pause_screen: CanvasLayer = $PauseScreen

var _buses: Array[Node2D] = []
var _rivals: Array[Node2D] = []

func _ready() -> void:
	_init_roster()
	_wire_systems()

func _init_roster() -> void:
	_buses.append(player_bus)

	# Player takes the driver chosen on the Driver Select screen.
	var player_driver: Dictionary = GameState.driver()
	if player_bus.has_method("apply_driver_identity") and not player_driver.is_empty():
		player_bus.call("apply_driver_identity", player_driver["name"], player_driver["accent"])

	# Rival bots take the remaining roster drivers (names + accent colors);
	# personalities and skill levels are unchanged.
	var rivals_roster: Array[Dictionary] = GameState.roster_without_driver()
	var bot_personalities: Array = [
		[BotBusScript.Personality.GREEDY, 0.85],      # Bot 1 (Lane 2)
		[BotBusScript.Personality.AGGRESSIVE, 0.9],   # Bot 2 (Lane 0)
		[BotBusScript.Personality.CAUTIOUS, 0.75],    # Bot 3 (Lane 3)
	]
	var bot_positions: Array[Vector2] = [Vector2(70.0, -40.0), Vector2(-210.0, -80.0), Vector2(210.0, 40.0)]
	for i: int in range(3):
		var bot: BotBus = BotBusScene.instantiate() as BotBus
		bot.position = bot_positions[i]
		add_child(bot)
		var driver: Dictionary = rivals_roster[i]
		bot.configure_identity(
			str(driver["name"]),
			driver["accent"],
			bot_personalities[i][0],
			bot_personalities[i][1]
		)
		_buses.append(bot)
		_rivals.append(bot)

func _wire_systems() -> void:
	# 1. Camera & Road
	if road_manager and player_bus:
		road_manager.set("player_target", player_bus)
	if camera and player_bus:
		camera.set("target", player_bus)
		
	# 2. Register all 4 buses with spawners
	for bus in _buses:
		if passenger_manager:
			passenger_manager.call("register_bus", bus)
		if obstacle_manager:
			obstacle_manager.call("register_bus", bus)
			
	# 3. Configure bot player targets
	for rival in _rivals:
		rival.set("player_target", player_bus)
		
	# 4. Game Manager
	if game_manager:
		game_manager.register_buses(_buses)
		game_manager.time_updated.connect(_on_time_updated)
		game_manager.match_ended.connect(_on_match_ended)
		
	# 5. Conductor System
	if conductor_system:
		conductor_system.setup(player_bus, _rivals)
		conductor_system.speech_triggered.connect(hud.show_conductor_line)
		
	# 6. HUD connections
	if hud and player_bus:
		hud.connect_bus(player_bus)

	# 7. Pause system
	if pause_screen:
		pause_screen.set("results_screen", results_screen)
	if hud and pause_screen and hud.has_signal("pause_requested"):
		hud.connect("pause_requested", Callable(pause_screen, "open"))

func _process(_delta: float) -> void:
	# Update HUD live standings
	if game_manager and hud:
		var standings: Array[Dictionary] = game_manager.get_standings()
		hud.update_standings(standings)

func _on_time_updated(time_left: float) -> void:
	if hud:
		hud.update_timer(time_left)

func _on_match_ended(standings: Array[Dictionary]) -> void:
	if results_screen:
		results_screen.show_results(standings)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
