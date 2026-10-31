extends SceneTree

# Rendered, scripted workload; not a human-play or GPU-time benchmark.
const WARMUP_SECONDS := 5.0
const SAMPLE_SECONDS := 30.0
var table: Node3D
var started_usec := 0
var previous_usec := 0
var samples_ms: Array[float] = []
var tick := 0
var output := "user://performance.json"
var pauses := 0
var warmup_pauses := 0

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	call_deferred("start")

func start() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This measurement needs a rendered window; do not use --headless.")
		quit(1)
		return
	table = load("res://main.tscn").instantiate()
	root.add_child(table)
	table.muted = false
	table.start_game()
	started_usec = Time.get_ticks_usec()

func _physics_process(_delta: float) -> bool:
	if started_usec == 0: return false
	tick += 1
	if table.game.phase == table.Session.Phase.GAME_OVER: table.start_game()
	if table.game.phase == table.Session.Phase.PAUSED:
		if float(Time.get_ticks_usec() - started_usec) / 1000000.0 >= WARMUP_SECONDS:
			pauses += 1
		else:
			warmup_pauses += 1
		table.toggle_pause()
	table.set_control("left", "benchmark", tick % 60 < 24)
	table.set_control("right", "benchmark", tick % 72 < 28)
	table.set_control("launch", "benchmark", table.in_shooter_lane() and tick % 180 < 120)
	return false

func _process(_delta: float) -> bool:
	if started_usec == 0: return false
	var now := Time.get_ticks_usec()
	var elapsed := float(now - started_usec) / 1000000.0
	if elapsed >= WARMUP_SECONDS:
		if previous_usec != 0: samples_ms.append(float(now - previous_usec) / 1000.0)
		previous_usec = now
	if elapsed >= WARMUP_SECONDS + SAMPLE_SECONDS:
		finish()
	return false

func percentile(sorted: Array[float], fraction: float) -> float:
	return sorted[maxi(0, ceili(sorted.size() * fraction) - 1)]

func finish() -> void:
	var sorted := samples_ms.duplicate()
	sorted.sort()
	if sorted.is_empty():
		quit(1)
		return
	var total_ms := 0.0
	var over_33 := 0
	for value in samples_ms:
		total_ms += value
		if value > 1000.0 / 30.0: over_33 += 1
	var report := {
		"workload": "scripted native launch/flipper loop; no ball teleportation",
		"metric": "monotonic CPU wall-clock intervals between SceneTree process callbacks, not GPU time",
		"warmup_seconds": WARMUP_SECONDS, "measured_seconds": total_ms / 1000.0,
		"sample_count": sorted.size(), "mean_ms": total_ms / sorted.size(),
		"average_callback_fps": sorted.size() * 1000.0 / total_ms,
		"p50_ms": percentile(sorted, 0.5), "p95_ms": percentile(sorted, 0.95),
		"p99_ms": percentile(sorted, 0.99), "max_ms": sorted.back(),
		"intervals_over_33_33_ms": over_33, "focus_pauses": pauses,
		"warmup_focus_pauses": warmup_pauses, "audio_driver": AudioServer.get_driver_name(),
		"viewport": str(root.size), "gpu": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"godot": Engine.get_version_info().string,
		"physics_hz": Engine.physics_ticks_per_second,
		"raw_intervals_ms": samples_ms
	}
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write performance output: " + output)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	report.erase("raw_intervals_ms")
	print(JSON.stringify(report))
	started_usec = 0
	quit(0 if pauses == 0 else 2)
