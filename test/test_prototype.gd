extends SceneTree

## Automated Headless Integration Test for Danfo Line Day 1 Prototype

func _init() -> void:
	print("--- Starting Danfo Line Integration Test ---")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var main_scene: PackedScene = load("res://src/scenes/main.tscn")
	if not main_scene:
		printerr("FAIL: Could not load main.tscn")
		quit(1)
		return
		
	var main_node: Node = main_scene.instantiate()
	root.add_child(main_node)
	
	var player_bus: Node2D = main_node.get_node("PlayerBus") as Node2D
	var road_manager: Node2D = main_node.get_node("RoadManager") as Node2D
	var hud: CanvasLayer = main_node.get_node("HUD") as CanvasLayer
	var camera: Camera2D = main_node.get_node("FollowCamera2D") as Camera2D
	
	assert(player_bus != null, "PlayerBus node must exist")
	assert(road_manager != null, "RoadManager node must exist")
	assert(hud != null, "HUD node must exist")
	assert(camera != null, "FollowCamera2D node must exist")
	print("✓ All essential nodes instantiated successfully.")
	
	# Initial position
	var start_pos: Vector2 = player_bus.global_position
	print("✓ Initial bus position: ", start_pos)
	
	# Simulate 30 physics frames
	for f in range(30):
		player_bus._physics_process(1.0 / 60.0)
		road_manager._process(1.0 / 60.0)
		camera._process(1.0 / 60.0)
	
	# Verify forward propulsion (-Y)
	var moved_pos: Vector2 = player_bus.global_position
	print("✓ Bus position after 30 normal frames: ", moved_pos)
	assert(moved_pos.y < start_pos.y, "Bus should move forward (-Y)")
	print("✓ Forward movement verified. Distance traveled: ", start_pos.y - moved_pos.y)
	
	# Test Steering
	player_bus.set("steer_input", 1.0) # Steer Right
	for f in range(20):
		player_bus._physics_process(1.0 / 60.0)
	print("✓ Bus position after right steer: ", player_bus.global_position)
	assert(player_bus.global_position.x > moved_pos.x, "Bus X should increase when steering right")
	print("✓ Steering physics verified.")
	
	# Test Boost
	var prev_speed: float = player_bus.get("current_forward_speed")
	player_bus.set("is_boosting", true)
	for f in range(30):
		player_bus._physics_process(1.0 / 60.0)
	var boosted_speed: float = player_bus.get("current_forward_speed")
	var boost_energy: float = player_bus.get("boost_energy")
	print("✓ Boosted speed: %f (was %f), Boost energy remaining: %f" % [boosted_speed, prev_speed, boost_energy])
	assert(boosted_speed > prev_speed, "Speed should increase during boost")
	assert(boost_energy < 100.0, "Boost energy should deplete when boosting")
	print("✓ Boost mechanics verified.")
	
	# Test Trail2D
	var trail: Node = null
	for child in player_bus.get_children():
		if child.has_method("set_color"):
			trail = child
			break
	assert(trail != null, "Trail2D instance must exist under PlayerBus")
	print("✓ Trail2D confirmed active.")
	
	# Test Road Chunk Recycling over extended driving
	var initial_chunk_positions: Array[float] = []
	for chunk in road_manager.get("_chunks"):
		initial_chunk_positions.append(chunk.position.y)
	print("✓ Road initial chunk Y positions: ", initial_chunk_positions)
	
	# Simulate 300 frames of full-speed driving (traveling ~3500px)
	for f in range(300):
		player_bus._physics_process(1.0 / 60.0)
		road_manager._process(1.0 / 60.0)
	
	var recycled_chunk_positions: Array[float] = []
	for chunk in road_manager.get("_chunks"):
		recycled_chunk_positions.append(chunk.position.y)
	print("✓ Road chunk Y positions after drive: ", recycled_chunk_positions)
	assert(recycled_chunk_positions != initial_chunk_positions, "Road chunks should recycle to new positions ahead")
	print("✓ Road chunk recycling verified.")
	
	print("--- ALL DANFO LINE INTEGRATION TESTS PASSED SUCCESSFULLY! ---")
	main_node.queue_free()
	quit(0)
