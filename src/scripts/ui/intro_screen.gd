extends Control

const CRAWL_DURATION := 26.0

@onready var crawl_layer: Control = %CrawlLayer
@onready var crawl_text: Label = %CrawlText
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
	# Strong scale reduction makes the copy recede into the starfield as it rises.
	crawl_text.position.y = lerpf(750.0, -760.0, progress)
	var crawl_scale := lerpf(1.34, 0.55, progress)
	crawl_text.scale = Vector2.ONE * crawl_scale
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
	# Trust: two spatially distinct plans, matching the in-game color language.
	_draw_keycap(Vector2(110.0, 250.0), "Q", Color("63e6ff"))
	_draw_route(PackedVector2Array([Vector2(165, 340), Vector2(205, 305), Vector2(185, 270), Vector2(240, 235)]), Color("63e6ff"))
	_draw_keycap(Vector2(285.0, 250.0), "E", Color("ff6aa9"))
	_draw_route(PackedVector2Array([Vector2(340, 340), Vector2(315, 305), Vector2(350, 270), Vector2(320, 235)]), Color("ff6aa9"))

	# Override: direct movement remains available while the sensor aperture shrinks.
	var ship := Vector2(640.0, 305.0)
	draw_circle(ship, 68.0, Color(0.12, 0.2, 0.36, 0.5))
	draw_circle(ship, 36.0, Color("050817"))
	draw_colored_polygon(PackedVector2Array([ship + Vector2(0, -22), ship + Vector2(-15, 18), ship, ship + Vector2(15, 18)]), Color("e8f5ff"))
	_draw_keycap(Vector2(510.0, 285.0), "A", Color("b7c7dd"))
	_draw_keycap(Vector2(735.0, 285.0), "D", Color("b7c7dd"))
	draw_line(Vector2(570, 305), Vector2(535, 305), Color("b7c7dd"), 4.0)
	draw_line(Vector2(710, 305), Vector2(745, 305), Color("b7c7dd"), 4.0)

	# Recovery: the same amber reticle and green repair cross used during play.
	var rock := Vector2(1010.0, 280.0)
	for corner in 4:
		var start := corner * PI * 0.5 + 0.2
		draw_arc(rock, 42.0, start, start + 0.85, 10, Color("ffc747"), 4.0, true)
	draw_circle(rock, 21.0, Color("39435a"))
	draw_line(Vector2(1010, 380), Vector2(1010, 330), Color("8cf7ff"), 5.0)
	_draw_keycap(Vector2(902.0, 355.0), "SPACE", Color("8cf7ff"), Vector2(112.0, 44.0))
	var repair := Vector2(1130.0, 365.0)
	draw_circle(repair, 24.0, Color(0.1, 0.35, 0.23, 0.75))
	draw_line(repair + Vector2(-11, 0), repair + Vector2(11, 0), Color("73ffad"), 7.0)
	draw_line(repair + Vector2(0, -11), repair + Vector2(0, 11), Color("73ffad"), 7.0)


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
