class_name BoatGame
extends Control
## «Капитан и шторм» — игра, которую Пиксель сделал для Лёвы.
## Стрелки ← → (или клик по левой/правой половине) — рулить. Доплыть до маяка, не задев скалы.

signal finished(lighthouses: int, dark: bool)

const PX := 2.0
var W := 400.0
var H := 330.0
var boat_x := 200.0
var rocks: Array = []           # [x, y, r]
var dist := 0.0
var speed := 70.0
var goal_dist := 900.0
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
	speed = 70.0
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
		boat_x = clampf(boat_x + dir * 150.0 * delta, 16, W - 16)
		dist += speed * delta
		_spawn -= delta
		var near_goal := dist > goal_dist - 160
		if _spawn <= 0 and not near_goal:
			_spawn = maxf(0.35, 0.9 - lighthouses * 0.15)
			rocks.append([randf_range(14, W - 14), -20.0, randf_range(9, 16)])
		# во тьме свет ведёт прямо на скалы
		if _dark() and near_goal and rocks.size() < 30 and randf() < 0.2:
			rocks.append([boat_x + randf_range(-30, 30), -20.0, 14.0])
		for r in rocks:
			r[1] += speed * delta
		rocks = rocks.filter(func(r): return r[1] < H + 30)
		for r in rocks:
			if Vector2(r[0], r[1]).distance_to(Vector2(boat_x, H - 40)) < r[2] + 9:
				_crash()
				break
		if running and dist >= goal_dist:
			lighthouses += 1
			Sfx.play("chime", -8.0)
			dist = 0.0
			speed += 22.0
			rocks.clear()
	queue_redraw()

func _crash() -> void:
	running = false
	over = true
	Sfx.play("door")
	G.fx.glitch(0.5)
	finished.emit(lighthouses, _dark())

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		steer = (-1.0 if e.position.x < W / 2 else 1.0) if e.pressed else 0.0
		grab_focus()

func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(floor(x / PX) * PX, floor(y / PX) * PX, ceil(w / PX) * PX, ceil(h / PX) * PX), c)

func _draw() -> void:
	var dark := _dark()
	var sea := Color("#0b1a2a") if dark else (Color("#1c3f66") if G.stage() >= 2 else Color("#2f78b8"))
	draw_rect(Rect2(0, 0, W, H), sea)
	# волны
	var wave := Color(1, 1, 1, 0.15)
	for i in 14:
		var y := fmod(i * 26.0 + dist * 0.8, H)
		var x := fmod(i * 67.0, W - 30)
		_r(x, y, 12, 2, wave)
		_r(x + 12, y - 2, 6, 2, wave)
	# маяк впереди
	var k := clampf(dist / goal_dist, 0, 1)
	var ly := -60.0 + k * 110.0
	var lamp := Color("#ff2a2a") if dark else Color("#fff27a")
	var beam := Color(lamp, 0.12 + 0.08 * sin(t * 4.0))
	draw_colored_polygon(PackedVector2Array([Vector2(W / 2, ly + 10), Vector2(W / 2 - 180, ly + 60), Vector2(W / 2 + 180, ly + 60)]), beam)
	_r(W / 2 - 8, ly + 10, 16, 40, Color("#efe9df"))
	_r(W / 2 - 8, ly + 22, 16, 6, Color("#e2574c"))
	_r(W / 2 - 10, ly, 20, 10, Color("#3a3f55"))
	_r(W / 2 - 4, ly + 2, 8, 6, lamp)
	# скалы
	for r in rocks:
		var c := Color("#5a6988")
		draw_circle(Vector2(floor(r[0] / PX) * PX, floor(r[1] / PX) * PX), r[2], c)
		_r(r[0] - r[2] * 0.4, r[1] - r[2] * 0.5, r[2] * 0.6, 4, Color("#8b9bb4"))
	# кораблик капитана
	var by := H - 40
	_r(boat_x - 14, by + 6, 28, 8, Color("#733e39"))
	_r(boat_x - 10, by + 14, 20, 4, Color("#3e2731"))
	_r(boat_x - 1, by - 18, 2, 24, UI.INK)
	draw_colored_polygon(PackedVector2Array([Vector2(boat_x + 1, by - 18), Vector2(boat_x + 14, by + 2), Vector2(boat_x + 1, by + 2)]), Color.WHITE)
	# счёт
	draw_string(UI.mono, Vector2(8, 18), G.L.boat.score % lighthouses, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	if over:
		draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.5))
