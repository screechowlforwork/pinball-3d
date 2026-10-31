extends SceneTree

# A frozen, injected rules/effects preview. Not real-input gameplay evidence.
func _initialize() -> void:
	call_deferred("preview")

func preview() -> void:
	var table = load("res://main.tscn").instantiate()
	root.add_child(table)
	table.start_game()
	table.set_physics_process(false)
	table.ball.freeze = true
	table.set_muted(true)
	table.set_reduced_effects(false)
	table.game.launch_ball()
	for i in 3: table.game.award(150, "ROLLOVER", "lane:%d" % i)
	for i in 3: table.game.award(250, "TARGET", "target:%d" % i)
	table.game.award(150, "ROLLOVER", "lane:0")
	table.ball.position = Vector3(-2.8, 0.3, -3.8)
	for child in table.get_children():
		if child.get_meta("title", "") == "BUMPER":
			table.award_contact(child, 100, "BUMPER")
			break
	for i in 4:
		table.effects.tick(0.035, table.ball.position + Vector3(-0.18 * (3 - i), 0, 0.16 * (3 - i)), true)
	table.game.tick(0.14)
	table.refresh_ui()
	var layer := CanvasLayer.new()
	layer.layer = 10
	root.add_child(layer)
	var label := Label.new()
	label.text = "CONTROLLED PREVIEW · injected rules / frozen effects · not real play"
	label.position = Vector2(34, 90)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", table.CORAL)
	layer.add_child(label)
