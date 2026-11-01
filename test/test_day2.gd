extends SceneTree

## Automated Headless Integration Test for Danfo Line Day 2
## Tests Roadside Passengers, Collection, Floating Text, and Oshodi Rocket Bot AI.

func _init() -> void:
	print("--- Starting Danfo Line Day 2 Integration Test ---")
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
	var bot_bus: Node2D = main_node.get_node("BotBus") as Node2D
	var passenger_mgr: Node2D = main_node.get_node("PassengerManager") as Node2D
	var hud: CanvasLayer = main_node.get_node("HUD") as CanvasLayer
	
	assert(player_bus != null, "PlayerBus must exist")
	assert(bot_bus != null, "BotBus must exist")
	assert(passenger_mgr != null, "PassengerManager must exist")
	assert(hud != null, "HUD must exist")
	print("✓ All Day 2 nodes initialized.")
	
	# 1. Test Passenger Spawning
	# Advance 1 frame so PassengerManager spawns ahead
	passenger_mgr._process(1.0 / 60.0)
	var passengers: Array[Node] = get_nodes_in_group("passengers")
	print("✓ Spawned passenger count ahead of race: ", passengers.size())
	assert(passengers.size() > 0, "PassengerManager should have spawned roadside passengers")
	
	# Verify curb positions
	var found_left: bool = false
	var found_right: bool = false
	for p in passengers:
		var p_area: Area2D = p as Area2D
		if absf(p_area.position.x - (-260.0)) < 10.0:
			found_left = true
		if absf(p_area.position.x - 260.0) < 10.0:
			found_right = true
	print("✓ Passengers placed on curbs - Left: %s, Right: %s" % [found_left, found_right])
	assert(found_left or found_right, "Passengers should spawn on highway curbs")
	
	# 2. Test Player Passenger Pickup
	var test_passenger: Area2D = passengers[0] as Area2D
	var fare_val: int = int(test_passenger.get("fare_value"))
	var prev_player_fare: int = int(player_bus.get("current_fare"))
	
	# Simulate collection by player
	test_passenger.call("collect", player_bus)
	var new_player_fare: int = int(player_bus.get("current_fare"))
	print("✓ Player collected passenger! Previous Fare: %d, New Fare: %d (Expected +%d)" % [prev_player_fare, new_player_fare, fare_val])
	assert(new_player_fare == prev_player_fare + fare_val, "Player fare must increase by passenger value")
	
	# Verify HUD updated
	var hud_player_fare: int = int(hud.get("player_fare"))
	assert(hud_player_fare == new_player_fare, "HUD should mirror player fare")
	print("✓ HUD player fare verified: ₦%d" % hud_player_fare)
	
	# 3. Test Bot Passenger Pickup & Rival Fare
	var bot_passenger: Area2D = passengers[1] as Area2D if passengers.size() > 1 else null
	if not bot_passenger or bot_passenger.get("is_collected"):
		# Spawn dedicated test passenger for bot
		passenger_mgr.call("_spawn_passenger", bot_bus.global_position.y - 100.0)
		for p in get_nodes_in_group("passengers"):
			if not (p as Area2D).get("is_collected"):
				bot_passenger = p as Area2D
				break
				
	var bot_fare_val: int = int(bot_passenger.get("fare_value"))
	var prev_bot_fare: int = int(bot_bus.get("current_fare"))
	bot_passenger.call("collect", bot_bus)
	var new_bot_fare: int = int(bot_bus.get("current_fare"))
	print("✓ Oshodi Rocket collected passenger! Previous: %d, New: %d (Expected +%d)" % [prev_bot_fare, new_bot_fare, bot_fare_val])
	assert(new_bot_fare == prev_bot_fare + bot_fare_val, "Bot fare must increase by passenger value")
	
	var hud_rival_fare: int = int(hud.get("rival_fare"))
	assert(hud_rival_fare == new_bot_fare, "HUD should mirror rival fare")
	print("✓ HUD rival fare verified: ₦%d" % hud_rival_fare)
	
	# 4. Test Bot AI Passenger Seeking & Steering
	# Place passenger ahead on the far left curb
	var target_p_y: float = bot_bus.global_position.y - 300.0
	passenger_mgr.call("_spawn_passenger", target_p_y)
	# Find that spawned passenger
	var target_p: Area2D = null
	for p in get_nodes_in_group("passengers"):
		var pa: Area2D = p as Area2D
		if absf(pa.global_position.y - target_p_y) < 5.0:
			target_p = pa
			break
			
	if target_p:
		target_p.global_position.x = -260.0 # Force left curb
		bot_bus._process(0.15) # Trigger AI scan
		print("✓ Bot AI target passenger detected: ", bot_bus.get("target_passenger") != null)
		print("✓ Bot AI steer input toward target: ", bot_bus.get("steer_input"))
		assert(float(bot_bus.get("steer_input")) < 0.0, "Bot should steer left toward left curb passenger")
		print("✓ Bot greedy intercept steering verified!")
		
	# 5. Test Dynamic Rubberbanding
	# Move bot far behind player
	bot_bus.global_position.y = player_bus.global_position.y + 400.0
	bot_bus.call("_update_pacing_and_boost")
	print("✓ Bot lagging pacing - is_boosting: %s, base_speed: %f" % [bot_bus.get("is_boosting"), bot_bus.get("base_speed")])
	assert(bool(bot_bus.get("is_boosting")) == true, "Bot should boost to catch up when lagging")
	print("✓ Dynamic rubberbanding verified!")
	
	print("--- ALL DAY 2 INTEGRATION TESTS PASSED SUCCESSFULLY! ---")
	main_node.queue_free()
	quit(0)
