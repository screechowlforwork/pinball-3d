extends RefCounted

const TONES := [Vector2(530, 0.06), Vector2(580, 0.06), Vector2(630, 0.06),
	Vector2(730, 0.06), Vector2(330, 0.045), Vector2(220, 0.12), Vector2(120, 0.2)]
var cache: Dictionary = {}

func _init() -> void:
	for tone in TONES: get_tone(tone.x, tone.y)

func get_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var key := Vector2(frequency, duration)
	if cache.has(key): return cache[key]
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var count := roundi(duration * wave.mix_rate)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var attack := minf(1.0, float(i) / (0.005 * wave.mix_rate))
		var envelope := attack * pow(1.0 - float(i) / count, 2)
		data.encode_s16(i * 2, int(sin(TAU * frequency * i / wave.mix_rate) * envelope * 4000))
	wave.data = data
	cache[key] = wave
	return wave
