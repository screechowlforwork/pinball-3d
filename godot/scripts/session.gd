class_name PinballSession
extends RefCounted

enum Phase { READY, PLAYING, PAUSED, GAME_OVER }

const MAX_MULTIPLIER := 5
const RUSH_DURATION := 20.0
const COMBO_DURATION := 3.0
const SAVE_DURATION := 8.0

var phase := Phase.READY
var score := 0
var best := 0
var balls := 3
var ball_active := false
var new_best := false
var message := "A little focus. A new high score."
var message_left := 0.0
var multiplier := 1
var lanes: Array[bool] = [false, false, false]
var targets: Array[bool] = [false, false, false]
var rush_left := 0.0
var combo_count := 0
var combo_left := 0.0
var combo_last_id := ""
var launched := false
var save_left := 0.0
var save_used := false
var saved_drain := false

func start() -> void:
	phase = Phase.PLAYING
	score = 0
	balls = 3
	ball_active = true
	new_best = false
	_reset_ball_rules()
	message = "Hold SPACE, then release to launch"
	message_left = 4.0

func award(points: int, title: String, shot_id: String = "") -> int:
	if phase != Phase.PLAYING or not ball_active or points <= 0:
		return 0

	var total := points * multiplier * (2 if rush_left > 0.0 else 1)
	var target_index := _shot_index(shot_id, "target") if title == "TARGET" else -1
	var lane_index := _shot_index(shot_id, "lane") if title == "ROLLOVER" else -1

	if target_index >= 0 or lane_index >= 0:
		total += _advance_combo(shot_id)

	if lane_index >= 0 and not lanes[lane_index]:
		lanes[lane_index] = true
		if _all_lit(lanes):
			total += 500
			multiplier = mini(MAX_MULTIPLIER, multiplier + 1)
			_clear_lanes()

	if target_index >= 0 and rush_left <= 0.0 and not targets[target_index]:
		targets[target_index] = true
		if _all_lit(targets):
			rush_left = RUSH_DURATION

	score += total
	message = "%s  +%d" % [title, total]
	message_left = 1.7
	return total

func tick(delta: float) -> void:
	if phase != Phase.PLAYING or not ball_active or delta <= 0.0:
		return

	message_left = maxf(0.0, message_left - delta)
	if message_left == 0.0:
		message = "Find your rhythm."

	if combo_count > 0:
		combo_left = maxf(0.0, combo_left - delta)
		if combo_left == 0.0:
			_clear_combo()

	if rush_left > 0.0:
		rush_left = maxf(0.0, rush_left - delta)
		if rush_left == 0.0:
			_clear_targets()

	if save_left > 0.0:
		save_left = maxf(0.0, save_left - delta)

func launch_ball() -> void:
	if phase != Phase.PLAYING or not ball_active or launched:
		return
	launched = true
	save_left = SAVE_DURATION

func drain() -> bool:
	if phase != Phase.PLAYING or not ball_active:
		return false
	ball_active = false
	_clear_combo()
	if save_left > 0.0 and not save_used:
		save_used = true
		save_left = 0.0
		saved_drain = true
		return true

	balls -= 1
	_reset_ball_rules()
	if balls == 0:
		phase = Phase.GAME_OVER
		new_best = score > best
		best = maxi(best, score)
	return true

func next_ball() -> void:
	if phase == Phase.PLAYING and balls > 0 and not ball_active:
		ball_active = true
		saved_drain = false

func pause() -> void:
	if phase == Phase.PLAYING:
		phase = Phase.PAUSED

func resume() -> void:
	if phase == Phase.PAUSED:
		phase = Phase.PLAYING

func _advance_combo(shot_id: String) -> int:
	if combo_count == 0 or combo_left <= 0.0:
		combo_count = 1
		combo_left = COMBO_DURATION
		combo_last_id = shot_id
		return 0

	if shot_id == combo_last_id:
		return 0

	combo_last_id = shot_id
	combo_left = COMBO_DURATION
	if combo_count >= MAX_MULTIPLIER:
		return 0

	combo_count += 1
	return 100 * (combo_count - 1)

func _shot_index(shot_id: String, prefix: String) -> int:
	for index in range(3):
		if shot_id == "%s:%d" % [prefix, index]:
			return index
	return -1

func _all_lit(items: Array[bool]) -> bool:
	for lit in items:
		if not lit:
			return false
	return true

func _clear_combo() -> void:
	combo_count = 0
	combo_left = 0.0
	combo_last_id = ""

func _clear_lanes() -> void:
	for index in range(3):
		lanes[index] = false

func _clear_targets() -> void:
	for index in range(3):
		targets[index] = false

func _reset_ball_rules() -> void:
	multiplier = 1
	_clear_lanes()
	_clear_targets()
	rush_left = 0.0
	_clear_combo()
	launched = false
	save_left = 0.0
	save_used = false
	saved_drain = false
