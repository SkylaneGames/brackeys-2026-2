class_name WorldRouteOverlay
extends Node2D

const ALPHA_COLOR := Color("63e6ff")
const BETA_COLOR := Color("ff6aa9")

var alpha_points := PackedVector2Array()
var beta_points := PackedVector2Array()
var trusted_route := 0


func set_route_rows(rows: Array[Dictionary], lane_count: int) -> void:
	alpha_points.clear()
	beta_points.clear()
	var lane_width := 1280.0 / lane_count
	for row in rows:
		var row_y := float(row["y"])
		alpha_points.append(Vector2((int(row["alpha_lane"]) + 0.5) * lane_width, row_y))
		beta_points.append(Vector2((int(row["beta_lane"]) + 0.5) * lane_width, row_y))
	queue_redraw()


func set_trusted_route(value: int) -> void:
	if trusted_route == value:
		return
	trusted_route = value
	queue_redraw()


func _draw() -> void:
	_draw_current_row_marker()
	_draw_route(alpha_points, ALPHA_COLOR, trusted_route == 1)
	_draw_route(beta_points, BETA_COLOR, trusted_route == 2)


func _draw_current_row_marker() -> void:
	if alpha_points.is_empty() or beta_points.is_empty():
		return
	var row_y := alpha_points[0].y
	draw_dashed_line(Vector2(32.0, row_y), Vector2(1248.0, row_y), Color(0.72, 0.82, 0.95, 0.16), 2.0, 18.0, true)


func _draw_route(points: PackedVector2Array, color: Color, is_trusted: bool) -> void:
	if points.is_empty():
		return
	var route_alpha := 0.95 if is_trusted else 0.58
	var route_width := 6.0 if is_trusted else 3.0
	if points.size() >= 2:
		draw_polyline(points, Color(color, 0.14 if is_trusted else 0.08), 16.0 if is_trusted else 11.0, true)
		draw_polyline(points, Color(color, route_alpha), route_width, true)
	for index in points.size():
		var point := points[index]
		var depth_alpha := maxf(0.34, route_alpha - index * 0.16)
		var radius := 17.0 if index == 0 else 13.0
		draw_circle(point, radius + 4.0, Color(color, 0.18 if index == 0 else 0.09))
		draw_arc(point, radius, 0.0, TAU, 28, Color(color, depth_alpha), 4.0 if index == 0 else 2.5, true)
		if index == 0:
			draw_arc(point, radius + 7.0, 0.0, TAU, 32, Color(0.92, 0.97, 1.0, 0.55), 2.0, true)
			continue
		var direction := (point - points[index - 1]).normalized()
		var side := direction.orthogonal()
		var arrow_tip := point - direction * 17.0
		draw_colored_polygon(PackedVector2Array([
			arrow_tip,
			arrow_tip - direction * 13.0 + side * 7.0,
			arrow_tip - direction * 13.0 - side * 7.0,
		]), Color(color, depth_alpha))
