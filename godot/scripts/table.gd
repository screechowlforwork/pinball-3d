extends Node3D

const Session = preload("res://scripts/session.gd")
const ToneBank = preload("res://scripts/tone_bank.gd")
const INK := Color("101b2d")
const MINT := Color("94ebcd")
const CORAL := Color("ffab91")
const WHITE := Color("edf4fc")
var game := Session.new()
var ball: RigidBody3D
var left_flipper: AnimatableBody3D
var right_flipper: AnimatableBody3D
var held := {"left": false, "right": false, "launch": false}
var sources := {"left": {}, "right": {}, "launch": {}}
var launch_pending := false
var charge := 0.0
var paused_velocity := Vector3.ZERO
var respawn_left := 0.0
var cooldowns: Dictionary = {}
var score_label: Label
var best_label: Label
var balls_label: Label
var toast_label: Label
var phase_label: Label
var charge_bar: ProgressBar
var overlay: PanelContainer
var overlay_title: Label
var overlay_text: Label
var primary_button: Button
var pause_button: Button
var sound_button: Button
var sound: AudioStreamPlayer
var muted := false
var tone_bank := ToneBank.new()
var impact_count := 0
var launch_count := 0
var drain_count := 0
var score_events: Dictionary = {}

func _ready() -> void:
	load_record()
	make_table()
	make_ui()
	sound = AudioStreamPlayer.new()
	add_child(sound)
	refresh_ui()

func material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.35
	return mat

func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func wall(a: Vector3, b: Vector3, width: float = 0.22, color: Color = MINT) -> StaticBody3D:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = (a + b) / 2.0
	body.rotation.y = -atan2(b.z - a.z, b.x - a.x)
	var size := Vector3(a.distance_to(b), 0.7, width)
	box(body, size, Vector3.ZERO, color)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.65
	mat.friction = 0.08
	body.physics_material_override = mat
	return body

func label_3d(text: String, pos: Vector3, size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.008
	label.modulate = color
	label.outline_size = 0
	label.rotation_degrees.x = -90
	add_child(label)
	label.position = pos

func make_table() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("0c1422")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b7cedc")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-65, -30, 0)
	light.light_energy = 1.5
	light.shadow_enabled = true
	add_child(light)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 23, 16)
	camera.look_at(Vector3(0, 0, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24.5
	camera.h_offset = 3.3
	camera.current = true
	box(self, Vector3(10.8, 0.7, 20.6), Vector3(0, -0.7, 0), Color("23394a"))
	box(self, Vector3(10, 0.15, 20), Vector3(0, -0.28, 0), Color("17303b"))
	for x in [-5.0, 5.0]:
		wall(Vector3(x, 0.3, -9.7), Vector3(x, 0.3, 10.0))
	wall(Vector3(-5, 0.3, -9.7), Vector3(3.1, 0.3, -9.7))
	wall(Vector3(3.1, 0.3, -9.7), Vector3(5, 0.3, -7.9))
	wall(Vector3(-5, 0.3, -8), Vector3(-3.5, 0.3, -9.7))
	wall(Vector3(3.75, 0.3, -6.5), Vector3(3.75, 0.3, 9.5), 0.18, Color("6b8792"))
	wall(Vector3(3.75, 0.3, 9.5), Vector3(5, 0.3, 9.5))
	wall(Vector3(-4.9, 0.3, 4.7), Vector3(-2.65, 0.3, 7.0))
	wall(Vector3(3.65, 0.3, 5.1), Vector3(2.25, 0.3, 7.0))
	for x in [-2.1, 0.0, 2.1]:
		make_sensor(Vector3(x, 0.3, -7.4), Vector3(1.4, 1, 0.6), 150, "ROLLOVER", Color("b4c8ff"))
		label_3d("150", Vector3(x, -0.15, -7.4), 34, WHITE)
	make_bumper(Vector3(-1.9, 0.3, -3.8), 0.68, 100, "BUMPER", CORAL)
	make_bumper(Vector3(1.35, 0.3, -3.3), 0.68, 100, "BUMPER", CORAL)
	make_bumper(Vector3(-0.3, 0.3, -0.9), 0.72, 100, "BUMPER", CORAL)
	make_bumper(Vector3(-3.05, 0.3, 4.0), 0.48, 50, "SLINGSHOT", MINT)
	make_bumper(Vector3(2.65, 0.3, 4.0), 0.48, 50, "SLINGSHOT", MINT)
	for z in [-4.5, -2.8, -1.1]:
		var target := wall(Vector3(-4.75, 0.3, z - 0.35), Vector3(-4.75, 0.3, z + 0.35), 0.35, Color("b4c8ff"))
		target.set_meta("points", 250)
		target.set_meta("title", "TARGET")
	label_3d("O R B I T", Vector3(-0.4, -0.15, 2.0), 76, MINT)
	label_3d("P I N B A L L   C L U B", Vector3(-0.4, -0.15, 2.8), 27, Color("a3b9c5"))
	label_3d("LAUNCH", Vector3(4.35, -0.15, 5.3), 20, MINT)
	label_3d("01", Vector3(-0.5, -0.15, -5.8), 42, WHITE)
	left_flipper = make_flipper(Vector3(-2.65, 0.3, 7), 1)
	right_flipper = make_flipper(Vector3(2.25, 0.3, 7), -1)
	ball = RigidBody3D.new()
	ball.name = "Ball"
	ball.mass = 1.0
	ball.continuous_cd = true
	ball.axis_lock_linear_y = true
	ball.lock_rotation = true
	ball.linear_damp = 0.07
	ball.contact_monitor = true
	ball.max_contacts_reported = 8
	var physics_mat := PhysicsMaterial.new()
	physics_mat.bounce = 0.55
	physics_mat.friction = 0.05
	ball.physics_material_override = physics_mat
	var sphere := SphereMesh.new()
	sphere.radius = 0.27
	sphere.height = 0.54
	var mesh := MeshInstance3D.new()
	mesh.mesh = sphere
	mesh.material_override = material(Color("f2f7ff"), 0.75)
	ball.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.27
	collision.shape = shape
	ball.add_child(collision)
	add_child(ball)
	ball.body_entered.connect(on_collision)
	ball.freeze = true
	ball.position = Vector3(4.35, 0.3, 8.4)

func make_flipper(pos: Vector3, direction: int) -> AnimatableBody3D:
	var body := AnimatableBody3D.new()
	body.position = pos
	body.set_meta("flipper", direction)
	body.rotation.y = -direction * 0.42
	add_child(body)
	box(body, Vector3(1.95, 0.45, 0.42), Vector3(direction * 0.82, 0, 0), CORAL)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.95, 0.45, 0.42)
	collision.shape = shape
	collision.position.x = direction * 0.82
	body.add_child(collision)
	return body

func make_bumper(pos: Vector3, radius: float, points: int, title: String, color: Color) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = pos
	body.set_meta("points", points)
	body.set_meta("title", title)
	body.set_meta("kick", true)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.7
	var mesh := MeshInstance3D.new()
	mesh.mesh = cylinder
	mesh.material_override = material(color, 0.2)
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 0.7
	collision.shape = shape
	body.add_child(collision)
	label_3d(str(points), pos + Vector3(0, 0.37, 0), 42, INK)

func make_sensor(pos: Vector3, size: Vector3, points: int, title: String, color: Color) -> void:
	var area := Area3D.new()
	add_child(area)
	area.position = pos
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	box(area, Vector3(size.x, 0.04, size.z), Vector3(0, -0.5, 0), color)
	area.body_entered.connect(func(body: Node3D):
		if body == ball:
			award_contact(area, points, title))

func award_contact(body: Node, points: int, title: String) -> void:
	if game.phase != Session.Phase.PLAYING or not game.ball_active:
		return
	var id := body.get_instance_id()
	if cooldowns.has(id):
		return
	cooldowns[id] = 0.18
	game.award(points, title)
	score_events[title] = int(score_events.get(title, 0)) + 1
	beep(480 + points, 0.06)

func on_collision(body: Node) -> void:
	if game.phase != Session.Phase.PLAYING:
		return
	if body.has_meta("points"):
		award_contact(body, body.get_meta("points"), body.get_meta("title"))
		if body.has_meta("kick"):
			var direction: Vector3 = (ball.position - body.position).normalized()
			direction.y = 0
			ball.apply_central_impulse(direction * 6.0)
	if body.has_meta("flipper"):
		var side: String = "left" if body.get_meta("flipper") == 1 else "right"
		if held[side] and not cooldowns.has(side):
			cooldowns[side] = 0.1
			ball.apply_central_impulse(Vector3(body.get_meta("flipper") * 2.5, 0, -12))
			impact_count += 1
			beep(330, 0.045)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		if event.keycode == KEY_ESCAPE and event.pressed:
			toggle_pause()
		var action := ""
		if event.keycode in [KEY_LEFT, KEY_Z]: action = "left"
		if event.keycode in [KEY_RIGHT, KEY_M]: action = "right"
		if event.keycode == KEY_SPACE: action = "launch"
		if action != "": set_control(action, str(event.keycode), event.pressed)

func set_control(action: String, source: String, pressed: bool) -> void:
	if game.phase != Session.Phase.PLAYING:
		return
	var was: bool = held[action]
	if pressed: sources[action][source] = true
	else: sources[action].erase(source)
	held[action] = not sources[action].is_empty()
	if action == "launch" and was and not held[action]: launch_pending = true

func clear_controls() -> void:
	for action in held:
		held[action] = false
		sources[action].clear()
	launch_pending = false
	charge = 0
	left_flipper.rotation.y = -0.42
	right_flipper.rotation.y = 0.42

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(ball):
		if game.phase == Session.Phase.PLAYING: toggle_pause()

func toggle_pause() -> void:
	if game.phase == Session.Phase.PLAYING:
		game.pause()
		paused_velocity = ball.linear_velocity
		ball.freeze = true
		clear_controls()
	elif game.phase == Session.Phase.PAUSED:
		game.resume()
		ball.freeze = not game.ball_active
		ball.linear_velocity = paused_velocity
	refresh_ui()

func start_game() -> void:
	clear_controls()
	cooldowns.clear()
	respawn_left = 0
	paused_velocity = Vector3.ZERO
	impact_count = 0
	launch_count = 0
	drain_count = 0
	score_events.clear()
	game.start()
	reset_ball()
	refresh_ui()

func reset_ball() -> void:
	clear_controls()
	ball.freeze = true
	ball.position = Vector3(4.35, 0.3, 8.4)
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.reset_physics_interpolation()
	ball.freeze = false

func in_shooter_lane() -> bool:
	return game.ball_active and ball.position.x > 4.02 and ball.position.z > 6.2 and absf(ball.linear_velocity.z) < 4

func _physics_process(delta: float) -> void:
	if game.phase != Session.Phase.PLAYING:
		return
	game.tick(delta)
	for key in cooldowns.keys():
		cooldowns[key] -= delta
		if cooldowns[key] <= 0: cooldowns.erase(key)
	left_flipper.rotation.y = move_toward(left_flipper.rotation.y, 0.5 if held.left else -0.42, delta * 18)
	right_flipper.rotation.y = move_toward(right_flipper.rotation.y, -0.5 if held.right else 0.42, delta * 18)
	if not game.ball_active:
		respawn_left -= delta
		if respawn_left <= 0:
			game.next_ball()
			reset_ball()
		return
	ball.apply_central_force(Vector3(0, 0, 5.0))
	if ball.linear_velocity.length() > 27:
		ball.linear_velocity = ball.linear_velocity.normalized() * 27
	if in_shooter_lane():
		if held.launch: charge = minf(1, charge + delta * 0.9)
		if launch_pending:
			ball.linear_velocity = Vector3(0, 0, -(19 + charge * 7))
			launch_count += 1
			beep(220, 0.12)
	else:
		charge = 0
	if launch_pending:
		launch_pending = false
		charge = 0
	if ball.position.z > 10.2 or absf(ball.position.x) > 6:
		if game.drain():
			drain_count += 1
			ball.freeze = true
			clear_controls()
			cooldowns.clear()
			respawn_left = 0.8
			beep(120, 0.2)
			if game.phase == Session.Phase.GAME_OVER: save_record()

func _process(_delta: float) -> void:
	refresh_ui()

func style(color: Color, radius: int = 18) -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = color
	panel.set_corner_radius_all(radius)
	panel.content_margin_left = 22
	panel.content_margin_right = 22
	panel.content_margin_top = 18
	panel.content_margin_bottom = 18
	return panel

func text_label(parent: Node, text: String, size: int, color: Color = WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func button(parent: Node, text: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 48
	result.focus_mode = Control.FOCUS_NONE
	result.add_theme_stylebox_override("normal", style(MINT, 12))
	result.add_theme_stylebox_override("hover", style(Color("baffdf"), 12))
	result.add_theme_stylebox_override("pressed", style(Color("62c9a9"), 12))
	result.add_theme_color_override("font_color", INK)
	result.add_theme_color_override("font_hover_color", INK)
	result.add_theme_color_override("font_pressed_color", INK)
	result.add_theme_font_size_override("font_size", 17)
	parent.add_child(result)
	if callback.is_valid(): result.pressed.connect(callback)
	return result

func make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var heading := VBoxContainer.new()
	root.add_child(heading)
	heading.position = Vector2(34, 24)
	text_label(heading, "ORBIT / PINBALL CLUB", 20, MINT)
	text_label(heading, "A moment of play.", 14, Color("a4b5c9"))
	var sidebar := PanelContainer.new()
	root.add_child(sidebar)
	sidebar.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	sidebar.offset_left = -320
	sidebar.offset_right = -24
	sidebar.offset_top = 24
	sidebar.offset_bottom = -24
	sidebar.add_theme_stylebox_override("panel", style(INK, 24))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	sidebar.add_child(column)
	text_label(column, "TABLE 01  /  ORBIT", 14, MINT)
	text_label(column, "Make it count.", 28)
	text_label(column, "SCORE", 13, Color("a4b5c9"))
	score_label = text_label(column, "000000", 48)
	best_label = text_label(column, "BEST  0", 17, MINT)
	balls_label = text_label(column, "● ● ●   3 balls", 20)
	var line := HSeparator.new()
	column.add_child(line)
	phase_label = text_label(column, "READY TO PLAY", 14, CORAL)
	toast_label = text_label(column, "", 17)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.custom_minimum_size.y = 62
	charge_bar = ProgressBar.new()
	charge_bar.max_value = 1
	charge_bar.show_percentage = false
	charge_bar.custom_minimum_size.y = 8
	var fill := style(MINT, 4)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	charge_bar.add_theme_stylebox_override("fill", fill)
	column.add_child(charge_bar)
	text_label(column, "HOLD SPACE · RELEASE TO LAUNCH", 11, Color("a4b5c9"))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	text_label(column, "HOW TO PLAY", 13, MINT)
	text_label(column, "← / Z     Left flipper\n→ / M    Right flipper\nSpace    Charge & launch\nEsc         Pause", 16, Color("bdccda"))
	pause_button = button(column, "Pause", toggle_pause)
	sound_button = button(column, "Sound off" if muted else "Sound on", func(): set_muted(not muted))
	var controls := HBoxContainer.new()
	root.add_child(controls)
	controls.position = Vector2(40, 724)
	controls.add_theme_constant_override("separation", 12)
	for entry in [["left", "← Left"], ["launch", "Hold to launch"], ["right", "Right →"]]:
		var action: String = entry[0]
		var control := button(controls, entry[1], Callable())
		control.button_down.connect(func(): set_control(action, "mouse", true))
		control.button_up.connect(func(): set_control(action, "mouse", false))
		control.mouse_exited.connect(func(): set_control(action, "mouse", false))
	overlay = PanelContainer.new()
	root.add_child(overlay)
	overlay.position = Vector2(145, 285)
	overlay.custom_minimum_size = Vector2(470, 230)
	overlay.add_theme_stylebox_override("panel", style(Color(0.07, 0.12, 0.18, 0.97), 24))
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 16)
	overlay.add_child(card)
	overlay_title = text_label(card, "Welcome to Orbit.", 36)
	overlay_text = text_label(card, "Three balls. One more try.\nA small escape, made for your Mac.", 18, Color("bdccda"))
	primary_button = button(card, "Let's play", func():
		if game.phase == Session.Phase.PAUSED: toggle_pause()
		else: start_game())

func refresh_ui() -> void:
	if not is_instance_valid(score_label): return
	score_label.text = "%06d" % game.score
	best_label.text = "BEST  %06d" % game.best
	balls_label.text = "%s   %d balls" % ["● ".repeat(game.balls), game.balls]
	toast_label.text = game.message
	charge_bar.value = charge
	phase_label.text = "CHARGE TO LAUNCH" if in_shooter_lane() else "IN PLAY"
	pause_button.disabled = game.phase in [Session.Phase.READY, Session.Phase.GAME_OVER]
	pause_button.text = "Resume" if game.phase == Session.Phase.PAUSED else "Pause"
	overlay.visible = game.phase != Session.Phase.PLAYING
	match game.phase:
		Session.Phase.READY:
			phase_label.text = "READY TO PLAY"
		Session.Phase.PAUSED:
			phase_label.text = "PAUSED"
			overlay_title.text = "Take a breath."
			overlay_text.text = "Your table will be right here.\nControls released. Ball safely paused."
			primary_button.text = "Back to play"
		Session.Phase.GAME_OVER:
			phase_label.text = "SESSION COMPLETE"
			overlay_title.text = "A new best." if game.new_best else "One more orbit?"
			overlay_text.text = "Final score  %06d\nThree balls. A fresh start awaits." % game.score
			primary_button.text = "Play again"

func beep(frequency: float, duration: float) -> void:
	if muted or not is_instance_valid(sound): return
	sound.stream = tone_bank.get_tone(frequency, duration)
	sound.play()

func set_muted(value: bool) -> void:
	muted = value
	sound_button.text = "Sound off" if muted else "Sound on"
	if muted: sound.stop()
	save_record()

func load_record() -> void:
	var config := ConfigFile.new()
	if config.load("user://record.cfg") == OK:
		game.best = maxi(0, int(config.get_value("orbit", "best", 0)))
		muted = bool(config.get_value("orbit", "muted", false))

func save_record() -> void:
	var config := ConfigFile.new()
	config.set_value("orbit", "best", game.best)
	config.set_value("orbit", "muted", muted)
	var error := config.save("user://record.cfg")
	if error != OK: push_warning("Best score could not be saved: %s" % error)
