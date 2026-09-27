class_name TitleScreen
extends Control
## Главное меню: пустая детская ночью. Светится только монитор — на нём Пиксель, он следит за курсором.
## При первом показе кинескоп «включается», логотип набирается по буквам, меню выезжает слева.
## Живые мелочи: свет монитора дрожит, в луче пыль, на башне в окне мигает огонёк, по стене проезжают фары.

const SCR := Rect2(292, 90, 116, 82)       # экран монитора на картинке title_room
const FACE_POS := Vector2(318, 99)
static var intro_done := false             # «включение» только один раз за запуск

var items: Array = []                      # [[текст, Callable, enabled]]
var bg: TextureRect
var screen: ColorRect
var face: TextureRect
var logo: Label
var logo_sh: Label
var logo_r: Label
var logo_c: Label
var cursor_l: Label
var tower: ColorRect
var car: Polygon2D
var menu: VBoxContainer
var dust: Array = []
var _t := 0.0
var _glitch_at := 5.0
var _car_at := 6.0
var _crumb := 0.0
var _ready_ui := false

func build(list: Array) -> void:
	items = list
	size = Vector2(480, 270)
	mouse_filter = Control.MOUSE_FILTER_PASS
	bg = TextureRect.new()
	bg.texture = UI.tex("title_room")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	tower = _rect(Vector2(116, 98), Vector2(1, 1), UI.ALARM)
	car = Polygon2D.new()
	car.polygon = PackedVector2Array([Vector2(0, 0), Vector2(46, 0), Vector2(70, 70), Vector2(20, 70)])
	car.color = Color(UI.AMBER2, 0.05)
	car.position = Vector2(-120, -10)
	add_child(car)
	screen = _rect(SCR.position, SCR.size, Color("#16263a"))
	face = TextureRect.new()
	face.texture = UI.tex(_face_tex())
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.size = Vector2(64, 64)
	face.position = FACE_POS
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(face)
	for y in range(int(SCR.position.y), int(SCR.end.y), 2):   # строки кинескопа
		_rect(Vector2(SCR.position.x, y), Vector2(SCR.size.x, 1), Color(0, 0, 0, 0.18))
	for i in 16:   # пыль в луче монитора
		var d := _rect(Vector2(randf_range(270, 440), randf_range(100, 250)), Vector2(1, 1), Color(UI.PAPER, 0.0))
		dust.append([d, randf_range(2.0, 6.0), randf_range(0, 6.28)])
	# панель меню слева: затемнение к краю
	var shade := TextureRect.new()
	var gt := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(0, 0, 0, 0.82))
	gr.set_color(1, Color(0, 0, 0, 0.0))
	gt.gradient = gr
	gt.width = 230
	gt.height = 4
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.size = Vector2(230, 270)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	# логотип: тень, красный/голубой сдвиг при сбое, мигающий курсор
	logo_sh = _logo(Color("#4a1f22"), Vector2(18, 20))
	logo_r = _logo(Color(UI.ALARM, 0.8), Vector2(18, 18))
	logo_c = _logo(Color("#6fb6c9", 0.8), Vector2(14, 18))
	logo = _logo(UI.PAPER, Vector2(16, 18))
	logo_r.visible = false
	logo_c.visible = false
	cursor_l = UI.label("_", UI.AMBER2, UI.logo, 24)
	cursor_l.position = Vector2(16 + logo.get_combined_minimum_size().x + 2, 18)
	add_child(cursor_l)
	var line := _rect(Vector2(18, 50), Vector2(0, 1), Color(UI.AMBER, 0.6))
	# меню
	menu = UI.vbox(2)
	menu.position = Vector2(20, 132)
	menu.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(menu)
	for it in items:
		menu.add_child(_item(it[0], it[1], it[2]))
	var ver := UI.label(G.L.ui.ver, Color(UI.GREY2, 0.6))
	ver.position = Vector2(452, 260)
	add_child(ver)
	_intro(line)

func _rect(p: Vector2, s: Vector2, c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = p
	r.size = s
	r.color = c
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r

func _logo(c: Color, p: Vector2) -> Label:
	var l := UI.label(G.L.title, c, UI.logo, 24)
	l.position = p
	add_child(l)
	return l

func _face_tex() -> String:
	return "pix_2" if not G.meta.endings.is_empty() else "pix_0"

## Пункт меню: тусклый; выбранный — янтарный, сдвигается вправо, слева мигает квадратик.
func _item(text: String, cb: Callable, enabled: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", UI.tiny)
	b.add_theme_font_size_override("font_size", 16)
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(s, StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", UI.GREY3)
	b.add_theme_color_override("font_hover_color", UI.AMBER2)
	b.add_theme_color_override("font_focus_color", UI.AMBER2)
	b.add_theme_color_override("font_pressed_color", UI.PAPER)
	b.add_theme_color_override("font_disabled_color", Color(UI.GREY, 0.8))
	b.disabled = not enabled
	b.custom_minimum_size = Vector2(170, 17)
	var mark := ColorRect.new()
	mark.color = UI.AMBER2
	mark.size = Vector2(4, 4)
	mark.position = Vector2(-9, 7)
	mark.visible = false
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(mark)
	b.set_meta("mark", mark)
	b.mouse_entered.connect(func(): if not b.disabled: b.grab_focus())
	b.focus_entered.connect(func():
		mark.visible = true
		Sfx.play("tick0", -14.0)
		var tw := b.create_tween()
		tw.tween_property(b, "position:x", 6.0, 0.12))
	b.focus_exited.connect(func():
		mark.visible = false
		var tw := b.create_tween()
		tw.tween_property(b, "position:x", 0.0, 0.12))
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	return b

# ---------------------------------------------------------------- «включение»
func _intro(line: ColorRect) -> void:
	var quick := (intro_done or G.TEST) and not OS.get_cmdline_user_args().has("--intro")
	intro_done = true
	menu.modulate.a = 0.0
	menu.position.x = -40
	for l in [logo, logo_sh, cursor_l]:
		l.modulate.a = 0.0
	face.modulate.a = 0.0
	screen.color = Color("#050608")
	if not quick:
		# кинескоп: вспыхивает полоска посередине и раскрывается в экран
		await get_tree().create_timer(0.5, false).timeout
		var beam := _rect(Vector2(SCR.position.x, SCR.get_center().y), Vector2(SCR.size.x, 1), Color(0.9, 0.95, 1.0))
		Sfx.play("glitch", -12.0)
		var tw := create_tween()
		tw.tween_property(beam, "position:y", SCR.position.y, 0.22)
		tw.parallel().tween_property(beam, "size:y", SCR.size.y, 0.22)
		tw.tween_property(beam, "color:a", 0.0, 0.35)
		await tw.finished
		beam.queue_free()
	screen.color = Color("#16263a")
	var tw2 := create_tween()
	tw2.tween_property(face, "modulate:a", 1.0, 0.1 if quick else 0.6)
	if not quick:
		await get_tree().create_timer(0.5, false).timeout
		# логотип набирается по буквам
		var full: String = G.L.title
		logo.modulate.a = 1.0
		logo_sh.modulate.a = 1.0
		for i in range(1, full.length() + 1):
			logo.text = full.substr(0, i)
			logo_sh.text = logo.text
			Sfx.play("key", -10.0)
			await get_tree().create_timer(0.09, false).timeout
	logo.modulate.a = 1.0
	logo_sh.modulate.a = 1.0
	cursor_l.modulate.a = 1.0
	var tw3 := create_tween()
	tw3.tween_property(line, "size:x", 150.0, 0.1 if quick else 0.5)
	tw3.parallel().tween_property(menu, "modulate:a", 1.0, 0.1 if quick else 0.5)
	tw3.parallel().tween_property(menu, "position:x", 20.0, 0.1 if quick else 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw3.finished
	_ready_ui = true
	focus_first()

func focus_first() -> void:
	for b in menu.get_children():
		if b is Button and not b.disabled:
			b.call_deferred("grab_focus")
			return

# ---------------------------------------------------------------- жизнь сцены
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	# свет монитора дрожит
	var fl := 0.94 + 0.04 * sin(_t * 7.3) + 0.02 * sin(_t * 23.0)
	bg.modulate = Color(fl, fl, fl)
	screen.modulate = Color(fl, fl, fl)
	# огонёк на башне
	tower.color.a = 1.0 if fmod(_t, 1.6) < 0.5 else 0.15
	# пыль
	for d in dust:
		var r: ColorRect = d[0]
		r.position.y -= delta * d[1]
		r.position.x += sin(_t * 0.7 + d[2]) * delta * 2.0
		if r.position.y < 95:
			r.position = Vector2(randf_range(270, 440), 250)
		var inside := absf(r.position.x - 350) < (r.position.y - 170) * 0.9 + 60
		r.color.a = (0.25 + 0.2 * sin(_t * 2.0 + d[2])) if inside else 0.05
	# фары машины по стене
	if _t >= _car_at:
		car.position.x += delta * 170.0
		if car.position.x > 520:
			car.position.x = -120
			_car_at = _t + randf_range(9.0, 16.0)
	# Пиксель следит за курсором (на 1–2 пикселя), иногда сбоит
	var m := get_global_mouse_position()
	var off := ((m - (FACE_POS + Vector2(32, 32))) / 90.0).clamp(Vector2(-2, -2), Vector2(2, 2)).round()
	if _t >= _glitch_at:
		face.texture = UI.tex("pix_3")
		face.position = FACE_POS + Vector2(randi_range(-3, 3), 0)
		logo_r.visible = true
		logo_c.visible = true
		if _t >= _glitch_at + 0.14:
			face.texture = UI.tex(_face_tex())
			logo_r.visible = false
			logo_c.visible = false
			_glitch_at = _t + randf_range(4.0, 9.0)
	else:
		face.position = FACE_POS + off
	cursor_l.visible = fmod(_t, 1.0) < 0.55
	# с последней буквы логотипа осыпаются пиксели
	_crumb -= delta
	if _crumb <= 0 and logo.modulate.a > 0.9:
		_crumb = randf_range(0.25, 0.6)
		var px := _rect(Vector2(16 + logo.get_combined_minimum_size().x - randf_range(2, 10), 18 + randf_range(2, 22)), Vector2(2, 2), UI.PAPER)
		var tw := px.create_tween()
		tw.tween_property(px, "position", px.position + Vector2(randf_range(8, 30), randf_range(4, 26)), 2.0)
		tw.parallel().tween_property(px, "color:a", 0.0, 2.0)
		tw.tween_callback(px.queue_free)
