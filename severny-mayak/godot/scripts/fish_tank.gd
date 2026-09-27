class_name FishTank
extends Control
## Аквариум Лёвы: рыбка Капитан. Её никто не кормит — каждую ночь она слабеет (G.st.f.fish, 0..100).
## Кормушка пищит: если кто-то спит в комнате или рядом — это слышно.

const W := 150.0
const H := 70.0
var t := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var hp := float(G.fget("fish", 100))
	var dead := G.flag("fishDead")
	var murky := clampf(1.0 - hp / 100.0, 0.0, 1.0)
	draw_rect(Rect2(0, 0, W, H), Color("#26344a").lerp(Color("#2f3a2a"), murky))
	for i in 7:   # пузырьки
		var x := fmod(i * 23.0 + 11.0, W - 6)
		var y := H - fmod(t * (8.0 + i) + i * 17.0, H)
		if not dead:
			draw_rect(Rect2(floorf(x), floorf(y), 1, 1), Color(UI.PAPER, 0.35))
	draw_rect(Rect2(0, H - 8, W, 8), Color("#8a7a5c"))
	for x in range(4, int(W), 13):   # водоросли
		var h := 10 + (x * 7) % 9
		for y in h:
			draw_rect(Rect2(x + floorf(sin(t * 1.5 + y * 0.4) * 1.2), H - 8 - y, 1, 1), UI.GREEN)
	# рыбка
	var fx: float
	var fy: float
	var dir := 1.0
	if dead:
		fx = W / 2
		fy = 6 + sin(t) * 0.5
	else:
		var sp := 0.25 + hp / 200.0
		fx = W / 2 + sin(t * sp) * (W / 2 - 14)
		fy = H / 2 + sin(t * sp * 1.7) * 10
		dir = 1.0 if cos(t * sp) > 0 else -1.0
	var body := UI.GREY2 if dead else Color("#c9743f").lerp(UI.GREY2, murky * 0.7)
	draw_rect(Rect2(floorf(fx - 5), floorf(fy - 2), 10, 5), body)
	draw_rect(Rect2(floorf(fx - 4), floorf(fy - 3), 8, 1), body)
	draw_rect(Rect2(floorf(fx - 4), floorf(fy + 3), 8, 1), body)
	var tail := fx - 7 * dir
	draw_rect(Rect2(floorf(tail - 1), floorf(fy - 3), 3, 7), body.darkened(0.2))
	var eye := fx + 3 * dir
	if dead:
		draw_line(Vector2(eye - 1, fy - 1), Vector2(eye + 1, fy + 1), UI.INK)
		draw_line(Vector2(eye - 1, fy + 1), Vector2(eye + 1, fy - 1), UI.INK)
	else:
		draw_rect(Rect2(floorf(eye), floorf(fy - 1), 1, 1), UI.INK)
