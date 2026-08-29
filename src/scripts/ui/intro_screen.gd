extends Control

const CRAWL_DURATION := 30.0
const CRAWL_START_POS := Vector3(0.0, -1.2, 0.8)
const CRAWL_END_POS := Vector3(0.0, 4.2, -7.2)

@onready var crawl_layer: Control = %CrawlLayer
@onready var crawl_text: Label3D = %CrawlText
@onready var briefing: Control = %Briefing
@onready var skip_button: Button = %SkipButton
@onready var begin_button: Button = %BeginButton

var stars: Array[Vector3] = []
var crawl_elapsed := 0.0
var showing_briefing := false


func _ready() -> void:
	GameManager.state = GameManager.GameState.INTRO
	var random := RandomNumberGenerator.new()
	random.seed = 4097
	for index in 150:
		stars.append(Vector3(random.randf_range(0.0, 1280.0), random.randf_range(0.0, 720.0), random.randf_range(0.5, 1.8)))
	skip_button.grab_focus()
	queue_redraw()


func _process(delta: float) -> void:
	for index in stars.size():
		var star := stars[index]
		star.y += star.z * delta * 7.0
		if star.y > 720.0:
			star.y = 0.0
		stars[index] = star
	queue_redraw()
	if showing_briefing:
		return
	crawl_elapsed += delta
	var progress := clampf(crawl_elapsed / CRAWL_DURATION, 0.0, 1.0)
	crawl_text.position = CRAWL_START_POS.lerp(CRAWL_END_POS, progress)
	crawl_text.modulate.a = 1.0 - smoothstep(0.88, 1.0, progress)
	if progress >= 1.0:
		_show_briefing()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey and event.keycode in [Key.KEY_ENTER, Key.KEY_SPACE, Key.KEY_ESCAPE]:
		# A scene transition detaches this node immediately, so consume the event first.
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
		if showing_briefing:
			if event.keycode != Key.KEY_ESCAPE:
				_begin_run()
		else:
			_show_briefing()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("050817"))
	for star in stars:
		var brightness := 0.35 + star.z * 0.28
		draw_circle(Vector2(star.x, star.y), star.z, Color(brightness, brightness, brightness + 0.12, 0.9))
	if showing_briefing:
		_draw_briefing_symbols()


func _draw_briefing_symbols() -> void:
	_draw_briefing_card(Rect2(45.0, 145.0, 370.0, 390.0), Color("b7c7dd"))
	_draw_briefing_card(Rect2(455.0, 145.0, 370.0, 390.0), Color("63e6ff"))
	_draw_briefing_card(Rect2(865.0, 145.0, 370.0, 390.0), Color("73ffad"))

	# 1. Manual movement is shown once; the next card explains its trust consequence.
	var ship := Vector2(230.0, 310.0)
	draw_colored_polygon(PackedVector2Array([ship + Vector2(0, -22), ship + Vector2(-15, 18), ship, ship + Vector2(15, 18)]), Color("e8f5ff"))
	_draw_keycap(Vector2(95.0, 288.0), "A", Color("b7c7dd"))
	_draw_keycap(Vector2(317.0, 288.0), "D", Color("b7c7dd"))
	draw_line(Vector2(190, 310), Vector2(155, 310), Color("b7c7dd"), 4.0)
	draw_line(Vector2(270, 310), Vector2(305, 310), Color("b7c7dd"), 4.0)

	# 2. Either guide reveals a route; manual steering disconnects it.
	_draw_keycap(Vector2(490.0, 215.0), "Q", Color("63e6ff"))
	_draw_route(PackedVector2Array([Vector2(555, 390), Vector2(595, 330), Vector2(575, 270)]), Color("63e6ff"))
	_draw_keycap(Vector2(737.0, 215.0), "E", Color("ff6aa9"))
	_draw_route(PackedVector2Array([Vector2(715, 390), Vector2(675, 330), Vector2(695, 270)]), Color("ff6aa9"))

	# 3. The same amber target and green repair symbols used during play.
	var rock := Vector2(945.0, 310.0)
	for corner in 4:
		var start := corner * PI * 0.5 + 0.2
		draw_arc(rock, 42.0, start, start + 0.85, 10, Color("ffc747"), 4.0, true)
	draw_circle(rock, 21.0, Color("39435a"))
	draw_line(Vector2(945, 375), Vector2(945, 360), Color("8cf7ff"), 5.0)
	_draw_keycap(Vector2(1000.0, 288.0), "SPACE", Color("8cf7ff"), Vector2(112.0, 44.0))
	var repair := Vector2(1175.0, 310.0)
	draw_circle(repair, 24.0, Color(0.1, 0.35, 0.23, 0.75))
	draw_line(repair + Vector2(-11, 0), repair + Vector2(11, 0), Color("73ffad"), 7.0)
	draw_line(repair + Vector2(0, -11), repair + Vector2(0, 11), Color("73ffad"), 7.0)


func _draw_briefing_card(rect: Rect2, accent: Color) -> void:
	draw_rect(rect, Color(0.025, 0.055, 0.12, 0.88), true)
	draw_line(rect.position + Vector2(0.0, 1.0), rect.position + Vector2(rect.size.x, 1.0), Color(accent, 0.8), 3.0)
	draw_rect(rect, Color(accent, 0.32), false, 1.0)


func _draw_route(points: PackedVector2Array, color: Color) -> void:
	draw_polyline(points, Color(color, 0.25), 9.0, true)
	draw_polyline(points, color, 3.0, true)
	for point in points:
		draw_circle(point, 5.0, color)
	draw_arc(points[1], 10.0, 0.0, TAU, 20, color, 2.0, true)


func _draw_keycap(position: Vector2, text: String, color: Color, key_size := Vector2(48.0, 44.0)) -> void:
	var rect := Rect2(position, key_size)
	draw_rect(rect, Color(0.03, 0.06, 0.13, 0.96), true)
	draw_rect(rect, color, false, 2.0)
	var font := ThemeDB.fallback_font
	var font_size := 18
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, position + (key_size - text_size) * 0.5 + Vector2(0.0, text_size.y * 0.76), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _show_briefing() -> void:
	showing_briefing = true
	crawl_layer.visible = false
	briefing.visible = true
	skip_button.visible = false
	begin_button.grab_focus()
	queue_redraw()


func _begin_run() -> void:
	GameManager.start_run()


func _on_skip_pressed() -> void:
	_show_briefing()


func _on_begin_pressed() -> void:
	_begin_run()
