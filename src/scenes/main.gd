class_name Main
extends Node2D

## Main Game Arena for Danfo Line.
## Ties together RoadManager, PlayerBus, FollowCamera2D, and HUD.

const RoadManagerScript = preload("res://src/world/road_manager.gd")
const PlayerBusScript = preload("res://src/entities/bus/player_bus.gd")
const FollowCamera2DScript = preload("res://src/camera/follow_camera_2d.gd")
const HUDScript = preload("res://src/ui/hud.gd")

@onready var road_manager: Node2D = $RoadManager
@onready var player_bus: Node2D = $PlayerBus
@onready var camera: Camera2D = $FollowCamera2D
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	if road_manager and player_bus:
		road_manager.player_target = player_bus
		
	if camera and player_bus:
		camera.target = player_bus
		
	if hud and player_bus:
		hud.connect_bus(player_bus)

func _unhandled_input(event: InputEvent) -> void:
	# Quick reset shortcut for rapid prototyping
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
