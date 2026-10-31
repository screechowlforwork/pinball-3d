extends SceneTree

var table: Node3D
var failures := 0

func check(condition: bool, title: String) -> void:
	print("%s: %s" % ["PASS" if condition else "FAIL", title])
	if not condition: failures += 1

func frames(count: int) -> void:
	for i in count: await physics_frame

func place(position: Vector3, velocity: Vector3) -> void:
	table.ball.freeze = true
	table.ball.position = position
	table.ball.linear_velocity = Vector3.ZERO
	await frames(2)
	table.ball.freeze = false
	table.ball.linear_velocity = velocity
	await frames(1)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	table = load("res://main.tscn").instantiate()
	root.add_child(table)
	await frames(2)
	table.muted = true
	table.start_game()
	await frames(10)
	table.set_control("launch", "test", true)
	await frames(120)
	table.set_control("launch", "test", false)
	await frames(160)
	check(table.launch_count == 1, "Latched charge/release launches")
	check(table.ball.position.x < 3.7, "Shooter exits into table without lane trap")
	print("Launch trajectory end: ", table.ball.position, " score=", table.game.score)
	await place(Vector3(0, 0.3, -7.4), Vector3.ZERO)
	await frames(4)
	check(table.game.score >= 150, "Physical rollover scores")
	await place(Vector3(-1.9, 0.3, -5.5), Vector3(0, 0, 15))
	await frames(18)
	check(table.score_events.has("BUMPER"), "Physical bumper scores")
	await place(Vector3(-3.9, 0.3, -2.8), Vector3(-20, 0, 0))
	await frames(12)
	check(table.score_events.has("TARGET"), "Physical target scores")
	await place(Vector3(0, 0.3, 0), Vector3(27, 0, 0))
	await frames(35)
	check(absf(table.ball.position.x) < 5, "CCD high-speed wall collision contains ball")
	await place(Vector3(-1.6, 0.3, 6.65), Vector3.ZERO)
	table.set_control("left", "test", true)
	await frames(20)
	check(table.impact_count > 0 and table.ball.linear_velocity.z < 0, "Flipper contact sends ball up-table")
	table.toggle_pause()
	check(not table.held.left and not table.launch_pending and table.ball.freeze, "Pause releases controls and freezes ball")
	table.toggle_pause()
	table.clear_controls()
	await place(Vector3(1.2, 0.3, 6.65), Vector3.ZERO)
	var previous_impacts: int = table.impact_count
	table.set_control("right", "test", true)
	await frames(20)
	check(table.impact_count > previous_impacts and table.ball.linear_velocity.z < 0, "Right flipper contact sends ball up-table")
	table.clear_controls()
	await place(Vector3(4.35, 0.3, 8.5), Vector3.ZERO)
	var lives: int = table.game.balls
	table.set_control("launch", "test", true)
	await frames(30)
	table.set_control("launch", "test", false)
	await frames(3)
	check(table.launch_count == 2 and table.game.balls == lives, "Returned shooter-lane ball relaunches without life loss")
	table.start_game()
	table.game.launch_ball()
	await place(Vector3(0, 0.3, 10.5), Vector3(0, 0, 5))
	await frames(110)
	check(table.game.balls == 3 and table.game.ball_active and table.game.save_used and table.game.launched, "Saved drain respawns same ball without rearming save")
	table.start_game()
	await frames(3)
	for i in 3:
		table.game.launch_ball()
		table.game.tick(8.1)
		await place(Vector3(0, 0.3, 10.5), Vector3(0, 0, 5))
		await frames(110)
	check(table.drain_count == 3 and table.game.phase == table.Session.Phase.GAME_OVER, "Three physical drains reach game over exactly once each")
	table.start_game()
	await frames(3)
	check(table.game.balls == 3 and table.game.score == 0 and table.respawn_left == 0 and table.cooldowns.is_empty(), "Restart clears timers and state")
	print("PHYSICS TESTS: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(failures)
