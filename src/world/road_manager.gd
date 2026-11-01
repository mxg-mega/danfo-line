class_name RoadManager
extends Node2D

## Infinite 4-Lane Highway Manager.
## Recycles road chunks seamlessly as the player drives north along -Y.

const RoadSegmentScene = preload("res://src/world/road_segment.tscn")

@export var chunk_count: int = 5
@export var segment_length: float = 1200.0
@export var player_target: Node2D

var _chunks: Array[Node2D] = []
var _northernmost_y: float = 0.0

func _ready() -> void:
	_init_chunks()

func _init_chunks() -> void:
	# Start with road extending slightly behind the spawn point (Y = +600)
	var start_y: float = 600.0
	_northernmost_y = start_y
	
	for i in range(chunk_count):
		var chunk: Node2D = RoadSegmentScene.instantiate() as Node2D
		chunk.position = Vector2(0.0, _northernmost_y)
		add_child(chunk)
		_chunks.append(chunk)
		_northernmost_y -= segment_length

func _process(_delta: float) -> void:
	if not player_target or not is_instance_valid(player_target):
		return
		
	var player_y: float = player_target.global_position.y
	_recycle_chunks(player_y)

func _recycle_chunks(player_y: float) -> void:
	# Check if any chunk has fallen well behind the player (south)
	for chunk in _chunks:
		# chunk extends from chunk.position.y down to (chunk.position.y - segment_length)
		# If the top of the chunk (chunk.position.y - segment_length) is further south than player by > 600px
		if (chunk.position.y - segment_length) > (player_y + 600.0):
			# Move this chunk to the very front of the highway
			chunk.position.y = _northernmost_y
			_northernmost_y -= segment_length
