class_name WorldRouteOverlay
extends Node2D

const ALPHA_COLOR := Color("63e6ff")
const BETA_COLOR := Color("ff6aa9")

var alpha_points := PackedVector2Array()
var beta_points := PackedVector2Array()


func set_route_rows(rows: Array[Dictionary], lane_count: int) -> void:
	alpha_points.clear()
	beta_points.clear()
	var lane_width := 1280.0 / lane_count
	for row in rows:
		var row_y := float(row["y"])
		alpha_points.append(Vector2((int(row["alpha_lane"]) + 0.5) * lane_width, row_y))
		beta_points.append(Vector2((int(row["beta_lane"]) + 0.5) * lane_width, row_y))
	queue_redraw()


func _draw() -> void:
	_draw_route(alpha_points, ALPHA_COLOR)
	_draw_route(beta_points, BETA_COLOR)


func _draw_route(points: PackedVector2Array, color: Color) -> void:
	if points.is_empty():
		return
	if points.size() >= 2:
		draw_polyline(points, Color(color, 0.18), 14.0, true)
		draw_polyline(points, Color(color, 0.9), 4.0, true)
	for index in points.size():
		var point := points[index]
		draw_circle(point, 15.0, Color(color, 0.16))
		draw_arc(point, 11.0, 0.0, TAU, 24, Color(color, 0.95), 3.0, true)
		if index == 0:
			continue
		var direction := (point - points[index - 1]).normalized()
		var side := direction.orthogonal()
		var arrow_tip := point - direction * 17.0
		draw_colored_polygon(PackedVector2Array([
			arrow_tip,
			arrow_tip - direction * 13.0 + side * 7.0,
			arrow_tip - direction * 13.0 - side * 7.0,
		]), Color(color, 0.95))
