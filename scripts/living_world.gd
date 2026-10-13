extends Node3D

# Living World — playable foundation.
# This is a deliberately small, testable simulation slice, not the finished game.
# Core rules: 100 original founders, Pure Observation, no unrelated human spawns,
# no artificial wildlife respawns, and actions constrained by available resources.

const FOUNDER_COUNT := 100
const WORLD_SIZE := 180.0
const GRID_SIZE := 65
const FOOD_COUNT := 95
const TREE_COUNT := 150
const WATER_LEVEL := -1.35
const DAY_SECONDS := 1.0

var world_seed: int
var rng := RandomNumberGenerator.new()
var terrain_noise := FastNoiseLite.new()
var elapsed_days := 0
var day_accumulator := 0.0
var time_speed := 1.0
var paused := false
var founders: Array[Node3D] = []
var people: Array[Dictionary] = []
var food_sources: Array[Dictionary] = []
var water_sources: Array[Vector3] = []
var selected_index := 0

var status_label: Label
var seed_label: Label
var detail_label: Label
var pause_button: Button
var speed_button: Button
var people_button: Button
var world_material: StandardMaterial3D
var camera: Camera3D
var touch_positions: Dictionary = {}
var previous_pinch_distance := 0.0
var ui_notice := ""
var world_root: Node3D

func _ready() -> void:
	world_seed = int(Time.get_unix_time_from_system()) % 2147483647
	_configure_seed(world_seed)
	_build_environment()
	_build_world_content()
	_build_interface()
	_update_interface()

func _configure_seed(seed_value: int) -> void:
	world_seed = seed_value
	rng.seed = world_seed
	terrain_noise.seed = world_seed
	terrain_noise.frequency = 0.035
	terrain_noise.fractal_octaves = 4
	terrain_noise.fractal_gain = 0.48
	terrain_noise.fractal_lacunarity = 2.0

func _build_world_content() -> void:
	if is_instance_valid(world_root):
		remove_child(world_root)
		world_root.queue_free()
	founders.clear()
	people.clear()
	food_sources.clear()
	water_sources.clear()
	selected_index = 0
	world_root = Node3D.new()
	world_root.name = "GeneratedWorld"
	add_child(world_root)
	_build_landscape()
	_build_water()
	_build_resources()
	_build_founders()

func _process(delta: float) -> void:
	if not paused:
		var sim_delta := delta * time_speed
		day_accumulator += sim_delta / DAY_SECONDS
		while day_accumulator >= 1.0:
			day_accumulator -= 1.0
			_advance_day()
		_move_people(sim_delta)
	_update_interface()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			touch_positions[touch.index] = touch.position
			if touch_positions.size() == 2:
				var points: Array = touch_positions.values()
				previous_pinch_distance = points[0].distance_to(points[1])
		else:
			touch_positions.erase(touch.index)
			if touch_positions.size() < 2:
				previous_pinch_distance = 0.0
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if touch_positions.has(drag.index):
			touch_positions[drag.index] = drag.position
			if touch_positions.size() >= 2:
				var points: Array = touch_positions.values()
				var pinch_distance: float = points[0].distance_to(points[1])
				if previous_pinch_distance > 0.0:
					camera.position.y = clampf(camera.position.y + (previous_pinch_distance - pinch_distance) * 0.12, 28.0, 135.0)
				previous_pinch_distance = pinch_distance
			else:
				camera.position.x = clampf(camera.position.x - drag.relative.x * 0.16, -WORLD_SIZE * 0.5, WORLD_SIZE * 0.5)
				camera.position.z = clampf(camera.position.z + drag.relative.y * 0.16, -WORLD_SIZE * 0.5, WORLD_SIZE * 0.5)
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.y = maxf(28.0, camera.position.y - 7.0)
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.y = minf(135.0, camera.position.y + 7.0)

func _height_at(x: float, z: float) -> float:
	var broad := terrain_noise.get_noise_2d(x, z) * 5.8
	var detail := terrain_noise.get_noise_2d(x * 2.7 + 91.0, z * 2.7 - 43.0) * 1.15
	# The broad valley near the middle creates a lowland that can hold water.
	var basin := maxf(0.0, 1.0 - Vector2(x, z).length() / 75.0) * -1.7
	return broad + detail + basin

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.70, 0.80)
	environment.ambient_light_energy = 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48.0, -25.0, 0.0)
	sunlight.light_energy = 1.15
	sunlight.shadow_enabled = true
	add_child(sunlight)

	camera = Camera3D.new()
	camera.position = Vector3(0.0, 82.0, 92.0)
	camera.rotation_degrees = Vector3(-42.0, 0.0, 0.0)
	camera.current = true
	camera.fov = 52.0
	add_child(camera)

func _build_landscape() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step_size := WORLD_SIZE / float(GRID_SIZE - 1)
	for z in range(GRID_SIZE - 1):
		for x in range(GRID_SIZE - 1):
			var x0 := -WORLD_SIZE * 0.5 + float(x) * step_size
			var x1 := x0 + step_size
			var z0 := -WORLD_SIZE * 0.5 + float(z) * step_size
			var z1 := z0 + step_size
			var a := Vector3(x0, _height_at(x0, z0), z0)
			var b := Vector3(x1, _height_at(x1, z0), z0)
			var c := Vector3(x0, _height_at(x0, z1), z1)
			var d := Vector3(x1, _height_at(x1, z1), z1)
			_add_terrain_vertex(surface, a)
			_add_terrain_vertex(surface, c)
			_add_terrain_vertex(surface, b)
			_add_terrain_vertex(surface, b)
			_add_terrain_vertex(surface, c)
			_add_terrain_vertex(surface, d)
	surface.generate_normals()
	var terrain := MeshInstance3D.new()
	terrain.name = "ProceduralTerrain"
	terrain.mesh = surface.commit()
	var terrain_material := StandardMaterial3D.new()
	terrain_material.vertex_color_use_as_albedo = true
	terrain_material.roughness = 1.0
	terrain.material_override = terrain_material
	world_root.add_child(terrain)

func _add_terrain_vertex(surface: SurfaceTool, point: Vector3) -> void:
	surface.set_color(_terrain_color(point.y))
	surface.add_vertex(point)

func _terrain_color(height: float) -> Color:
	if height < WATER_LEVEL + 0.8:
		return Color(0.48, 0.48, 0.35)
	if height < WATER_LEVEL + 1.8:
		return Color(0.62, 0.59, 0.40)
	if height > 5.0:
		return Color(0.49, 0.51, 0.45)
	if height > 2.7:
		return Color(0.35, 0.43, 0.30)
	return Color(0.31, 0.48, 0.30)

func _build_water() -> void:
	# A visible central lake is a starting water source, not a full hydrology model.
	var lake := MeshInstance3D.new()
	lake.name = "Lake"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 17.0
	mesh.bottom_radius = 17.0
	mesh.height = 0.12
	lake.mesh = mesh
	lake.position = Vector3(-10.0, WATER_LEVEL, -7.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.36, 0.48, 0.88)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.22
	material.metallic = 0.05
	lake.material_override = material
	world_root.add_child(lake)
	water_sources.append(lake.position)

func _build_resources() -> void:
	var trees_root := Node3D.new()
	trees_root.name = "Vegetation"
	world_root.add_child(trees_root)
	for i in range(TREE_COUNT):
		var x := rng.randf_range(-WORLD_SIZE * 0.46, WORLD_SIZE * 0.46)
		var z := rng.randf_range(-WORLD_SIZE * 0.46, WORLD_SIZE * 0.46)
		if Vector2(x + 10.0, z + 7.0).length() < 21.0:
			continue
		var y := _height_at(x, z)
		if y < WATER_LEVEL + 0.25:
			continue
		var tree := Node3D.new()
		tree.position = Vector3(x, y, z)
		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.16
		trunk_mesh.bottom_radius = 0.25
		trunk_mesh.height = rng.randf_range(1.4, 2.4)
		trunk.mesh = trunk_mesh
		trunk.position.y = trunk_mesh.height * 0.5
		var trunk_mat := StandardMaterial3D.new()
		trunk_mat.albedo_color = Color(0.30, 0.20, 0.12)
		trunk.material_override = trunk_mat
		tree.add_child(trunk)
		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		var crown_scale := rng.randf_range(0.8, 1.45)
		crown_mesh.radius = crown_scale
		crown_mesh.height = crown_scale * 2.0
		crown.mesh = crown_mesh
		crown.position.y = trunk_mesh.height + crown_scale * 0.55
		var crown_mat := StandardMaterial3D.new()
		crown_mat.albedo_color = Color(0.13 + rng.randf() * 0.08, 0.30 + rng.randf() * 0.12, 0.15)
		crown_mat.roughness = 1.0
		crown.material_override = crown_mat
		tree.add_child(crown)
		trees_root.add_child(tree)

	var food_root := Node3D.new()
	food_root.name = "WildFood"
	world_root.add_child(food_root)
	for i in range(FOOD_COUNT):
		var x := rng.randf_range(-WORLD_SIZE * 0.45, WORLD_SIZE * 0.45)
		var z := rng.randf_range(-WORLD_SIZE * 0.45, WORLD_SIZE * 0.45)
		var y := _height_at(x, z)
		if y < WATER_LEVEL + 0.25 or Vector2(x + 10.0, z + 7.0).length() < 20.0:
			continue
		var bush := MeshInstance3D.new()
		var bush_mesh := SphereMesh.new()
		bush_mesh.radius = 0.65
		bush_mesh.height = 1.1
		bush.mesh = bush_mesh
		bush.position = Vector3(x, y + 0.45, z)
		var bush_mat := StandardMaterial3D.new()
		bush_mat.albedo_color = Color(0.18, 0.39, 0.17)
		bush_mat.roughness = 1.0
		bush.material_override = bush_mat
		food_root.add_child(bush)
		var capacity := rng.randi_range(5, 9)
		food_sources.append({"position": Vector3(x, y, z), "food": capacity, "capacity": capacity, "node": bush})

func _build_founders() -> void:
	var people_root := Node3D.new()
	people_root.name = "Founders"
	world_root.add_child(people_root)
	for i in range(FOUNDER_COUNT):
		var person := Node3D.new()
		person.name = "Founder_%03d" % (i + 1)
		var body := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.34
		capsule.height = 1.55
		body.mesh = capsule
		var material := StandardMaterial3D.new()
		material.albedo_color = Color.from_hsv(rng.randf_range(0.04, 0.12), rng.randf_range(0.25, 0.62), rng.randf_range(0.48, 0.84))
		material.roughness = 0.9
		body.material_override = material
		body.position.y = 0.78
		person.add_child(body)
		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.25
		head_mesh.height = 0.5
		head.mesh = head_mesh
		head.position.y = 1.62
		head.material_override = material
		person.add_child(head)
		var home := Vector3(rng.randf_range(-27.0, 27.0), _height_at(0.0, 0.0), rng.randf_range(-27.0, 27.0))
		home.y = _height_at(home.x, home.z)
		person.position = home
		people_root.add_child(person)
		founders.append(person)
		people.append({
			"id": i + 1,
			"name": "Founder %03d" % (i + 1),
			"age": rng.randi_range(18, 42),
			"hunger": rng.randf_range(15.0, 48.0),
			"thirst": rng.randf_range(12.0, 40.0),
			"energy": rng.randf_range(55.0, 100.0),
			"health": 100.0,
			"alive": true,
			"action": "Exploring",
			"target": home,
			"home": home,
			"food_eaten": 0,
			"water_drunk": 0
		})

func _advance_day() -> void:
	elapsed_days += 1
	# Plants recover slowly through natural growth. This is plant regrowth, not
	# artificial animal or human respawning.
	if elapsed_days % 12 == 0:
		for food_index in range(food_sources.size()):
			var plant: Dictionary = food_sources[food_index]
			if int(plant["food"]) < int(plant["capacity"]):
				plant["food"] = int(plant["food"]) + 1
				if is_instance_valid(plant["node"]):
					plant["node"].visible = true
				food_sources[food_index] = plant
	for i in range(people.size()):
		var person: Dictionary = people[i]
		if not person["alive"]:
			continue
		person["age"] = int(person["age"]) + (1 if elapsed_days % 365 == 0 else 0)
		person["hunger"] = minf(100.0, float(person["hunger"]) + 5.0)
		person["thirst"] = minf(100.0, float(person["thirst"]) + 7.0)
		person["energy"] = minf(100.0, float(person["energy"]) + 2.0)
		if float(person["hunger"]) > 82.0:
			person["health"] = maxf(0.0, float(person["health"]) - 2.0)
		if float(person["thirst"]) > 82.0:
			person["health"] = maxf(0.0, float(person["health"]) - 4.0)
		if float(person["energy"]) < 15.0:
			person["health"] = maxf(0.0, float(person["health"]) - 1.0)
		if float(person["health"]) <= 0.0:
			person["alive"] = false
			person["action"] = "Died from unmet survival needs"
			founders[i].visible = false
			people[i] = person
			continue
		_choose_action(i)
		people[i] = person

func _choose_action(index: int) -> void:
	var person: Dictionary = people[index]
	if float(person["thirst"]) >= float(person["hunger"]) * 0.72:
		var nearest_water := _nearest_water(founders[index].position)
		person["target"] = nearest_water
		person["action"] = "Seeking water"
		if Vector2(founders[index].position.x - nearest_water.x, founders[index].position.z - nearest_water.z).length() < 3.0:
			person["thirst"] = maxf(0.0, float(person["thirst"]) - 52.0)
			person["water_drunk"] = int(person["water_drunk"]) + 1
			person["action"] = "Drinking"
	else:
		var food_index := _nearest_food(founders[index].position)
		if food_index >= 0:
			var food: Dictionary = food_sources[food_index]
			var food_position: Vector3 = food["position"]
			person["target"] = food_position
			person["action"] = "Gathering food"
			if Vector2(founders[index].position.x - food_position.x, founders[index].position.z - food_position.z).length() < 2.5 and int(food["food"]) > 0:
				food["food"] = int(food["food"]) - 1
				person["hunger"] = maxf(0.0, float(person["hunger"]) - 42.0)
				person["food_eaten"] = int(person["food_eaten"]) + 1
				person["action"] = "Eating"
				food_sources[food_index] = food
				if int(food["food"]) <= 0 and is_instance_valid(food["node"]):
					food["node"].visible = false
					food_sources[food_index] = food
		else:
			person["target"] = person["home"]
			person["action"] = "Searching for food"
	people[index] = person

func _nearest_water(from: Vector3) -> Vector3:
	var nearest := water_sources[0]
	var best_distance := from.distance_squared_to(nearest)
	for point in water_sources:
		var distance := from.distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			nearest = point
	return nearest

func _nearest_food(from: Vector3) -> int:
	var best_index := -1
	var best_distance := INF
	for i in range(food_sources.size()):
		var food: Dictionary = food_sources[i]
		if int(food["food"]) <= 0:
			continue
		var point: Vector3 = food["position"]
		var distance := from.distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

func _move_people(delta: float) -> void:
	for i in range(people.size()):
		var person: Dictionary = people[i]
		if not person["alive"]:
			continue
		var agent := founders[i]
		var target: Vector3 = person["target"]
		var current := agent.position
		var flat_target := Vector3(target.x, _height_at(target.x, target.z), target.z)
		var direction := Vector3(flat_target.x - current.x, 0.0, flat_target.z - current.z)
		if direction.length() > 1.3:
			direction = direction.normalized()
			var movement := minf(2.1 * delta, current.distance_to(flat_target))
			agent.position.x += direction.x * movement
			agent.position.z += direction.z * movement
			agent.position.y = _height_at(agent.position.x, agent.position.z)
			if direction.length() > 0.1:
				agent.rotation.y = atan2(direction.x, direction.z)

func _build_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(310, 210)
	layer.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	panel.add_child(layout)
	var heading := Label.new()
	heading.text = "LIVING WORLD"
	heading.add_theme_font_size_override("font_size", 24)
	layout.add_child(heading)
	var motto := Label.new()
	motto.text = "The people create the world."
	motto.add_theme_font_size_override("font_size", 12)
	layout.add_child(motto)
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
	people_button = Button.new()
	people_button.text = "Inspect person"
	people_button.pressed.connect(_cycle_person)
	layout.add_child(people_button)
	var save_controls := HBoxContainer.new()
	layout.add_child(save_controls)
	var save_button := Button.new()
	save_button.text = "Save world"
	save_button.pressed.connect(_save_world)
	save_controls.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "Load world"
	load_button.pressed.connect(_load_world)
	save_controls.add_child(load_button)
	detail_label = Label.new()
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.custom_minimum_size = Vector2(280, 100)
	layout.add_child(detail_label)
	var footer := Label.new()
	footer.text = "Drag to pan • Pinch to zoom\nPURE OBSERVATION  •  ORIGINAL FOUNDERS: 100"
	footer.add_theme_font_size_override("font_size", 10)
	layout.add_child(footer)

func _save_world() -> void:
	var save_data := ConfigFile.new()
	save_data.set_value("world", "seed", world_seed)
	save_data.set_value("world", "elapsed_days", elapsed_days)
	save_data.set_value("world", "time_speed", time_speed)
	save_data.set_value("world", "people", people)
	var positions: Array[Vector3] = []
	for agent in founders:
		positions.append(agent.position)
	save_data.set_value("world", "positions", positions)
	var food_amounts: Array[int] = []
	for source in food_sources:
		food_amounts.append(int(source["food"]))
	save_data.set_value("world", "food_amounts", food_amounts)
	var result := save_data.save("user://living_world.save")
	if result == OK:
		ui_notice = "World saved successfully."
	else:
		ui_notice = "Save failed. Error code: %d" % result

func _load_world() -> void:
	var save_data := ConfigFile.new()
	var result := save_data.load("user://living_world.save")
	if result != OK:
		ui_notice = "No valid save found yet."
		return
	var saved_seed := int(save_data.get_value("world", "seed", world_seed))
	_configure_seed(saved_seed)
	_build_world_content()
	elapsed_days = int(save_data.get_value("world", "elapsed_days", 0))
	time_speed = float(save_data.get_value("world", "time_speed", 1.0))
	var saved_people: Array = save_data.get_value("world", "people", [])
	var saved_positions: Array = save_data.get_value("world", "positions", [])
	var saved_food: Array = save_data.get_value("world", "food_amounts", [])
	for i in range(mini(people.size(), saved_people.size())):
		var saved_person: Dictionary = saved_people[i]
		people[i] = saved_person
		if i < saved_positions.size():
			founders[i].position = saved_positions[i]
		founders[i].visible = bool(saved_person["alive"])
	for i in range(mini(food_sources.size(), saved_food.size())):
		var source: Dictionary = food_sources[i]
		source["food"] = int(saved_food[i])
		if is_instance_valid(source["node"]):
			source["node"].visible = int(source["food"]) > 0
		food_sources[i] = source
	paused = true
	day_accumulator = 0.0
	ui_notice = "World loaded. Simulation is paused."
	_update_interface()

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

func _cycle_person() -> void:
	for offset in range(1, people.size() + 1):
		var candidate := (selected_index + offset) % people.size()
		if bool(people[candidate]["alive"]):
			selected_index = candidate
			break
	_update_interface()

func _update_interface() -> void:
	if status_label == null:
		return
	var alive_count := 0
	for person in people:
		if bool(person["alive"]):
			alive_count += 1
	status_label.text = "Year %d  •  Day %d\nLiving people: %d / %d%s" % [int(elapsed_days / 365) + 1, elapsed_days % 365 + 1, alive_count, FOUNDER_COUNT, ("\n" + ui_notice) if not ui_notice.is_empty() else ""]
	seed_label.text = "World seed: %d" % world_seed
	if pause_button != null:
		pause_button.text = "Resume" if paused else "Pause"
	if speed_button != null:
		speed_button.text = "Time x%d" % int(time_speed)
	if detail_label != null and people.size() > 0:
		var person: Dictionary = people[selected_index]
		var state := "Alive" if bool(person["alive"]) else "Dead"
		detail_label.text = "PERSON: %s  •  %s\nAge: %d\nHealth: %d  |  Hunger: %d  |  Thirst: %d\nAction: %s\nFood gathered: %d  •  Water visits: %d" % [
			person["name"], state, int(person["age"]), int(person["health"]), int(person["hunger"]), int(person["thirst"]),
			person["action"], int(person["food_eaten"]), int(person["water_drunk"])
		]
