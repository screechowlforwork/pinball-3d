extends SceneTree

const Session = preload("res://scripts/session.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	test_award_and_lane_rules()
	test_combo_rules()
	test_combo_cap()
	test_rush_rules()
	test_saver_lifecycle()
	test_restart_resets_rules()
	if failures == 0:
		print("RULES TESTS: PASS")
	else:
		push_error("RULES TESTS: %d failure(s)" % failures)
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: " + description)

func test_award_and_lane_rules() -> void:
	var inactive = Session.new()
	check(inactive.award(10, "TARGET", "target:0") == 0, "inactive session rejects awards")

	var state = Session.new()
	state.start()
	check(state.award(7, "TARGET", "target:3") == 7, "unknown target ID receives ordinary points")
	check(state.targets == [false, false, false] and state.combo_count == 0, "unknown target ID has no objective or combo effect")
	check(state.message == "TARGET  +7", "toast displays the accepted award total")
	check(state.award(5, "ROLLOVER", "target:0") == 5, "mismatched title and ID receive ordinary points")
	check(state.lanes == [false, false, false] and state.combo_count == 0, "mismatched title and ID have no rule effect")

	var lanes = Session.new()
	lanes.start()
	check(lanes.award(10, "ROLLOVER", "lane:0") == 10, "first lane hit uses the current multiplier")
	lanes.tick(3.0)
	check(lanes.award(10, "ROLLOVER", "lane:1") == 10, "second lane hit uses the current multiplier")
	lanes.tick(3.0)
	check(lanes.award(10, "ROLLOVER", "lane:2") == 510, "third lane hit uses the old multiplier and adds 500")
	check(lanes.multiplier == 2, "three distinct lanes raise the multiplier")
	check(lanes.lanes == [false, false, false], "completed lane set clears")
	check(lanes.message == "ROLLOVER  +510", "lane toast includes its flat bonus")

	var capped = Session.new()
	capped.start()
	capped.multiplier = 5
	capped.award(1, "ROLLOVER", "lane:0")
	capped.tick(3.0)
	capped.award(1, "ROLLOVER", "lane:1")
	capped.tick(3.0)
	check(capped.award(1, "ROLLOVER", "lane:2") == 505, "capped lane completion still adds 500 to old-multiplier scoring")
	check(capped.multiplier == 5 and capped.lanes == [false, false, false], "lane set clears at multiplier cap")

func test_combo_rules() -> void:
	var state = Session.new()
	state.start()
	check(state.award(10, "TARGET", "target:0") == 10, "first qualifying shot starts combo at one")
	state.tick(2.0)
	check(state.award(10, "TARGET", "target:0") == 10, "repeated shot ID receives ordinary points")
	check(state.combo_count == 1 and state.combo_left == 1.0, "same ID neither advances nor refreshes combo")
	check(state.award(20, "BUMPER", "bumper:0") == 20, "bumper receives ordinary points")
	check(state.combo_count == 1 and state.combo_last_id == "target:0" and state.combo_left == 1.0, "bumper leaves combo state unchanged")

	check(state.award(10, "ROLLOVER", "lane:0") == 110, "different qualifying ID advances combo and adds 100")
	check(state.combo_count == 2 and state.combo_left == 3.0, "combo advancement refreshes its timer")
	state.tick(2.0)
	check(state.award(10, "ROLLOVER", "lane:0") == 10, "same latest ID has no advancement bonus")
	check(state.combo_count == 2 and state.combo_left == 1.0, "same latest ID does not refresh the timer")
	state.tick(1.0)
	check(state.combo_count == 0 and state.combo_left == 0.0 and state.combo_last_id == "", "combo expires at its deadline")
	check(state.award(10, "TARGET", "target:1") == 10, "a shot after expiry starts a fresh combo")
	check(state.combo_count == 1, "fresh combo starts at one after expiry")

func test_combo_cap() -> void:
	var state = Session.new()
	state.start()
	var ids: Array[String] = ["target:0", "lane:0", "target:1", "lane:1", "target:2"]
	var titles: Array[String] = ["TARGET", "ROLLOVER", "TARGET", "ROLLOVER", "TARGET"]
	var totals: Array[int] = [1, 101, 201, 301, 401]
	for index in range(ids.size()):
		check(state.award(1, titles[index], ids[index]) == totals[index], "combo step %d has exact score" % (index + 1))
	check(state.combo_count == 5 and state.combo_left == 3.0, "combo reaches its cap")
	check(state.rush_left == 20.0 and state.targets == [true, true, true], "third target starts Rush with all targets lit")

	check(state.award(1, "TARGET", "target:0") == 2, "different shot at combo cap earns no combo bonus during Rush")
	check(state.combo_count == 5 and state.combo_last_id == "target:0" and state.combo_left == 3.0, "different capped shot refreshes combo identity and timer")
	check(state.rush_left == 20.0 and state.targets == [true, true, true], "target hit during Rush neither retriggers nor clears targets")
	state.tick(2.0)
	check(state.award(1, "TARGET", "target:0") == 2, "same target ID during Rush still receives doubled ordinary points")
	check(state.combo_left == 1.0 and state.rush_left == 18.0, "repeated ID does not refresh combo or Rush timers")

func test_rush_rules() -> void:
	var state = Session.new()
	state.start()
	check(state.award(1, "TARGET", "target:0") == 1, "first target uses ordinary scoring")
	check(state.award(1, "TARGET", "target:1") == 101, "second target adds the combo flat bonus")
	check(state.award(1, "TARGET", "target:2") == 201, "Rush completion award uses pre-Rush scoring")
	check(state.rush_left == 20.0 and state.targets == [true, true, true], "three distinct targets activate Rush")
	check(state.award(2, "BUMPER") == 4, "Rush doubles ordinary contact scoring")
	state.tick(5.0)
	check(state.rush_left == 15.0, "Rush timer advances during active play")
	var frozen_rush: float = state.rush_left
	var frozen_message: float = state.message_left
	state.pause()
	state.tick(10.0)
	check(state.rush_left == frozen_rush and state.message_left == frozen_message, "pause freezes rule and toast clocks")
	state.resume()
	state.tick(15.0)
	check(state.rush_left == 0.0 and state.targets == [false, false, false], "Rush expiry clears target lights")

	var combo_flat = Session.new()
	combo_flat.start()
	combo_flat.award(1, "TARGET", "target:0")
	combo_flat.rush_left = 8.0
	check(combo_flat.award(10, "ROLLOVER", "lane:0") == 120, "Rush doubles ordinary points but not combo flat bonus")

	var lane_flat = Session.new()
	lane_flat.start()
	lane_flat.rush_left = 8.0
	lane_flat.lanes[0] = true
	lane_flat.lanes[1] = true
	check(lane_flat.award(10, "ROLLOVER", "lane:2") == 520, "Rush doubles ordinary points but not lane flat bonus")

func test_saver_lifecycle() -> void:
	var before_launch = Session.new()
	before_launch.start()
	before_launch.multiplier = 4
	before_launch.lanes[0] = true
	before_launch.targets[1] = true
	before_launch.rush_left = 12.0
	before_launch.combo_count = 2
	before_launch.combo_left = 1.0
	before_launch.combo_last_id = "lane:0"
	check(not before_launch.launched and before_launch.save_left == 0.0, "saver is inactive before launch")
	check(before_launch.drain(), "drain before launch is accepted")
	check(before_launch.balls == 2 and not before_launch.ball_active, "drain before launch loses a ball")
	check_rules_reset(before_launch, "pre-launch drain")
	before_launch.next_ball()
	check(before_launch.ball_active and not before_launch.launched and before_launch.save_left == 0.0, "new ball after pre-launch loss is unlaunched")

	var saved = Session.new()
	saved.start()
	saved.launch_ball()
	check(saved.launched and saved.save_left == 8.0, "first physical launch arms an eight-second save")
	saved.tick(2.0)
	saved.launch_ball()
	check(saved.save_left == 6.0, "relaunch does not refresh the save timer")
	saved.multiplier = 3
	saved.lanes[0] = true
	saved.targets[1] = true
	saved.rush_left = 11.0
	saved.combo_count = 2
	saved.combo_left = 2.0
	saved.combo_last_id = "target:0"
	saved.pause()
	saved.tick(5.0)
	check(saved.save_left == 6.0 and saved.combo_left == 2.0 and saved.rush_left == 11.0, "pause freezes saver, combo, and Rush clocks")
	saved.resume()
	check(saved.message_left == 2.0, "pause also freezes the toast clock")

	check(saved.drain(), "active saver accepts one drain")
	check(saved.balls == 3 and saved.saved_drain and saved.save_used, "saved drain preserves the current ball and consumes its save")
	check(saved.multiplier == 3 and saved.lanes == [true, false, false] and saved.targets == [false, true, false] and saved.rush_left == 11.0, "saved drain preserves non-combo rule state")
	check(saved.combo_count == 0 and saved.combo_left == 0.0 and saved.combo_last_id == "", "saved drain clears combo")
	check(not saved.drain() and saved.balls == 3, "duplicate saved drain is rejected")
	var respawn_rush: float = saved.rush_left
	saved.tick(5.0)
	check(saved.rush_left == respawn_rush and saved.message_left == 2.0, "respawn freezes Rush and toast clocks")
	saved.next_ball()
	check(saved.ball_active and not saved.saved_drain and saved.launched and saved.save_used, "saved ball reactivates without resetting saver state")
	saved.launch_ball()
	check(saved.save_left == 0.0, "saved-ball relaunch does not rearm the saver")
	saved.tick(1.0)
	check(saved.rush_left == 10.0, "rule clocks resume after saved-ball respawn")

	check(saved.drain(), "drain after using saver is a normal loss")
	check(saved.balls == 2 and not saved.ball_active, "normal post-save drain loses a ball")
	check_rules_reset(saved, "normal post-save drain")
	saved.next_ball()
	check(saved.ball_active and not saved.launched and not saved.save_used, "new ball after loss starts with an unarmed saver")

	var expired = Session.new()
	expired.start()
	expired.launch_ball()
	expired.tick(8.0)
	check(expired.save_left == 0.0 and not expired.save_used, "save window expires without being consumed")
	expired.launch_ball()
	check(expired.save_left == 0.0, "launch after expiry does not rearm the same ball")
	check(expired.drain() and expired.balls == 2, "expired saver does not prevent a life loss")
	check_rules_reset(expired, "expired-save drain")

func test_restart_resets_rules() -> void:
	var state = Session.new()
	state.best = 77
	state.start()
	state.score = 50
	state.balls = 1
	state.ball_active = false
	state.multiplier = 5
	state.lanes[1] = true
	state.targets[2] = true
	state.rush_left = 4.0
	state.combo_count = 4
	state.combo_left = 2.0
	state.combo_last_id = "lane:2"
	state.launched = true
	state.save_left = 3.0
	state.save_used = true
	state.saved_drain = true
	state.start()
	check(state.score == 0 and state.best == 77 and state.balls == 3, "restart resets session score and lives while preserving best")
	check(state.ball_active and state.new_best == false, "restart reactivates the first ball and clears new-best state")
	check_rules_reset(state, "restart")

func check_rules_reset(state, context: String) -> void:
	check(state.multiplier == 1, context + " resets multiplier")
	check(state.lanes == [false, false, false], context + " clears lanes")
	check(state.targets == [false, false, false], context + " clears targets")
	check(state.rush_left == 0.0, context + " clears Rush")
	check(state.combo_count == 0 and state.combo_left == 0.0 and state.combo_last_id == "", context + " clears combo")
	check(not state.launched and state.save_left == 0.0 and not state.save_used and not state.saved_drain, context + " resets saver")
