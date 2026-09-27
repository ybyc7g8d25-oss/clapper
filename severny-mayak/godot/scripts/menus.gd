class_name Menus
extends CanvasLayer
## Всё, что поверх рабочего стола: предупреждение, титульный экран, настройки, пауза,
## загрузка, заставки частей, финалы, всплывашки, прятки, скример.

signal new_game_requested
signal continue_requested

var title: Control
var panel: Control
var pause: Control
var boot_o: Control
var card: Control
var black: ColorRect
var end_o: Control
var toast_box: PanelContainer
var visit_o: Control
var visit_box: PanelContainer
var visit_title: Label
var visit_text: Label
var person: TextureRect
var scare_o: Control
var warn: Control
var _beams: Array = []
var _lamp: TextureRect

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("toast")
	_build_visit()
	black = ColorRect.new()
	black.color = Color.BLACK
	UI.full(black)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.modulate.a = 0
	add_child(black)
	boot_o = _overlay()
	card = _overlay()
	title = _overlay()
	end_o = _overlay()
	pause = _overlay(Color(0, 0, 0, 0.82))
	panel = _overlay(Color(0, 0, 0, 0.9))
	warn = _overlay()
	scare_o = _overlay()
	toast_box = PanelContainer.new()
	toast_box.add_theme_stylebox_override("panel", UI.flat(Color("#0d0c14"), UI.MINT, 2, 0, 10))
	toast_box.position = Vector2(300, 12)
	toast_box.custom_minimum_size = Vector2(360, 0)
	toast_box.modulate.a = 0
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_box)

func hide_overlays() -> void:
	for c in [title, end_o, pause, panel, warn]:
		c.visible = false

func _overlay(bg := Color.BLACK) -> Control:
	var c := ColorRect.new()
	c.color = bg
	UI.full(c)
	c.visible = false
	add_child(c)
	return c

func _clear(c: Control) -> void:
	for ch in c.get_children():
		ch.queue_free()

func _show(c: Control, fade := 0.4) -> void:
	c.visible = true
	c.modulate.a = 0
	create_tween().tween_property(c, "modulate:a", 1.0, fade)

func _hide(c: Control, fade := 0.4) -> void:
	var tw := create_tween()
	tw.tween_property(c, "modulate:a", 0.0, fade)
	tw.tween_callback(func(): c.visible = false)

func _center_box(parent: Control, sep := 14) -> VBoxContainer:
	var v := UI.vbox(sep)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	UI.full(v)
	parent.add_child(v)
	return v

func _clabel(text: String, font: Font, size: int, col: Color, wrap_w := 0) -> Label:
	var l := UI.label(text, font, size, col, wrap_w > 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wrap_w > 0:
		l.custom_minimum_size = Vector2(wrap_w, 0)
		l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return l

func _center(c: Control) -> Control:
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return c

# ---------------------------------------------------------------- предупреждение
func show_warn(then: Callable) -> void:
	_clear(warn)
	var v := _center_box(warn, 18)
	v.add_child(_clabel(G.L.ui.warnTitle.to_upper(), UI.pixf, 16, Color("#ff5a4d")))
	v.add_child(_clabel(G.L.ui.warnText, null, 16, Color("#cfd8e3"), 620))
	var b := UI.menu_button(G.L.ui.warnOk, func():
		G.settings.warned = true
		G.save_settings()
		_hide(warn)
		then.call())
	v.add_child(_center(b))
	_show(warn)
	b.call_deferred("grab_focus")

# ---------------------------------------------------------------- титульный экран
func show_title() -> void:
	_clear(title)
	var bg := TextureRect.new()
	bg.texture = UI.tex("title_bg")
	title.add_child(bg)
	# свет маяка и луч
	var lamp_pos := Vector2(480, 166)
	for sgn in [-1, 1]:
		var beam := Polygon2D.new()
		beam.polygon = PackedVector2Array([Vector2(0, -6), Vector2(sgn * 520, -70), Vector2(sgn * 520, 40), Vector2(0, 6)])
		beam.color = Color(1, 0.95, 0.55, 0.13)
		beam.position = lamp_pos
		title.add_child(beam)
		_beams.append(beam)
	_lamp = TextureRect.new()
	_lamp.texture = UI.tex("title_lamp")
	_lamp.position = lamp_pos - Vector2(16, 16)
	title.add_child(_lamp)
	var col := UI.vbox(10)
	col.position = Vector2(48, 60)
	col.size = Vector2(320, 440)
	title.add_child(col)
	var t := UI.shadowed(UI.label(G.L.title.to_upper().replace(" ", "\n"), UI.pixf, 24, Color.WHITE), Color("#3a2f8f"))
	col.add_child(t)
	col.add_child(UI.label(G.L.subtitle, null, 16, Color("#7d8699"), true))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 16)
	col.add_child(sp)
	var has_save := G.has_save()
	var seen: bool = not G.meta.endings.is_empty()
	var bc := UI.menu_button(G.L.ui.cont, func():
		_hide(title)
		continue_requested.emit())
	bc.disabled = not has_save
	col.add_child(bc)
	col.add_child(UI.menu_button(G.L.ui.newGameNg if seen else G.L.ui.newGame, func():
		if has_save:
			confirm(G.L.ui.confirmNew, func():
				_hide(title)
				new_game_requested.emit())
		else:
			_hide(title)
			new_game_requested.emit()))
	col.add_child(UI.menu_button(G.L.ui.settings, func(): open_panel("settings")))
	col.add_child(UI.menu_button(G.L.ui.endings, func(): open_panel("endings")))
	col.add_child(UI.menu_button(G.L.ui.credits, func(): open_panel("credits")))
	col.add_child(UI.menu_button(G.L.ui.quit, func(): get_tree().quit()))
	var hint := UI.label(G.L.ui.hint, null, 16, Color("#5d6479"), true)
	hint.position = Vector2(600, 420)
	hint.size = Vector2(340, 110)
	title.add_child(hint)
	var ver := UI.label("Nimbus Kids · " + G.L.ui.ver, null, 16, Color("#444a5a"))
	ver.position = Vector2(12, 514)
	title.add_child(ver)
	_show(title, 1.0)
	(bc if has_save else col.get_child(4)).call_deferred("grab_focus")

func _process(_d: float) -> void:
	if title.visible and _beams.size():
		var t := Time.get_ticks_msec() / 1000.0
		var k := cos(t * 0.9)
		_beams[0].scale = Vector2(maxf(0.02, k), 1)
		_beams[1].scale = Vector2(maxf(0.02, -k), 1)
		_lamp.modulate.a = 0.75 + 0.25 * sin(t * 3.0)

# ---------------------------------------------------------------- панели: настройки, финалы, титры
func open_panel(kind: String, in_game := false) -> void:
	_clear(panel)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UI.flat(Color("#0d0c14"), Color("#2b2840"), 2, 0, 20))
	box.custom_minimum_size = Vector2(560, 0)
	var v := UI.vbox(10)
	box.add_child(v)
	match kind:
		"settings": _settings(v, in_game)
		"endings": _endings(v)
		"credits": v.add_child(_clabel(G.L.credits, null, 16, Color("#aab"), 520))
	var back := UI.menu_button(G.L.ui.back, func():
		_hide(panel, 0.2)
		if not in_game and not G.in_game and G.ending == "":
			show_title())
	v.add_child(_center(back))
	var cc := CenterContainer.new()
	UI.full(cc)
	cc.add_child(box)
	panel.add_child(cc)
	_show(panel, 0.2)
	back.call_deferred("grab_focus")

func _row(v: VBoxContainer, text: String, ctl: Control) -> void:
	var h := UI.hbox(12)
	var l := UI.label(text, null, 16, Color("#cfd8e3"))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	ctl.custom_minimum_size = Vector2(200, 24)
	h.add_child(ctl)
	v.add_child(h)

func _settings(v: VBoxContainer, in_game: bool) -> void:
	var u = G.L.ui
	v.add_child(_clabel(u.settings.to_upper(), UI.pixf, 16, Color.WHITE))
	for pair in [["vol", u.sVol], ["amb", u.sAmb]]:
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 1
		s.step = 0.05
		s.value = float(G.settings[pair[0]])
		var key: String = pair[0]
		s.value_changed.connect(func(x):
			G.settings[key] = x
			G.save_settings()
			Sfx.apply_volume())
		_row(v, pair[1], s)
	var ts := OptionButton.new()
	var speeds := ["slow", "normal", "fast", "instant"]
	for i in 4:
		ts.add_item([u.tSlow, u.tNormal, u.tFast, u.tInstant][i], i)
	ts.selected = speeds.find(G.settings.text)
	ts.item_selected.connect(func(i):
		G.settings.text = speeds[i]
		G.save_settings())
	_row(v, u.sText, ts)
	var auto := CheckBox.new()
	auto.button_pressed = bool(G.settings.auto)
	auto.toggled.connect(func(on):
		G.settings.auto = on
		G.save_settings())
	_row(v, u.sAuto, auto)
	var fx := OptionButton.new()
	fx.add_item(u.fxFull, 0)
	fx.add_item(u.fxLow, 1)
	fx.selected = 1 if G.settings.fx == "low" else 0
	fx.item_selected.connect(func(i):
		G.settings.fx = "low" if i == 1 else "full"
		G.save_settings()
		if G.fx:
			G.fx.set_stage(G.stage(), true))
	_row(v, u.sFx, fx)
	var sc := CheckBox.new()
	sc.button_pressed = bool(G.settings.scares)
	sc.toggled.connect(func(on):
		G.settings.scares = on
		G.save_settings())
	_row(v, u.sScares, sc)
	var fs := CheckBox.new()
	fs.button_pressed = DisplayServer.window_get_mode() >= DisplayServer.WINDOW_MODE_FULLSCREEN
	fs.toggled.connect(func(on):
		G.settings.fullscreen = on
		G.save_settings()
		G.main.apply_fullscreen())
	_row(v, u.sFull, fs)
	var lg := OptionButton.new()
	var codes := ["ru", "en"]
	for i in 2:
		lg.add_item(G.LANGS[codes[i]].langName, i)
	lg.selected = codes.find(G.settings.lang)
	lg.disabled = in_game
	lg.item_selected.connect(func(i):
		G.set_lang(codes[i])
		open_panel("settings"))
	_row(v, u.sLang, lg)
	v.add_child(UI.label(u.sNote, null, 16, Color("#7d8699"), true))

func _endings(v: VBoxContainer) -> void:
	v.add_child(_clabel(G.L.ui.endings.to_upper(), UI.pixf, 16, Color.WHITE))
	for k in ["a", "t", "b", "c"]:
		var seen: bool = G.meta.endings.has(k)
		var e = G.L.endings[k]
		var pv := UI.vbox(2)
		pv.add_child(UI.label(e.title if seen else G.L.ui.endLocked, UI.head, 16, Color.WHITE if seen else Color("#444a5a")))
		pv.add_child(UI.label(e.text if seen else G.L.endHint[k], null, 16, Color("#8a90a3"), true))
		pv.custom_minimum_size = Vector2(520, 0)
		v.add_child(UI.panel(pv, Color(0, 0, 0, 0), Color("#2b2840"), 2, 8))
	var n := 0
	for k in G.L.ach:
		if G.meta.ach.has(k):
			n += 1
	v.add_child(_clabel("%s: %d / %d" % [G.L.ui.achTitle, n, G.L.ach.size()], null, 16, Color("#7d8699")))

func confirm(text: String, yes: Callable) -> void:
	_clear(panel)
	var v := _center_box(panel, 16)
	v.add_child(_clabel(text, null, 16, Color("#cfd8e3"), 480))
	var h := UI.hbox(12)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var y := UI.menu_button(G.L.ui.yes, func():
		_hide(panel, 0.2)
		yes.call())
	y.custom_minimum_size = Vector2(160, 40)
	var n := UI.menu_button(G.L.ui.no, func(): _hide(panel, 0.2))
	n.custom_minimum_size = Vector2(160, 40)
	h.add_child(y)
	h.add_child(n)
	v.add_child(h)
	_show(panel, 0.2)
	n.call_deferred("grab_focus")

# ---------------------------------------------------------------- пауза
func open_pause(settings_direct := false) -> void:
	if not G.in_game or G.ending != "":
		return
	get_tree().paused = true
	Sfx.duck(true)
	_clear(pause)
	var v := _center_box(pause, 12)
	v.add_child(_clabel(G.L.ui.paused.to_upper(), UI.pixf, 16, Color.WHITE))
	var r := UI.menu_button(G.L.ui.resume, close_pause)
	v.add_child(_center(r))
	v.add_child(_center(UI.menu_button(G.L.ui.settings, func(): open_panel("settings", true))))
	v.add_child(_center(UI.menu_button(G.L.ui.toMenu, func():
		G.save_game()
		close_pause()
		G.main.to_title())))
	v.add_child(_center(UI.menu_button(G.L.ui.quit, func():
		G.save_game()
		get_tree().quit())))
	v.add_child(_clabel(G.L.ui.saved, null, 16, Color("#7d8699")))
	_show(pause, 0.15)
	r.call_deferred("grab_focus")
	if settings_direct:
		open_panel("settings", true)

func close_pause() -> void:
	panel.visible = false
	_hide(pause, 0.15)
	get_tree().paused = false
	Sfx.duck(false)

func pause_open() -> bool:
	return pause.visible

func panel_open() -> bool:
	return panel.visible

# ---------------------------------------------------------------- загрузка и заставки
func boot(lines: Array) -> void:
	_clear(boot_o)
	var v := _center_box(boot_o, 18)
	var logo := UI.hbox(14)
	logo.alignment = BoxContainer.ALIGNMENT_CENTER
	logo.add_child(UI.icon_rect("cloud", 64))
	logo.add_child(UI.label("Nimbus", UI.head, 32, Color.WHITE))
	logo.add_child(UI.label("Kids", UI.head, 16, UI.MINT))
	v.add_child(logo)
	var log_v := UI.vbox(4)
	log_v.custom_minimum_size = Vector2(560, 150)
	v.add_child(_center(log_v))
	_show(boot_o, 0.3)
	for l in lines:
		await get_tree().create_timer(0.04 if G.TEST else 0.65, false).timeout
		log_v.add_child(UI.label(l, null, 16, Color("#aeb8c6")))
		Sfx.play("tick0", -8.0)
	await get_tree().create_timer(0.05 if G.TEST else 0.9, false).timeout
	_hide(boot_o, 0.8)

func part_card(n: int) -> void:
	_clear(card)
	var p = G.L.parts[n - 1]
	var v := _center_box(card, 16)
	v.add_child(_clabel(p.tag, UI.pixf, 16, UI.MINT))
	v.add_child(_clabel(p.name, UI.head, 32, Color.WHITE))
	v.add_child(_clabel(p.time, null, 16, Color("#8890a0")))
	_show(card, 0.8)
	Sfx.play("soft", -6.0)
	await get_tree().create_timer(0.2 if G.TEST else 3.6, false).timeout
	_hide(card, 0.8)
	await get_tree().create_timer(0.05 if G.TEST else 0.8, false).timeout

func fade_black(on: bool) -> void:
	var tw := create_tween()
	tw.tween_property(black, "modulate:a", 1.0 if on else 0.0, 0.1 if G.TEST else 1.2)
	await tw.finished

# ---------------------------------------------------------------- финалы
func show_end(k: String) -> void:
	_end_screen(G.L.endings[k].tag, G.L.endings[k].title, G.L.endings[k].text, false, k in ["b", "c"])

func show_caught(why: String) -> void:
	var c = G.L.caught
	var text: String = c.text
	match why:
		"cam": text = c.textCam
		"dima": text = c.textDima
		"visit": text = c.textVisit
	_end_screen(c.tag, c.title, text, true, true)

func _end_screen(tag: String, head: String, text: String, caught: bool, red: bool) -> void:
	_clear(end_o)
	var found := 0
	for k in ["a", "b", "c", "t"]:
		if G.meta.endings.has(k):
			found += 1
	var v := _center_box(end_o, 16)
	v.add_child(_clabel(tag.to_upper() + ("" if caught else "  %d/4" % found), UI.pixf, 8, Color("#ff5a4d") if red else UI.MINT))
	v.add_child(_clabel(head, UI.head, 32, Color.WHITE, 700))
	v.add_child(_clabel(text, null, 16, Color("#aab"), 600))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 10)
	v.add_child(sp)
	var first: Button
	if caught:
		first = UI.menu_button(G.L.ui.retry, func():
			_hide(end_o)
			continue_requested.emit())
		v.add_child(_center(first))
	else:
		first = UI.menu_button(G.L.ui.credits, func(): open_panel("credits", true))
		v.add_child(_center(first))
	v.add_child(_center(UI.menu_button(G.L.ui.again, func():
		_hide(end_o)
		G.main.to_title())))
	_show(end_o, 1.2)
	first.call_deferred("grab_focus")

# ---------------------------------------------------------------- всплывашка
func toast(head: String, text: String) -> void:
	show_toast(head, text)

func show_toast(head: String, text: String) -> void:
	for c in toast_box.get_children():
		c.queue_free()
	var h := UI.hbox(10)
	h.add_child(UI.label(head.to_upper(), UI.pixf, 8, UI.MINT))
	var l := UI.label(text, null, 16, Color.WHITE, true)
	l.custom_minimum_size = Vector2(240, 0)
	h.add_child(l)
	toast_box.add_child(h)
	toast_box.reset_size()
	toast_box.position.x = 480 - toast_box.get_combined_minimum_size().x / 2
	var tw := create_tween()
	tw.tween_property(toast_box, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.5)
	tw.tween_property(toast_box, "modulate:a", 0.0, 0.5)

# ---------------------------------------------------------------- прятки
func _build_visit() -> void:
	visit_o = Control.new()
	UI.full(visit_o)
	visit_o.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visit_o.visible = false
	add_child(visit_o)
	person = TextureRect.new()
	person.texture = UI.tex("person")
	person.position = Vector2(960 - 180, 0)
	person.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visit_o.add_child(person)
	visit_box = PanelContainer.new()
	visit_box.custom_minimum_size = Vector2(460, 0)
	visit_box.position = Vector2(250, 60)
	visit_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := UI.vbox(6)
	visit_title = _clabel("", UI.pixf, 8, Color("#f2c94c"))
	visit_text = _clabel("", null, 16, Color.WHITE, 430)
	v.add_child(visit_title)
	v.add_child(visit_text)
	visit_box.add_child(v)
	visit_o.add_child(visit_box)

func visit_banner(kind: String, text: String) -> void:
	if kind == "":
		visit_o.visible = false
		return
	visit_o.visible = true
	var red := kind == "in"
	visit_box.add_theme_stylebox_override("panel", UI.flat(Color(0.04, 0.03, 0.06, 0.92), Color("#ff5a4d") if red else Color("#f2c94c"), 2, 0, 12))
	visit_title.add_theme_color_override("font_color", Color("#ff5a4d") if red else Color("#f2c94c"))
	if red:
		visit_title.text = text
		visit_text.text = G.L.visit.freeze
		person.visible = true
		person.modulate.a = 0
		create_tween().tween_property(person, "modulate:a", 1.0, 2.4)
	else:
		visit_title.text = G.L.visit.stepsTitle
		visit_text.text = text
		person.visible = false
	visit_box.reset_size()

func visit_flash(text: String) -> void:
	visit_text.text = text
	var tw := create_tween()
	tw.tween_property(visit_box, "position:x", 262.0, 0.05)
	tw.tween_property(visit_box, "position:x", 240.0, 0.05)
	tw.tween_property(visit_box, "position:x", 250.0, 0.05)

# ---------------------------------------------------------------- скример
func scare() -> bool:
	if not G.settings.scares or G.TEST:
		return false
	_clear(scare_o)
	var t := TextureRect.new()
	t.texture = UI.tex("scare")
	t.position = Vector2(480 - 192, 270 - 192)
	scare_o.add_child(t)
	scare_o.visible = true
	scare_o.modulate.a = 1
	Sfx.play("scare")
	var tw := create_tween()
	t.scale = Vector2(1.3, 1.3)
	t.pivot_offset = Vector2(192, 192)
	tw.tween_property(t, "scale", Vector2.ONE, 0.2)
	tw.tween_interval(0.3)
	tw.tween_callback(func(): scare_o.visible = false)
	return true
