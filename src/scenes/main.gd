class_name Main
extends Node2D

## Main Game Arena for Danfo Line.
## Ties together RoadManager, PassengerManager, PlayerBus, BotBus ("Oshodi Rocket"), Camera, and HUD.

const RoadManagerScript = preload("res://src/world/road_manager.gd")
const PassengerManagerScript = preload("res://src/entities/passenger/passenger_manager.gd")
const PlayerBusScript = preload("res://src/entities/bus/player_bus.gd")
const BotBusScript = preload("res://src/entities/bus/bot_bus.gd")
const FollowCamera2DScript = preload("res://src/camera/follow_camera_2d.gd")
const HUDScript = preload("res://src/ui/hud.gd")

@onready var road_manager: Node2D = $RoadManager
@onready var passenger_manager: Node2D = $PassengerManager
@onready var player_bus: Node2D = $PlayerBus
@onready var bot_bus: Node2D = $BotBus
@onready var camera: Camera2D = $FollowCamera2D
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	if road_manager and player_bus:
		road_manager.set("player_target", player_bus)
		
	if passenger_manager:
		if player_bus:
			passenger_manager.call("register_bus", player_bus)
		if bot_bus:
			passenger_manager.call("register_bus", bot_bus)
			
	if bot_bus and player_bus:
		bot_bus.set("player_target", player_bus)
		
	if camera and player_bus:
		camera.set("target", player_bus)
		
	if hud:
		if player_bus:
			hud.call("connect_bus", player_bus)
		if bot_bus:
			hud.call("connect_rival", bot_bus)

func _unhandled_input(event: InputEvent) -> void:
	# Quick reset shortcut for rapid prototyping
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
