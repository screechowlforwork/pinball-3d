extends SceneTree

const Session = preload("res://scripts/session.gd")
var failures := 0

func check(condition: bool, title: String) -> void:
	if not condition:
		push_error(title)
		failures += 1

func _initialize() -> void:
	var state := Session.new()
	state.best = 100
	state.award(10, "INVALID")
	check(state.score == 0, "No scoring before start")
	state.start()
	state.award(100, "BUMPER")
	state.tick(1)
	state.award(100, "BUMPER")
	state.tick(1)
	check(state.message.begins_with("BUMPER"), "Repeated toast refreshes expiry")
	state.tick(0.8)
	check(state.message == "Find your rhythm.", "Toast expires")
	state.pause()
	state.award(100, "INVALID")
	check(state.score == 200 and not state.drain(), "Paused session ignores score and drain")
	state.resume()
	for i in 3:
		check(state.drain(), "Active ball drains")
		check(not state.drain(), "Duplicate drain ignored")
		if i < 2: state.next_ball()
	check(state.phase == Session.Phase.GAME_OVER and state.balls == 0, "Exactly three drains ends session")
	check(state.best == 200 and state.new_best, "Strictly higher score records new best")
	state.start()
	check(state.score == 0 and state.balls == 3 and not state.new_best and state.ball_active, "Restart resets session")
	state.award(200, "EQUAL")
	for i in 3:
		state.drain()
		state.next_ball()
	check(not state.new_best and state.best == 200, "Equal score is not new best")
	print("SESSION TESTS: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(failures)
