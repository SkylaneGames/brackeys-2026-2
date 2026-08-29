extends Control
class_name RoutePreview

@export var route_color := Color("63e6ff")
@export_range(2, 12) var lane_count := 8

var route: Array[int] = []
var player_lane := 0
var is_active := false
var reward_step := -1


func set_route(next_route: Array[int], current_player_lane: int, next_reward_step := -1) -> void:
	route.assign(next_route)
	player_lane = clampi(current_player_lane, 0, lane_count - 1)
	reward_step = next_reward_step
	queue_redraw()


func set_active(value: bool) -> void:
	is_active = value
	queue_redraw()


func _draw() -> void:
	var inset := 8.0
	var top := 8.0
	var bottom := size.y - 10.0
	var lane_width := (size.x - inset * 2.0) / lane_count
	var grid_color := Color(route_color, 0.13 if is_active else 0.08)
	var path_color := Color(route_color, 1.0 if is_active else 0.55)

	for lane in range(lane_count + 1):
		var x := inset + lane * lane_width
		draw_line(Vector2(x, top), Vector2(x, bottom), grid_color, 1.0)

	if route.is_empty():
		return

	var row_gap := (bottom - top - 28.0) / route.size()
	var points := PackedVector2Array([Vector2(_lane_x(player_lane, inset, lane_width), bottom)])
	for index in route.size():
		var y := bottom - 28.0 - index * row_gap
		points.append(Vector2(_lane_x(route[index], inset, lane_width), y))
		draw_line(Vector2(inset, y), Vector2(size.x - inset, y), grid_color, 1.0)

	draw_polyline(points, Color(path_color, 0.25), 8.0, true)
	draw_polyline(points, path_color, 3.0, true)

	# The triangle is the ship. The closest, largest waypoint is the action now.
	var ship := points[0]
	draw_colored_polygon(PackedVector2Array([
		ship + Vector2(0.0, -8.0),
		ship + Vector2(-6.0, 5.0),
		ship + Vector2(0.0, 2.0),
		ship + Vector2(6.0, 5.0),
	]), path_color)
	for index in route.size():
		var point := points[index + 1]
		var radius := 7.0 if index == 0 else 4.0
		if index == 0:
			draw_circle(point, 12.0, Color(path_color, 0.16))
			draw_arc(point, 10.0, 0.0, TAU, 24, path_color, 2.0, true)
		draw_circle(point, radius, path_color)
		if index == reward_step:
			var reward_color := Color("73ffad")
			draw_circle(point + Vector2(13.0, -10.0), 8.0, Color(0.02, 0.12, 0.08, 0.95))
			draw_line(point + Vector2(9.0, -10.0), point + Vector2(17.0, -10.0), reward_color, 3.0)
			draw_line(point + Vector2(13.0, -14.0), point + Vector2(13.0, -6.0), reward_color, 3.0)


func _lane_x(lane: int, inset: float, lane_width: float) -> float:
	return inset + (clampi(lane, 0, lane_count - 1) + 0.5) * lane_width
