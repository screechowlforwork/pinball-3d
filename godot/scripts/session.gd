class_name PinballSession
extends RefCounted

enum Phase { READY, PLAYING, PAUSED, GAME_OVER }
var phase := Phase.READY
var score := 0
var best := 0
var balls := 3
var ball_active := false
var new_best := false
var message := "A little focus. A new high score."
var message_left := 0.0

func start() -> void:
	phase = Phase.PLAYING
	score = 0
	balls = 3
	ball_active = true
	new_best = false
	message = "Hold SPACE, then release to launch"
	message_left = 4.0

func award(points: int, title: String) -> void:
	if phase != Phase.PLAYING or not ball_active or points <= 0:
		return
	score += points
	message = "%s  +%d" % [title, points]
	message_left = 1.7

func tick(delta: float) -> void:
	if phase == Phase.PLAYING:
		message_left = maxf(0.0, message_left - delta)
		if message_left == 0.0:
			message = "Find your rhythm."

func drain() -> bool:
	if phase != Phase.PLAYING or not ball_active:
		return false
	ball_active = false
	balls -= 1
	if balls == 0:
		phase = Phase.GAME_OVER
		new_best = score > best
		best = maxi(best, score)
	return true

func next_ball() -> void:
	if phase == Phase.PLAYING and balls > 0 and not ball_active:
		ball_active = true

func pause() -> void:
	if phase == Phase.PLAYING:
		phase = Phase.PAUSED

func resume() -> void:
	if phase == Phase.PAUSED:
		phase = Phase.PLAYING
