extends SceneTree

const ToneBank = preload("res://scripts/tone_bank.gd")
var failures := 0

func check(condition: bool, title: String) -> void:
	print("%s: %s" % ["PASS" if condition else "FAIL", title])
	if not condition: failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var bank := ToneBank.new()
	check(bank.cache.size() == 7, "All gameplay tones prewarmed")
	for tone in bank.TONES:
		var wave: AudioStreamWAV = bank.get_tone(tone.x, tone.y)
		check(wave == bank.get_tone(tone.x, tone.y), "Repeated tone reuses the same WAV resource")
		var pcm := wave.data
		var peak := 0
		for i in range(0, pcm.size(), 2): peak = maxi(peak, absi(pcm.decode_s16(i)))
		check(pcm.size() == roundi(tone.y * 22050) * 2 and peak > 0 and peak <= 4000, "PCM duration, non-silence and amplitude bound")
		check(pcm.decode_s16(0) == 0 and absi(pcm.decode_s16(pcm.size() - 2)) <= 1, "Tone has silent endpoints")
	var table = load("res://main.tscn").instantiate()
	root.add_child(table)
	table.set_muted(false)
	table.beep(220, 0.12)
	check(table.sound.playing, "Unmuted sound starts playback")
	var stream: AudioStream = table.sound.stream
	table.set_muted(true)
	check(not table.sound.playing and table.sound_button.text == "Sound off", "Mute immediately stops playback and updates UI")
	table.beep(330, 0.045)
	check(not table.sound.playing and table.sound.stream == stream, "Muted events cannot start or replace playback")
	var record := ConfigFile.new()
	check(record.load("user://record.cfg") == OK and record.get_value("orbit", "muted") == true, "Mute preference saved")
	table.muted = false
	table.load_record()
	check(table.muted, "Mute preference reloads")
	table.start_game()
	check(table.muted, "Restart preserves mute")
	table.set_muted(false)
	table.beep(330, 0.045)
	check(table.sound.playing, "Unmute permits new playback")
	print("AUDIO STATE/PCM TESTS (not audible output): %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(failures)
