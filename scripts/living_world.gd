extends Node3D

# Prototype milestone: generated landscape, 100 founders, and time controls.
# Needs, ecology, genealogy, and survival rules will be added as separate systems.
const FOUNDER_COUNT := 100
const WORLD_SIZE := 180.0

var world_seed: int
var elapsed_days := 0.0
var time_speed := 1.0
var paused := false
var founders: Array[Node3D] = []
var home_positions: Array[Vector3] = []
var status_label: Label
var seed_label: Label
var pause_button: Button
var speed_button: Button

func _ready() -> void:
	world_seed = int(Time.get_unix_time_from_system()) % 2147483647
	seed(world_seed)
	_build_environment()
	_build_landscape()
	_build_founders()
	_build_interface()
	_update_interface()

func _process(delta: float) -> void:
	if not paused:
		elapsed_days += delta * time_speed
		_simulate_founders(delta * time_speed)
	_update_interface()

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.69, 0.78)
	environment.ambient_light_energy = 0.75
	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48.0, -25.0, 0.0)
	sunlight.light_energy = 1.2
	add_child(sunlight)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 95.0, 115.0)
	camera.rotation_degrees = Vector3(-38.0, 0.0, 0.0)
	camera.current = true
	camera.fov = 52.0
	add_child(camera)

func _build_landscape() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(WORLD_SIZE, WORLD_SIZE)
	plane.subdivide_width = 40
	plane.subdivide_depth = 40
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.32, 0.49, 0.32)
	ground_material.roughness = 1.0
	ground.material_override = ground_material
	ground.position.y = -0.2
	add_child(ground)

	# Seed-driven natural-looking patches; this is a visual placeholder, not yet
	# a full terrain, hydrology, geology, or climate simulation.
	var patches := Node3D.new()
	patches.name = "LandscapePatches"
	add_child(patches)
	for i in range(110):
		var patch := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		var radius := randf_range(2.0, 8.0)
		mesh.top_radius = radius
		mesh.bottom_radius = radius * randf_range(0.8, 1.2)
		mesh.height = 0.08
		patch.mesh = mesh
		var material := StandardMaterial3D.new()
		var roll := randf()
		if roll < 0.15:
			material.albedo_color = Color(0.68, 0.62, 0.40)
		elif roll < 0.28:
			material.albedo_color = Color(0.24, 0.39, 0.27)
		else:
			material.albedo_color = Color(0.38, 0.56, 0.35)
		material.roughness = 1.0
		patch.material_override = material
		patch.position = Vector3(
			randf_range(-WORLD_SIZE * 0.48, WORLD_SIZE * 0.48),
			-0.1,
			randf_range(-WORLD_SIZE * 0.48, WORLD_SIZE * 0.48)
		)
		patches.add_child(patch)

func _build_founders() -> void:
	var people_root := Node3D.new()
	people_root.name = "Founders"
	add_child(people_root)
	for i in range(FOUNDER_COUNT):
		var person := Node3D.new()
		person.name = "Founder_%03d" % (i + 1)

		var body := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.42
		capsule.height = 1.7
		body.mesh = capsule
		var material := StandardMaterial3D.new()
		material.albedo_color = Color.from_hsv(
			randf_range(0.04, 0.12),
			randf_range(0.25, 0.65),
			randf_range(0.45, 0.85)
		)
		material.roughness = 0.9
		body.material_override = material
		body.position.y = 0.85
		person.add_child(body)

		var home := Vector3(
			randf_range(-35.0, 35.0),
			0.0,
			randf_range(-35.0, 35.0)
		)
		person.position = home
		people_root.add_child(person)
		founders.append(person)
		home_positions.append(home)

func _simulate_founders(delta: float) -> void:
	# Early visual placeholder: small local movement only. These agents do not
	# yet have survival needs, memory, relationships, or individual decision AI.
	for i in range(founders.size()):
		var home := home_positions[i]
		var offset := Vector3(
			sin(elapsed_days * 0.12 + i * 1.7),
			0.0,
			cos(elapsed_days * 0.10 + i * 2.1)
		) * 2.0
		founders[i].position = founders[i].position.lerp(
			home + offset,
			clampf(delta * 0.18, 0.0, 1.0)
		)

func _build_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(320, 150)
	layer.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	panel.add_child(layout)

	var heading := Label.new()
	heading.text = "LIVING WORLD"
	heading.add_theme_font_size_override("font_size", 23)
	layout.add_child(heading)

	status_label = Label.new()
	layout.add_child(status_label)
	seed_label = Label.new()
	layout.add_child(seed_label)

	var controls := HBoxContainer.new()
	layout.add_child(controls)
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.pressed.connect(_toggle_pause)
	controls.add_child(pause_button)
	speed_button = Button.new()
	speed_button.text = "Time x1"
	speed_button.pressed.connect(_cycle_speed)
	controls.add_child(speed_button)

	var note := Label.new()
	note.text = "Pure Observation  •  100 founders"
	note.add_theme_font_size_override("font_size", 12)
	layout.add_child(note)

func _toggle_pause() -> void:
	paused = not paused
	_update_interface()

func _cycle_speed() -> void:
	if is_equal_approx(time_speed, 1.0):
		time_speed = 3.0
	elif is_equal_approx(time_speed, 3.0):
		time_speed = 10.0
	else:
		time_speed = 1.0
	_update_interface()

func _update_interface() -> void:
	if status_label == null:
		return
	status_label.text = "Day %d  •  Founders: %d" % [int(elapsed_days), founders.size()]
	seed_label.text = "World seed: %d" % world_seed
	if pause_button != null:
		pause_button.text = "Resume" if paused else "Pause"
	if speed_button != null:
		speed_button.text = "Time x%d" % int(time_speed)
