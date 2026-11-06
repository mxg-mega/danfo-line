class_name Passenger
extends Area2D

## Roadside passenger that awards fare to the first Danfo bus that reaches them.

signal collected(claiming_bus: Node, fare_amount: int)

const FloatingTextScript = preload("res://src/effects/floating_text.gd")

@export var fare_value: int = 150
@export var is_vip: bool = false
@export var facing_road_dir: float = 1.0

var is_collected: bool = false

@onready var visual: Node2D = $PassengerVisual
@onready var fare_tag: Label = $FareTag

func _ready() -> void:
	# Add to group for fast scanning by bot AI
	add_to_group("passengers")
	
	if is_vip:
		fare_value = 500
	elif fare_value == 150:
		# Randomize standard fare slightly between ₦120 and ₦220
		fare_value = int(randf_range(12, 22)) * 10
		
	_update_display()
	
	# Connect overlap detection
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _update_display() -> void:
	if visual:
		visual.set("is_vip", is_vip)
		visual.set("facing_road_dir", facing_road_dir)
		if is_vip:
			visual.set("passenger_color", Color(1.0, 0.08, 0.65, 1.0))
		else:
			visual.set("passenger_color", Color(0.2, 1.0, 0.3, 1.0))
			
	if fare_tag:
		if is_vip:
			fare_tag.text = "₦%d VIP!" % fare_value
			fare_tag.add_theme_color_override("font_color", Color(1.0, 0.08, 0.65, 1.0))
		else:
			fare_tag.text = "₦%d" % fare_value
			fare_tag.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.has_method("add_fare"):
		collect(body)

func _on_area_entered(area: Area2D) -> void:
	if is_collected:
		return
	var bus: Node = area.get_parent()
	if bus and bus.has_method("add_fare"):
		collect(bus)

func collect(claiming_bus: Node) -> void:
	if is_collected:
		return
	is_collected = true
	
	# Award fare to claiming bus
	claiming_bus.call("add_fare", fare_value)
	collected.emit(claiming_bus, fare_value)
	
	# Audio feedback
	var tree_root: Window = get_tree().root
	if tree_root:
		var am: Node = tree_root.find_child("AudioManager", true, false)
		if am:
			if is_vip and am.has_method("play_vip_pickup"):
				am.call("play_vip_pickup")
			elif am.has_method("play_pickup"):
				am.call("play_pickup")
	
	# Spawn floating score feedback
	_spawn_feedback()
	
	queue_free()

func _spawn_feedback() -> void:
	var popup: Node2D = FloatingTextScript.new()
	popup.global_position = global_position + Vector2(0, -20.0)
	var color: Color = Color(1.0, 0.08, 0.65, 1.0) if is_vip else Color(1.0, 0.88, 0.05, 1.0)
	var prefix: String = "+₦%d VIP!" % fare_value if is_vip else "+₦%d" % fare_value
	popup.call("setup", prefix, color)
	
	# Add to main scene root or current tree
	var tree_root: Window = get_tree().root
	if tree_root:
		tree_root.add_child(popup)
