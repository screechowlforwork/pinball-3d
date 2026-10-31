extends Node3D

const MAX_BURSTS := 12
const MAX_TRAIL := 8
const BURST_SECONDS := 0.65
var reduced := false
var bursts: Array[Dictionary] = []
var trail: Array[Dictionary] = []
var pulses: Array[Dictionary] = []
var trail_clock := 0.0

func ink(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	return mat

func ring(radius: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.025
	torus.outer_radius = radius + 0.025
	torus.rings = 24
	torus.ring_segments = 6
	mesh.mesh = torus
	mesh.material_override = ink(color)
	return mesh

func hit(pos: Vector3, points: int, accent: Color, bumper: MeshInstance3D = null) -> void:
	if reduced: return
	if bursts.size() >= MAX_BURSTS:
		bursts.pop_front().node.free()
	var group := Node3D.new()
	add_child(group)
	group.position = Vector3(pos.x, 0.12, pos.z)
	var halo := ring(0.35, accent)
	group.add_child(halo)
	var label := Label3D.new()
	label.text = "+%d" % points
	label.font_size = 44
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = accent
	label.outline_size = 4
	label.outline_modulate = Color("101b2d")
	label.position = Vector3(0, 0.7, 0)
	group.add_child(label)
	bursts.append({"node": group, "ring": halo, "label": label, "left": BURST_SECONDS})
	if is_instance_valid(bumper):
		var mat := bumper.material_override as StandardMaterial3D
		for pulse in pulses:
			if pulse.mat == mat:
				pulse.left = 0.25
				return
		mat.emission_enabled = true
		mat.emission = accent
		pulses.append({"mat": mat, "left": 0.25})

func tick(delta: float, ball_pos: Vector3, moving: bool) -> void:
	if reduced: return
	for i in range(bursts.size() - 1, -1, -1):
		var burst := bursts[i]
		burst.left -= delta
		if burst.left <= 0:
			burst.node.free()
			bursts.remove_at(i)
			continue
		var fraction: float = burst.left / BURST_SECONDS
		burst.ring.scale = Vector3.ONE * (1.0 + (1.0 - fraction) * 1.4)
		burst.ring.material_override.albedo_color.a = fraction * 0.65
		burst.label.modulate.a = fraction
		burst.label.position.y = 0.7 + (1.0 - fraction) * 0.65
	for i in range(pulses.size() - 1, -1, -1):
		var pulse := pulses[i]
		pulse.left = maxf(0, pulse.left - delta)
		pulse.mat.emission_energy_multiplier = pulse.left * 1.6
		if pulse.left == 0:
			pulse.mat.emission_enabled = false
			pulses.remove_at(i)
	for i in range(trail.size() - 1, -1, -1):
		var dot := trail[i]
		dot.left -= delta
		if dot.left <= 0:
			dot.node.free()
			trail.remove_at(i)
		else:
			dot.node.material_override.albedo_color.a = dot.left * 1.8
	trail_clock += delta
	if moving and trail_clock >= 0.035:
		trail_clock = 0
		if trail.size() >= MAX_TRAIL: trail.pop_front().node.free()
		var dot := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.09
		sphere.height = 0.18
		dot.mesh = sphere
		dot.material_override = ink(Color("94ebcd"))
		add_child(dot)
		dot.position = ball_pos
		trail.append({"node": dot, "left": 0.2})

func clear() -> void:
	for burst in bursts: burst.node.free()
	for dot in trail: dot.node.free()
	for pulse in pulses:
		pulse.mat.emission_enabled = false
		pulse.mat.emission_energy_multiplier = 0
	bursts.clear()
	trail.clear()
	pulses.clear()
	trail_clock = 0

func set_reduced(value: bool) -> void:
	reduced = value
	clear()
