class_name BoatGame
extends Control
## «Капитан и шторм» — игра, которую Пиксель сделал для Лёвы (побочная).
## ← → (или левая/правая половина окна) — рулить. Доплыть до маяка, не задев скалы.
## В конце игры (стадия 3) свет маяка начинает вести прямо на скалы.

signal finished(lighthouses: int, dark: bool)

const W := 216.0
const H := 150.0
var boat_x := W / 2
var rocks: Array = []           # [x, y, r]
var dist := 0.0
var speed := 34.0
var goal_dist := 420.0
var lighthouses := 0
var running := false
var over := false
var t := 0.0
var steer := 0.0
var _spawn := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL

func start() -> void:
	rocks.clear()
	boat_x = W / 2
	dist = 0.0
	speed = 34.0
	lighthouses = 0
	running = true
	over = false
	grab_focus()

func _dark() -> bool:
	return G.stage() >= 3

func _process(delta: float) -> void:
	t += delta
	if running:
		var dir := 0.0
		if Input.is_key_pressed(KEY_LEFT):
			dir -= 1
		if Input.is_key_pressed(KEY_RIGHT):
			dir += 1
		if dir == 0.0:
			dir = steer
		boat_x = clampf(boat_x + dir * 80.0 * delta, 8, W - 8)
		dist += speed * delta
		_spawn -= delta
		var near_goal := dist > goal_dist - 70
		if _spawn <= 0 and not near_goal:
			_spawn = maxf(0.35, 0.9 - lighthouses * 0.15)
			rocks.append([randf_range(7, W - 7), -10.0, randf_range(4, 8)])
		if _dark() and near_goal and rocks.size() < 30 and randf() < 0.2:
			rocks.append([boat_x + randf_range(-15, 15), -10.0, 7.0])
		for r in rocks:
			r[1] += speed * delta
		rocks = rocks.filter(func(r): return r[1] < H + 15)
		for r in rocks:
			if Vector2(r[0], r[1]).distance_to(Vector2(boat_x, H - 20)) < r[2] + 4:
				_crash()
				break
		if running and dist >= goal_dist:
			lighthouses += 1
			Sfx.play("chime", -8.0)
			dist = 0.0
			speed += 10.0
			rocks.clear()
	queue_redraw()

func _crash() -> void:
	running = false
	over = true
	Sfx.play("err", -4.0)
	G.fx.glitch(0.5)
	finished.emit(lighthouses, _dark())

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		steer = (-1.0 if e.position.x < W / 2 else 1.0) if e.pressed else 0.0
		grab_focus()
		accept_event()

func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(floorf(x), floorf(y), ceilf(w), ceilf(h)), c)

func _draw() -> void:
	var dark := _dark()
	var sea := Color("#141a22") if dark else (Color("#26344a") if G.stage() >= 2 else UI.BLUE)
	draw_rect(Rect2(0, 0, W, H), sea)
	var wave := Color(UI.PAPER, 0.18)
	for i in 12:
		var y := fmod(i * 13.0 + dist * 0.8, H)
		var x := fmod(i * 37.0, W - 14)
		_r(x, y, 6, 1, wave)
		_r(x + 6, y - 1, 3, 1, wave)
	# маяк впереди
	var k := clampf(dist / goal_dist, 0, 1)
	var ly := -30.0 + k * 55.0
	var lamp := UI.ALARM if dark else UI.AMBER2
	var beam := Color(lamp, 0.12 + 0.08 * sin(t * 4.0))
	draw_colored_polygon(PackedVector2Array([Vector2(W / 2, ly + 5), Vector2(W / 2 - 90, ly + 30), Vector2(W / 2 + 90, ly + 30)]), beam)
	_r(W / 2 - 4, ly + 5, 8, 20, UI.PAPER)
	_r(W / 2 - 4, ly + 11, 8, 3, UI.RED)
	_r(W / 2 - 5, ly, 10, 5, UI.DARK3)
	_r(W / 2 - 2, ly + 1, 4, 3, lamp)
	# скалы
	for r in rocks:
		draw_circle(Vector2(floorf(r[0]), floorf(r[1])), r[2], UI.GREY)
		_r(r[0] - r[2] * 0.4, r[1] - r[2] * 0.5, r[2] * 0.6, 2, UI.GREY2)
	# кораблик капитана
	var by := H - 20
	_r(boat_x - 7, by + 3, 14, 4, Color("#6b3f35"))
	_r(boat_x - 5, by + 7, 10, 2, Color("#3a2b28"))
	_r(boat_x, by - 9, 1, 12, UI.INK)
	draw_colored_polygon(PackedVector2Array([Vector2(boat_x + 1, by - 9), Vector2(boat_x + 7, by + 1), Vector2(boat_x + 1, by + 1)]), UI.PAPER)
	draw_string(UI.tiny, Vector2(4, 9), G.L.boat.score % lighthouses, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UI.PAPER)
	if over:
		draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.5))
