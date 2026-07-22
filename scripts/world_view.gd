extends Control

var world_seed := 1
var climate_index := 1
var water_index := 1
var mineral_index := 1
var year := 0
var population := 0
var tech_level := 0
var civilization_alive := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func configure(data: Dictionary) -> void:
	world_seed = int(data.get("seed", 1))
	climate_index = int(data.get("climate", 1))
	water_index = int(data.get("water", 1))
	mineral_index = int(data.get("minerals", 1))
	queue_redraw()

func set_civilization_state(new_year: int, new_population: int, new_tech_level: int, alive: bool = true) -> void:
	year = new_year
	population = new_population
	tech_level = new_tech_level
	civilization_alive = alive
	queue_redraw()

func _draw() -> void:
	var canvas_size: Vector2 = size
	if canvas_size.x <= 1.0 or canvas_size.y <= 1.0:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed

	var sky_color := Color("#132236")
	if climate_index == 0:
		sky_color = Color("#16283f")
	elif climate_index == 2:
		sky_color = Color("#352018")
	draw_rect(Rect2(Vector2.ZERO, canvas_size), sky_color)

	var sun_position := Vector2(canvas_size.x * 0.82, canvas_size.y * 0.18)
	draw_circle(sun_position, min(canvas_size.x, canvas_size.y) * 0.055, Color("#ffd98a"))

	for i in range(28):
		var star_position := Vector2(rng.randf_range(16.0, canvas_size.x - 16.0), rng.randf_range(12.0, canvas_size.y * 0.44))
		draw_circle(star_position, rng.randf_range(0.8, 1.8), Color(1, 1, 1, rng.randf_range(0.25, 0.7)))

	var horizon: float = canvas_size.y * 0.54
	var terrain_points := PackedVector2Array()
	terrain_points.append(Vector2(0, canvas_size.y))
	terrain_points.append(Vector2(0, horizon))
	for i in range(13):
		var x: float = canvas_size.x * float(i) / 12.0
		var y: float = horizon + rng.randf_range(-34.0, 28.0)
		terrain_points.append(Vector2(x, y))
	terrain_points.append(Vector2(canvas_size.x, canvas_size.y))

	var land_color := Color("#45684e")
	if climate_index == 0:
		land_color = Color("#637584")
	elif climate_index == 2:
		land_color = Color("#806347")
	draw_colored_polygon(terrain_points, land_color)

	for i in range(6):
		var center_x: float = canvas_size.x * (0.08 + float(i) * 0.18) + rng.randf_range(-28.0, 28.0)
		var base_y: float = horizon + 15.0
		var mountain_height: float = rng.randf_range(80.0, 170.0) * (1.0 + mineral_index * 0.08)
		var mountain_width: float = rng.randf_range(110.0, 190.0)
		var triangle := PackedVector2Array([
			Vector2(center_x - mountain_width * 0.5, base_y),
			Vector2(center_x, base_y - mountain_height),
			Vector2(center_x + mountain_width * 0.5, base_y)
		])
		draw_colored_polygon(triangle, Color("#2f4150"))
		if climate_index == 0:
			var snow := PackedVector2Array([
				Vector2(center_x - mountain_width * 0.14, base_y - mountain_height * 0.72),
				Vector2(center_x, base_y - mountain_height),
				Vector2(center_x + mountain_width * 0.14, base_y - mountain_height * 0.72)
			])
			draw_colored_polygon(snow, Color("#dce7ef"))

	if water_index > 0:
		var river_width: float = 32.0 + water_index * 20.0
		var river_points := PackedVector2Array()
		for i in range(9):
			var px: float = canvas_size.x * float(i) / 8.0
			var py: float = horizon + 80.0 + sin(float(i) * 1.2 + float(world_seed % 7)) * 24.0
			river_points.append(Vector2(px, py))
		draw_polyline(river_points, Color("#397da3"), river_width, true)
		draw_polyline(river_points, Color(0.55, 0.82, 0.95, 0.45), 3.0, true)

	var tree_count: int = 14 + water_index * 8
	if climate_index == 2:
		tree_count -= 6
	for i in range(max(tree_count, 5)):
		var tx: float = rng.randf_range(18.0, canvas_size.x - 18.0)
		var ty: float = rng.randf_range(horizon + 24.0, canvas_size.y - 24.0)
		var leaf_color := Color("#244f3b") if climate_index != 2 else Color("#52613a")
		draw_rect(Rect2(Vector2(tx - 2.0, ty), Vector2(4.0, 12.0)), Color("#49372a"))
		draw_circle(Vector2(tx, ty - 3.0), rng.randf_range(6.0, 10.0), leaf_color)

	if civilization_alive:
		_draw_civilization(rng, canvas_size, horizon)

func _draw_civilization(rng: RandomNumberGenerator, canvas_size: Vector2, horizon: float) -> void:
	var settlement_count: int = clampi(1 + tech_level + int(population / 2500), 1, 10)
	for i in range(settlement_count):
		var sx: float = canvas_size.x * (0.12 + float(i % 5) * 0.18) + rng.randf_range(-24.0, 24.0)
		var row: int = int(i / 5)
		var sy: float = horizon + 95.0 + row * 90.0 + rng.randf_range(-16.0, 16.0)
		var settlement_scale: float = 0.75 + min(tech_level, 6) * 0.09
		draw_rect(Rect2(Vector2(sx - 11.0 * settlement_scale, sy - 8.0 * settlement_scale), Vector2(22.0 * settlement_scale, 18.0 * settlement_scale)), Color("#f1c27d"))
		var roof := PackedVector2Array([
			Vector2(sx - 14.0 * settlement_scale, sy - 8.0 * settlement_scale),
			Vector2(sx, sy - 22.0 * settlement_scale),
			Vector2(sx + 14.0 * settlement_scale, sy - 8.0 * settlement_scale)
		])
		draw_colored_polygon(roof, Color("#9f5547"))
		draw_rect(Rect2(Vector2(sx - 2.0 * settlement_scale, sy + 1.0 * settlement_scale), Vector2(4.0 * settlement_scale, 9.0 * settlement_scale)), Color("#342b2a"))

	if tech_level >= 3:
		var road_y: float = horizon + 165.0
		draw_line(Vector2(30.0, road_y), Vector2(canvas_size.x - 30.0, road_y + 28.0), Color(0.78, 0.68, 0.52, 0.65), 7.0, true)

	if tech_level >= 5:
		for i in range(3):
			var tower_x: float = canvas_size.x * (0.3 + i * 0.2)
			var tower_y: float = horizon + 120.0
			draw_rect(Rect2(Vector2(tower_x - 9.0, tower_y - 58.0), Vector2(18.0, 58.0)), Color("#687681"))
			draw_circle(Vector2(tower_x, tower_y - 62.0), 7.0, Color("#b8d8ee"))
