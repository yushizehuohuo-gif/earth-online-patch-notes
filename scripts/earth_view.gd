extends Control

var stats := {
	"civilization": 50.0,
	"ecology": 50.0,
	"joy": 50.0,
	"stability": 50.0,
}
var patch_index := 0
var game_over := false
var pulse := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func set_world_state(next_stats: Dictionary, next_patch_index: int, stopped: bool) -> void:
	stats = next_stats.duplicate()
	patch_index = next_patch_index
	game_over = stopped
	queue_redraw()


func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.33
	var stability: float = _value("stability") / 100.0
	var ecology: float = _value("ecology") / 100.0
	var civilization: float = _value("civilization") / 100.0
	var joy: float = _value("joy") / 100.0

	_draw_starfield(center, radius, joy)
	_draw_orbits(center, radius, stability)
	_draw_planet(center, radius, ecology, civilization, joy, stability)
	_draw_status_marks(center, radius, civilization, stability)


func _draw_starfield(center: Vector2, radius: float, joy: float) -> void:
	for index in range(34):
		var angle := float(index) * 1.91 + 0.3
		var distance := radius * (1.24 + float(index % 7) * 0.12)
		var pos := center + Vector2(cos(angle), sin(angle)) * distance
		var flicker := 0.45 + 0.32 * sin(pulse * 1.6 + float(index))
		var star_color := Color(0.55 + joy * 0.3, 0.68 + joy * 0.2, 0.86, flicker)
		draw_circle(pos, 1.2 + float(index % 3) * 0.35, star_color)


func _draw_orbits(center: Vector2, radius: float, stability: float) -> void:
	var orbit_color := Color(0.38, 0.58, 0.78, 0.18 + stability * 0.25)
	draw_arc(center, radius * 1.24, 0.0, TAU, 120, orbit_color, 1.5, true)
	draw_arc(center, radius * 1.44, -0.6, TAU - 0.6, 120, Color(0.5, 0.66, 0.82, 0.12), 1.0, true)

	var satellite_angle := pulse * 0.55 + float(patch_index) * 0.35
	var satellite := center + Vector2(cos(satellite_angle), sin(satellite_angle)) * radius * 1.24
	draw_circle(satellite, 4.0, Color(0.92, 0.97, 1.0, 0.95))
	draw_line(satellite + Vector2(-5, 3), satellite + Vector2(5, -3), Color(0.55, 0.76, 0.95, 0.75), 1.4, true)


func _draw_planet(center: Vector2, radius: float, ecology: float, civilization: float, joy: float, stability: float) -> void:
	var warning: float = clampf(1.0 - stability, 0.0, 1.0)
	var ocean := Color(0.07, 0.28 + ecology * 0.18, 0.52 + stability * 0.18)
	if game_over:
		ocean = Color(0.18, 0.19, 0.22)

	draw_circle(center, radius + 9.0 + sin(pulse * 2.0) * 1.3, Color(0.08, 0.45, 0.78, 0.13 + stability * 0.18))
	draw_circle(center, radius, ocean)
	draw_arc(center, radius + 1.5, 0.0, TAU, 160, Color(0.8, 0.94, 1.0, 0.35), 2.0, true)

	var land := Color(0.16 + ecology * 0.18, 0.42 + ecology * 0.34, 0.19 + ecology * 0.08)
	if game_over:
		land = Color(0.28, 0.27, 0.22)

	_draw_blob(center, radius, [
		Vector2(-0.56, -0.20), Vector2(-0.42, -0.43), Vector2(-0.15, -0.34),
		Vector2(-0.05, -0.12), Vector2(-0.20, 0.12), Vector2(-0.47, 0.08),
	], land)
	_draw_blob(center, radius, [
		Vector2(0.08, -0.38), Vector2(0.35, -0.50), Vector2(0.56, -0.28),
		Vector2(0.50, -0.05), Vector2(0.25, 0.02), Vector2(0.02, -0.12),
	], land.lightened(0.08))
	_draw_blob(center, radius, [
		Vector2(0.18, 0.16), Vector2(0.45, 0.12), Vector2(0.58, 0.34),
		Vector2(0.35, 0.52), Vector2(0.12, 0.42),
	], land.darkened(0.04))

	var cloud_alpha: float = 0.16 + ecology * 0.2 + joy * 0.08
	_draw_cloud(center + Vector2(-radius * 0.26, -radius * 0.38), radius * 0.16, cloud_alpha)
	_draw_cloud(center + Vector2(radius * 0.34, radius * 0.22), radius * 0.13, cloud_alpha)

	if civilization > 0.42:
		_draw_city_lights(center, radius, civilization, warning)

	if warning > 0.45:
		_draw_glitches(center, radius, warning)


func _draw_blob(center: Vector2, radius: float, points: Array, color: Color) -> void:
	var polygon := PackedVector2Array()
	for point in points:
		var typed_point: Vector2 = point as Vector2
		polygon.append(center + typed_point * radius)
	draw_colored_polygon(polygon, color)


func _draw_cloud(pos: Vector2, radius: float, alpha: float) -> void:
	var color := Color(0.9, 0.96, 1.0, alpha)
	draw_circle(pos + Vector2(-radius * 0.55, 0.0), radius * 0.58, color)
	draw_circle(pos, radius * 0.75, color)
	draw_circle(pos + Vector2(radius * 0.6, radius * 0.05), radius * 0.5, color)


func _draw_city_lights(center: Vector2, radius: float, civilization: float, warning: float) -> void:
	var count := int(7 + civilization * 18.0)
	for index in range(count):
		var angle := float(index) * 2.38 + 0.7
		var band := -0.55 + float(index % 6) * 0.19
		var pos := center + Vector2(cos(angle) * radius * 0.58, band * radius)
		if pos.distance_to(center) < radius * 0.88:
			var light := Color(1.0, 0.74 - warning * 0.22, 0.34, 0.5 + civilization * 0.35)
			draw_circle(pos, 2.0 + civilization * 1.3, light)


func _draw_glitches(center: Vector2, radius: float, warning: float) -> void:
	for index in range(5):
		var y := center.y - radius * 0.55 + float(index) * radius * 0.28 + sin(pulse * 5.0 + float(index)) * 3.0
		var offset := sin(pulse * 8.0 + float(index) * 1.7) * radius * 0.2 * warning
		var start := Vector2(center.x - radius * 0.72 + offset, y)
		var end := Vector2(center.x + radius * 0.72 + offset, y + 2.0)
		draw_line(start, end, Color(1.0, 0.22, 0.3, 0.22 + warning * 0.34), 2.0, true)


func _draw_status_marks(center: Vector2, radius: float, civilization: float, stability: float) -> void:
	var arc_color := Color(0.42, 0.78, 1.0, 0.14 + stability * 0.26)
	draw_arc(center, radius * 0.78, -0.3 + pulse * 0.18, 2.2 + pulse * 0.18, 70, arc_color, 2.0, true)
	draw_arc(center, radius * 0.91, 2.6 - pulse * 0.12, 4.4 - pulse * 0.12, 70, Color(1.0, 0.76, 0.36, 0.1 + civilization * 0.18), 1.6, true)


func _value(key: String) -> float:
	if stats.has(key):
		return float(stats[key])
	return 50.0
