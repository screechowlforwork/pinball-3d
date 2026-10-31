extends SceneTree

var failures := 0

func check(condition: bool, title: String) -> void:
	print("%s: %s" % ["PASS" if condition else "FAIL", title])
	if not condition: failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var table = load("res://main.tscn").instantiate()
	root.add_child(table)
	table.start_game()
	table.set_physics_process(false)
	table.ball.freeze = true
	table.muted = true
	table.set_reduced_effects(false)
	var lane: Node3D
	for child in table.get_children():
		if child.get_meta("shot_id", "") == "lane:0": lane = child
	table.award_contact(lane, 150, "ROLLOVER")
	var score: int = table.game.score
	table.award_contact(lane, 150, "ROLLOVER")
	check(table.effects.bursts.size() == 1 and table.game.score == score, "Cooldown suppresses duplicate score and effect")
	table.toggle_pause()
	var life: float = table.effects.bursts[0].left
	table._physics_process(1.0)
	check(table.effects.bursts[0].left == life, "Pause freezes effect lifetime")
	table.toggle_pause()
	table.ball.freeze = true
	for i in 30:
		table.effects.hit(Vector3.ZERO, 100, table.MINT)
		table.effects.tick(0.04, Vector3.ZERO, true)
		check(table.effects.bursts.size() <= table.effects.MAX_BURSTS and table.effects.trail.size() <= table.effects.MAX_TRAIL, "Live effects stay bounded")
	table.effects.tick(1.0, Vector3.ZERO, false)
	check(table.effects.bursts.is_empty() and table.effects.trail.is_empty(), "Effects expire and free their nodes")
	table.effects.hit(Vector3.ZERO, 100, table.MINT)
	table.set_reduced_effects(true)
	table.effects.hit(Vector3.ZERO, 100, table.MINT)
	table.effects.tick(0.1, Vector3.ZERO, true)
	table.refresh_ui()
	check(table.effects.bursts.is_empty() and table.effects.trail.is_empty(), "Reduced effects clears and suppresses transient motion")
	check(table.lane_lamps[0].material_override.emission_enabled and table.lane_label.text.contains("●"), "Reduced mode retains objective lamp and HUD")
	var cfg := ConfigFile.new()
	check(cfg.load("user://record.cfg") == OK and cfg.get_value("orbit", "reduced_effects") == true, "Reduced setting saved")
	table.reduced_effects = false
	table.load_record()
	check(table.reduced_effects, "Reduced setting reloads")
	table.set_reduced_effects(false)
	table.game.launch_ball()
	table.effects.hit(Vector3.ZERO, 100, table.MINT)
	table.ball.position = Vector3(0, 0.3, 10.5)
	table._physics_process(0.01)
	check(table.effects.bursts.is_empty() and not table.game.ball_active and table.game.balls == 3, "Saved drain cleans effects without losing a life")
	table.start_game()
	check(table.effects.bursts.is_empty() and table.effects.trail.is_empty() and table.cooldowns.is_empty(), "Restart clears all transient effects and cooldowns")
	table.free()
	print("EFFECTS TESTS: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(failures)
