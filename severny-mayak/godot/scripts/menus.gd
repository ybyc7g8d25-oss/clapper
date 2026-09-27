class_name Menus
extends CanvasLayer
## Всё поверх игры: предупреждение, титульный экран, настройки, пауза, заставка ночи (газета),
## отчёт ночи, финалы, всплывашки, баннер визита, скример, «монитор выключен».

signal new_game_requested
signal continue_requested
signal retry_requested

var root: Control
var title: Control
var panel: Control
var pause: Control
var card: Control
var end_o: Control
var warn: Control
var black: ColorRect
var toast_l: PanelContainer
var visit_box: PanelContainer
var visit_l: Label
var monitor: ColorRect
var scare_o: Control
var _face: TextureRect          # лицо Пикселя на мониторе заставки
var _cursor_l: Label
var _glitch_at := 0.0

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.size = Vector2(480, 270)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	monitor = ColorRect.new()
	monitor.color = UI.BLACK
	monitor.position = Vector2(0, Desk.TOP)
	monitor.size = Vector2(480, Desk.BOTTOM - Desk.TOP)
	monitor.visible = false
	root.add_child(monitor)
	visit_box = PanelContainer.new()
	visit_box.position = Vector2(150, 16)
	visit_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visit_box.visible = false
	visit_l = UI.label("", UI.PAPER)
	visit_box.add_child(visit_l)
	root.add_child(visit_box)
	black = ColorRect.new()
	black.color = UI.BLACK
	black.size = Vector2(480, 270)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.modulate.a = 0
	root.add_child(black)
	card = _overlay()
	title = _overlay()
	end_o = _overlay()
	pause = _overlay(Color(UI.BLACK, 0.85))
	panel = _overlay(Color(UI.BLACK, 0.92))
	warn = _overlay()
	scare_o = _overlay()
	toast_l = PanelContainer.new()
	toast_l.add_theme_stylebox_override("panel", UI.flat(UI.DARK, UI.AMBER, 1, 4, 2))
	toast_l.position = Vector2(170, 16)
	toast_l.modulate.a = 0
	toast_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast_l)

func _overlay(bg := UI.BLACK) -> Control:
	var c := ColorRect.new()
	c.color = bg
	c.size = Vector2(480, 270)
	c.visible = false
	root.add_child(c)
	return c

func _clear(c: Control) -> void:
	for ch in c.get_children():
		ch.queue_free()

func _show(c: Control, t := 0.3) -> void:
	c.visible = true
	c.modulate.a = 0
	create_tween().tween_property(c, "modulate:a", 1.0, t)

func _hide(c: Control, t := 0.3) -> void:
	var tw := create_tween()
	tw.tween_property(c, "modulate:a", 0.0, t)
	tw.tween_callback(func(): c.visible = false)

func hide_overlays() -> void:
	for c in [title, end_o, pause, panel, warn, card]:
		c.visible = false
	monitor.visible = false

func _col(parent: Control, x: float, y: float, w: float, sep := 4, center := false) -> VBoxContainer:
	var v := UI.vbox(sep)
	v.position = Vector2(x, y)
	v.custom_minimum_size = Vector2(w, 0)
	v.size = Vector2(w, 0)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	if center:
		v.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(v)
	return v

func _big(text: String, c := UI.PAPER) -> Label:
	return UI.label(text, c, UI.tiny, 16)

## Пункт меню: крупный текст, при наведении — стрелка и янтарный цвет.
func item(text: String, cb: Callable, enabled := true) -> Button:
	var b := Button.new()
	b.text = "  " + text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", UI.tiny)
	b.add_theme_font_size_override("font_size", 16)
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(s, StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", UI.LIGHT)
	b.add_theme_color_override("font_hover_color", UI.AMBER2)
	b.add_theme_color_override("font_focus_color", UI.AMBER2)
	b.add_theme_color_override("font_pressed_color", UI.AMBER)
	b.add_theme_color_override("font_disabled_color", UI.GREY)
	b.disabled = not enabled
	b.mouse_entered.connect(func(): if not b.disabled: b.grab_focus())
	b.focus_entered.connect(func(): b.text = "> " + text)
	b.focus_exited.connect(func(): b.text = "  " + text)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	return b

# ---------------------------------------------------------------- предупреждение
func show_warn(then: Callable) -> void:
	_clear(warn)
	var v := _col(warn, 90, 90, 300, 8)
	v.add_child(UI.label(G.L.ui.warnTitle, UI.RED2, UI.logo, 8))
	v.add_child(UI.label(G.L.ui.warnText, UI.LIGHT, null, 8, 300))
	var b := item(G.L.ui.warnOk, func():
		G.settings.warned = true
		G.save_settings()
		_hide(warn)
		then.call())
	v.add_child(b)
	_show(warn)
	b.call_deferred("grab_focus")

# ---------------------------------------------------------------- титульный экран
func show_title() -> void:
	Sfx.music("title")
	_clear(title)
	# пустая детская ночью; светится только монитор — на нём Пиксель
	var bg := TextureRect.new()
	bg.texture = UI.tex("title_room")
	title.add_child(bg)
	var scr := ColorRect.new()
	scr.color = Color("#16263a")
	scr.position = Vector2(292, 90)
	scr.size = Vector2(116, 82)
	title.add_child(scr)
	_face = TextureRect.new()
	_face.texture = UI.tex(_face_tex())
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.size = Vector2(64, 64)
	_face.position = Vector2(318, 99)
	title.add_child(_face)
	for y in range(90, 172, 2):   # строки кинескопа
		var ln := ColorRect.new()
		ln.color = Color(0, 0, 0, 0.18)
		ln.position = Vector2(292, y)
		ln.size = Vector2(116, 1)
		title.add_child(ln)
	var t := UI.label(G.L.title, UI.PAPER, UI.logo, 24)
	t.position = Vector2(16, 18)
	t.add_theme_color_override("font_shadow_color", UI.BLACK)
	t.add_theme_constant_override("shadow_offset_x", 2)
	t.add_theme_constant_override("shadow_offset_y", 2)
	title.add_child(t)
	_cursor_l = UI.label("_", UI.AMBER2, UI.logo, 24)
	_cursor_l.position = Vector2(16 + t.get_combined_minimum_size().x + 2, 18)
	title.add_child(_cursor_l)
	_glitch_at = Time.get_ticks_msec() / 1000.0 + 3.0
	var v := _col(title, 14, 150, 180, 0)
	var has_save := G.has_save()
	var c := item(G.L.ui.cont, func():
		_hide(title)
		continue_requested.emit(), has_save)
	v.add_child(c)
	v.add_child(item(G.L.ui.newGame, func():
		if has_save:
			confirm(G.L.ui.confirmNew, func():
				_hide(title)
				new_game_requested.emit())
		else:
			_hide(title)
			new_game_requested.emit()))
	v.add_child(item(G.L.ui.settings, func(): open_panel("settings")))
	v.add_child(item(G.L.ui.endings, func(): open_panel("endings")))
	v.add_child(item(G.L.ui.credits, func(): open_panel("credits")))
	v.add_child(item(G.L.ui.quit, func(): get_tree().quit()))
	var ver := UI.label(G.L.ui.ver, UI.GREY)
	ver.position = Vector2(450, 259)
	title.add_child(ver)
	_show(title, 0.8)
	(c if has_save else v.get_child(1)).call_deferred("grab_focus")

func _process(_d: float) -> void:
	_update_point()
	if title.visible and _face and is_instance_valid(_face):
		var t := Time.get_ticks_msec() / 1000.0
		_cursor_l.visible = fmod(t, 1.0) < 0.55
		_face.modulate.a = 0.92 + 0.08 * sin(t * 9.0)
		# иногда лицо сбоит: на миг — тёмное, со сдвигом
		if t >= _glitch_at:
			_face.texture = UI.tex("pix_3")
			_face.position = Vector2(318 + randi_range(-3, 3), 99)
			if t >= _glitch_at + 0.14:
				_face.texture = UI.tex(_face_tex())
				_face.position = Vector2(318, 99)
				_glitch_at = t + randf_range(3.5, 8.0)

## После первого пройденного финала Пиксель на заставке уже не улыбается.
func _face_tex() -> String:
	return "pix_2" if not G.meta.endings.is_empty() else "pix_0"

# ---------------------------------------------------------------- панели
func open_panel(kind: String, in_game := false) -> void:
	_clear(panel)
	var v := _col(panel, 100, 24, 280, 3)
	match kind:
		"settings": _settings(v, in_game)
		"endings": _endings(v)
		"credits": v.add_child(UI.label(G.L.credits, UI.LIGHT, null, 8, 280))
	var back := item(G.L.ui.back, func(): _hide(panel, 0.15))
	v.add_child(back)
	_show(panel, 0.15)
	back.call_deferred("grab_focus")

func _row(v: VBoxContainer, text: String, ctl: Control) -> void:
	var h := UI.hbox(6)
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	var l := UI.label(text, UI.LIGHT)
	l.custom_minimum_size = Vector2(130, 0)
	h.add_child(l)
	ctl.custom_minimum_size = Vector2(120, 10)
	h.add_child(ctl)
	v.add_child(h)

func _cycle(opts: Array, labels: Array, key: String, after := Callable()) -> Button:
	var b := UI.button(labels[maxi(0, opts.find(G.settings[key]))], func(): pass, "dark")
	b.pressed.connect(func():
		var i := (opts.find(G.settings[key]) + 1) % opts.size()
		G.settings[key] = opts[i]
		G.save_settings()
		b.text = labels[i]
		if after.is_valid():
			after.call())
	return b

func _settings(v: VBoxContainer, in_game: bool) -> void:
	var u = G.L.ui
	v.add_child(UI.label(u.settings.to_upper(), UI.PAPER, UI.logo, 8))
	for pair in [["vol", u.sVol], ["mus", u.sMus], ["amb", u.sAmb]]:
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
	_row(v, u.sText, _cycle(["slow", "normal", "fast", "instant"], [u.tSlow, u.tNormal, u.tFast, u.tInstant], "text"))
	_row(v, u.sFx, _cycle(["full", "low"], [u.fxFull, u.fxLow], "fx", func(): if G.fx: G.fx.set_stage(G.stage(), true)))
	_row(v, u.sScares, _cycle([true, false], [u.on, u.off], "scares"))
	_row(v, u.sFull, _cycle([true, false], [u.on, u.off], "fullscreen", func(): G.main.apply_fullscreen()))
	_row(v, u.sScale, _cycle(["fill", "pixel"], [u.scaleFill, u.scalePixel], "scale", func(): G.main._layout()))
	if not in_game:
		_row(v, u.sLang, _cycle(["ru", "en"], [G.LANGS.ru.langName, G.LANGS.en.langName], "lang", func():
			G.set_lang(G.settings.lang)
			open_panel("settings")
			show_title()))

func _endings(v: VBoxContainer) -> void:
	v.add_child(UI.label(G.L.ui.endings.to_upper(), UI.PAPER, UI.logo, 8))
	for k in ENDS:
		var seen: bool = G.meta.endings.has(k)
		var e = G.L.endings[k]
		v.add_child(UI.label(e.title if seen else G.L.ui.endLocked, UI.AMBER2 if seen else UI.GREY2))
		v.add_child(UI.label(e.text if seen else G.L.endHint[k], UI.GREY3, null, 8, 280))

func confirm(text: String, yes: Callable) -> void:
	_clear(panel)
	var v := _col(panel, 120, 100, 240, 6)
	v.add_child(UI.label(text, UI.LIGHT, null, 8, 240))
	v.add_child(item(G.L.ui.yes, func():
		_hide(panel, 0.15)
		yes.call()))
	var n := item(G.L.ui.no, func(): _hide(panel, 0.15))
	v.add_child(n)
	_show(panel, 0.15)
	n.call_deferred("grab_focus")

# ---------------------------------------------------------------- пауза
func open_pause() -> void:
	if not G.in_game or G.ending != "":
		return
	get_tree().paused = true
	Sfx.duck(true)
	_clear(pause)
	var v := _col(pause, 170, 80, 160, 2)
	v.add_child(UI.label(G.L.ui.paused, UI.PAPER, UI.logo, 8))
	var r := item(G.L.ui.resume, close_pause)
	v.add_child(r)
	v.add_child(item(G.L.ui.help, func(): show_help()))
	v.add_child(item(G.L.ui.settings, func(): open_panel("settings", true)))
	v.add_child(item(G.L.ui.toMenu, func():
		G.save_game()
		close_pause()
		G.main.to_title()))
	v.add_child(item(G.L.ui.quit, func():
		G.save_game()
		get_tree().quit()))
	_show(pause, 0.1)
	r.call_deferred("grab_focus")

func close_pause() -> void:
	panel.visible = false
	_hide(pause, 0.1)
	get_tree().paused = false
	Sfx.duck(false)

func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	if e.keycode == KEY_ESCAPE:
		if panel.visible:
			_hide(panel, 0.1)
		elif pause.visible:
			close_pause()
		elif G.in_game and G.ending == "":
			open_pause()
		get_viewport().set_input_as_handled()
		return
	if not G.in_game or G.ending != "" or get_tree().paused:
		return
	match e.keycode:
		KEY_TAB:
			if not G.stealth.frozen():
				G.board.toggle()
		KEY_Q:
			G.set_lens(not G.lens)
		KEY_D:
			if not G.stealth.frozen():
				G.desk.hide_all()
		KEY_H:
			if not G.stealth.frozen():
				G.house.toggle()
		KEY_W:
			G.hud.set_fast(not G.hud.fast)
		KEY_SPACE, KEY_ENTER:
			G.pix.advance()
		KEY_F11:
			G.settings.fullscreen = not G.settings.fullscreen
			G.save_settings()
			G.main.apply_fullscreen()
	get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- заставка ночи: газета
func night_card(n: int) -> void:
	_clear(card)
	var nt = G.night_info(n)
	var big := UI.label("%s %d" % [G.L.ui.night, n], UI.PAPER, UI.logo, 16)
	big.position = Vector2(24, 22)
	card.add_child(big)
	var d := UI.label(G.date_str(n), UI.GREY3, UI.logo, 8)
	d.position = Vector2(24, 44)
	card.add_child(d)
	var paper := PanelContainer.new()
	var st := StyleBoxTexture.new()
	st.texture = UI.tex("tex_paper")
	st.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	st.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	st.set_content_margin_all(8)
	paper.add_theme_stylebox_override("panel", st)
	paper.position = Vector2(150, 70)
	paper.rotation = -0.03
	var v := UI.vbox(4)
	v.add_child(UI.label(G.L.ui.news, UI.INK2))
	var line := ColorRect.new()
	line.color = UI.INK
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)
	v.add_child(UI.label(String(nt.paper), UI.INK, UI.tiny, 16, 220))
	v.add_child(UI.label(String(nt.paperText), UI.INK, null, 8, 220))
	paper.add_child(v)
	card.add_child(paper)
	var gone := UI.label(G.L.ui.gone + " " + G.L.ui.hours % G.hours_at(n, false), UI.RED2)
	gone.position = Vector2(24, 60)
	card.add_child(gone)
	if G.flag("seize"):
		var sz := UI.label(G.L.day.seizeCard, UI.ALARM, null, 8, 110)
		sz.position = Vector2(24, 80)
		card.add_child(sz)
	_show(card, 0.6)
	Sfx.play("paper")
	var t := 0.0
	var lim := 0.2 if G.TEST else 6.0
	while t < lim:
		await get_tree().create_timer(0.1, false).timeout
		t += 0.1
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and t > 1.0:
			break
	_hide(card, 0.6)
	await get_tree().create_timer(0.05 if G.TEST else 0.6, false).timeout

## Скриншот для автотеста (только с --shots): заставки мелькают слишком быстро, чтобы поймать их снаружи.
func _test_shot(n: String) -> void:
	if not G.TEST or G.shots_dir == "" or DisplayServer.get_name() == "headless":
		return
	await get_tree().create_timer(0.7, false).timeout
	await RenderingServer.frame_post_draw
	G.screen.get_texture().get_image().save_png("%s/%s-card-%s.png" % [G.shots_dir, G.settings.lang, n])

# ---------------------------------------------------------------- заставка дня: протокол
func day_card(d: int, seize := false) -> void:
	_clear(card)
	var dd = G.L.day
	var big := UI.label("%s %d" % [G.L.ui.day, d], UI.PAPER, UI.logo, 16)
	big.position = Vector2(24, 22)
	card.add_child(big)
	var dt := UI.label(G.date_str(d, true) + " · 13:00", UI.GREY3, UI.logo, 8)
	dt.position = Vector2(24, 44)
	card.add_child(dt)
	var gone := UI.label(G.L.ui.gone + " " + G.L.ui.hours % G.hours_at(d, true), UI.RED2)
	gone.position = Vector2(24, 60)
	card.add_child(gone)
	var paper := PanelContainer.new()
	var st := StyleBoxTexture.new()
	st.texture = UI.tex("tex_paper")
	st.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	st.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	st.set_content_margin_all(8)
	paper.add_theme_stylebox_override("panel", st)
	paper.position = Vector2(150, 64)
	paper.rotation = 0.02
	var v := UI.vbox(4)
	v.add_child(UI.label(dd.caseNo, UI.INK2))
	var line := ColorRect.new()
	line.color = UI.INK
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)
	var txt: String = dd.seizeText if seize else String(dd.cards[clampi(d - 1, 0, dd.cards.size() - 1)])
	v.add_child(UI.label(dd.seizeHead if seize else dd.head, UI.INK, UI.tiny, 16, 220))
	v.add_child(UI.label(txt, UI.INK, null, 8, 220))
	v.add_child(UI.label(dd.caseLine % int(G.st.case), UI.BLUE))
	paper.add_child(v)
	card.add_child(paper)
	_show(card, 0.6)
	Sfx.play("paper")
	await _test_shot("daycard%d" % d)
	var t := 0.0
	var lim := 0.2 if G.TEST else 7.0
	while t < lim:
		await get_tree().create_timer(0.1, false).timeout
		t += 0.1
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and t > 1.0:
			break
	_hide(card, 0.6)
	await get_tree().create_timer(0.05 if G.TEST else 0.6, false).timeout

## Итог дня: что скопировали, что не нашли, как продвинулось дело, что думают про Пикселя.
func day_report(d: int, copied: Array, missed: Array) -> void:
	_clear(card)
	var r = G.L.day.report
	var v := _col(card, 110, 30, 260, 3)
	v.add_child(UI.label(r.title % d, UI.PAPER, UI.logo, 8))
	var sep := ColorRect.new()
	sep.color = UI.GREY
	sep.custom_minimum_size = Vector2(260, 1)
	v.add_child(sep)
	if copied.is_empty():
		v.add_child(UI.label(r.none, UI.GREY3))
	for f in copied:
		v.add_child(UI.label(r.copied % [G.docs.file_label(f), int(G.FILES[f][0])], UI.BLUE2, null, 8, 260))
	for f in missed:
		v.add_child(UI.label(r.missed % G.docs.file_label(f), UI.GREEN2, null, 8, 260))
	v.add_child(UI.label(r.field % int(G.day.FIELD), UI.GREY3))
	v.add_child(UI.label(r.case % int(G.st.case), UI.LIGHT))
	var p := float(G.st.pix)
	var vi := 0 if p < 30 else (1 if p < 60 else (2 if p < 100 else 3))
	v.add_child(UI.label(String(r.version[vi]), UI.RED2 if vi >= 2 else UI.GREY3, null, 8, 260))
	v.add_child(UI.label(r.gone % G.hours_at(d, true), UI.RED2))
	var go := [false]
	var nx := item(r.next, func(): go[0] = true)
	v.add_child(nx)
	_show(card, 0.6)
	Sfx.play("paper")
	nx.call_deferred("grab_focus")
	await _test_shot("dayreport%d" % d)
	var t := 0.0
	while not go[0] and t < (0.3 if G.TEST else 600.0):
		await get_tree().create_timer(0.1, false).timeout
		t += 0.1
	_hide(card, 0.4)
	await get_tree().create_timer(0.05 if G.TEST else 0.4, false).timeout

# ---------------------------------------------------------------- отчёт ночи
func report(n: int) -> void:
	_clear(card)
	var r = G.L.report
	var v := _col(card, 120, 50, 240, 4)
	v.add_child(UI.label(r.title % n, UI.PAPER, UI.logo, 8))
	var sep := ColorRect.new()
	sep.color = UI.GREY
	sep.custom_minimum_size = Vector2(240, 1)
	v.add_child(sep)
	v.add_child(UI.label(r.gone % G.hours_gone(), UI.RED2))
	v.add_child(UI.label(r.board % [G.st.solved.size(), G.L.board.sections.size()], UI.LIGHT))
	v.add_child(UI.label(r.memory % int(G.st.mem), UI.PURPLE2))
	v.add_child(UI.label(r.exposure % int(G.st.sus), UI.AMBER2))
	v.add_child(UI.label(r.case % int(G.st.case), UI.BLUE2))
	v.add_child(UI.label(String(r.house[clampi(n - 1, 0, r.house.size() - 1)]), UI.GREY3, null, 8, 240))
	var go := [false]
	var nx := item(r.next, func(): go[0] = true)
	v.add_child(nx)
	_show(card, 0.6)
	Sfx.play("paper")
	nx.call_deferred("grab_focus")
	var t := 0.0
	while not go[0] and t < (0.3 if G.TEST else 600.0):
		await get_tree().create_timer(0.1, false).timeout
		t += 0.1
	_hide(card, 0.4)
	await get_tree().create_timer(0.05 if G.TEST else 0.4, false).timeout

# ---------------------------------------------------------------- финалы
const ENDS := ["a", "t", "b", "c", "p", "s", "x"]

func show_end(k: String) -> void:
	var e = G.L.endings[k]
	var text: String = e.text
	# как нашли Лёву — зависит от того, сколько часов прошло
	if k in ["p", "s", "x"]:
		var h := int(G.st.found_h)
		text += "\n\n" + (String(G.L.leva[G.leva_idx(h)]) if h >= 0 else String(G.L.levaLost))
	_end_screen(e.tag, e.title, text, false)

func show_caught() -> void:
	var c = G.L.caught
	_end_screen(c.tag, c.title, c.text, true)

func _end_screen(tag: String, head: String, text: String, caught: bool) -> void:
	_clear(end_o)
	var v := _col(end_o, 90, 70, 300, 6)
	var n := 0
	for k in ENDS:
		if G.meta.endings.has(k):
			n += 1
	v.add_child(UI.label(tag + ("" if caught else "  %d/%d" % [n, ENDS.size()]), UI.RED2 if caught else UI.AMBER, UI.logo, 8))
	v.add_child(UI.label(head, UI.PAPER, UI.tiny, 16, 300))
	v.add_child(UI.label(text, UI.GREY3, null, 8, 300))
	var first: Button
	if caught:
		first = item(G.L.ui.retry, func():
			_hide(end_o)
			retry_requested.emit())
	else:
		first = item(G.L.ui.credits, func(): open_panel("credits"))
	v.add_child(first)
	v.add_child(item(G.L.ui.again, func():
		_hide(end_o)
		G.main.to_title()))
	_show(end_o, 1.0)
	first.call_deferred("grab_focus")

# ---------------------------------------------------------------- мелочи
func toast(text: String) -> void:
	for c in toast_l.get_children():
		c.queue_free()
	toast_l.add_child(UI.label(text, UI.AMBER2))
	toast_l.reset_size()
	toast_l.position.x = 240 - toast_l.get_combined_minimum_size().x / 2
	var tw := create_tween()
	tw.tween_property(toast_l, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.2)
	tw.tween_property(toast_l, "modulate:a", 0.0, 0.4)

func visit_banner(kind: String, who: String) -> void:
	visit_box.visible = kind != ""
	if kind == "":
		return
	var red := kind == "in"
	var ck = G.L.check
	visit_box.add_theme_stylebox_override("panel", UI.flat(Color(UI.BLACK, 0.9), UI.ALARM if red else (UI.GREEN if kind == "away" else UI.AMBER), 1, 5, 3))
	if kind == "warn" and who == "":
		visit_l.text = String(ck.comingAnon)
	else:
		visit_l.text = String(ck.inRoom if red else (ck.away if kind == "away" else ck.coming)) % who
	visit_l.add_theme_color_override("font_color", UI.RED2 if red else (UI.GREEN2 if kind == "away" else UI.AMBER2))
	visit_box.reset_size()
	visit_box.position.x = 240 - visit_box.get_combined_minimum_size().x / 2

func visit_text(t: String) -> void:
	visit_l.text = t
	visit_box.reset_size()
	visit_box.position.x = 240 - visit_box.get_combined_minimum_size().x / 2

var _gaze: ColorRect
## Полоса «взгляда», проходящая по экрану во время проверки. x < 0 — убрать.
func gaze(x: float) -> void:
	if _gaze == null:
		_gaze = ColorRect.new()
		_gaze.color = Color(UI.AMBER2, 0.14)
		_gaze.size = Vector2(36, Desk.BOTTOM - Desk.TOP)
		_gaze.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var edge := ColorRect.new()
		edge.color = Color(UI.AMBER2, 0.45)
		edge.size = Vector2(1, Desk.BOTTOM - Desk.TOP)
		edge.position = Vector2(35, 0)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_gaze.add_child(edge)
		root.add_child(_gaze)
		root.move_child(_gaze, 0)
	_gaze.visible = x >= 0
	_gaze.position = Vector2(x - 36, Desk.TOP)

## Подсветить найденный след красной рамкой с подписью.
func callout(r: Rect2, text: String) -> void:
	var fr := Panel.new()
	fr.add_theme_stylebox_override("panel", UI.flat(Color(UI.ALARM, 0.12), UI.ALARM, 1, 0, 0))
	fr.position = r.position
	fr.size = r.size
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fr)
	var l := UI.label("?! " + text, UI.PAPER)
	var lp := PanelContainer.new()
	lp.add_theme_stylebox_override("panel", UI.flat(UI.ALARM, UI.ALARM, 0, 2, 0))
	lp.add_child(l)
	lp.position = Vector2(clampf(r.position.x, 2, 380), clampf(r.position.y - 11, 0, 250))
	lp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lp)
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(fr, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(lp, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		fr.queue_free()
		lp.queue_free())

## Субтитр реплики живого человека (днём — телефон Орлова, ночью — папа у камеры).
var _sub: PanelContainer
func subtitle(who: String, text: String, sec := 2.6) -> void:
	if _sub and is_instance_valid(_sub):
		_sub.queue_free()
	_sub = PanelContainer.new()
	_sub.add_theme_stylebox_override("panel", UI.flat(Color(UI.BLACK, 0.88), UI.GREY, 1, 5, 3))
	var l := UI.rich("[color=#e3c983]%s:[/color] %s" % [G.esc(who), G.esc(text)], false)
	l.custom_minimum_size = Vector2(300, 0)
	l.fit_content = true
	l.add_theme_color_override("default_color", UI.LIGHT)
	_sub.add_child(l)
	_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sub.position = Vector2(90, 34)
	root.add_child(_sub)
	var s := _sub
	var tw := s.create_tween()
	tw.tween_interval(sec)
	tw.tween_property(s, "modulate:a", 0.0, 0.4)
	tw.tween_callback(s.queue_free)

# ---------------------------------------------------------------- подсказка «куда нажать»
var _point_key := ""
var _point: Panel

## Мигающая рамка вокруг того, что нужно нажать по текущей цели Пикселя.
func point(key: String) -> void:
	_point_key = key
	if _point == null:
		_point = Panel.new()
		_point.add_theme_stylebox_override("panel", UI.flat(Color(0, 0, 0, 0), UI.AMBER2, 1, 0, 0))
		_point.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(_point)
		root.move_child(_point, 1)

func _point_target() -> Control:
	if not G.in_game or G.ending != "" or not G.desk or not G.hud:
		return null
	var icons := {"note": "note", "clues": "web", "pin": "draw", "night2": "map", "map": "map", "tale": "tale",
		"cipher": "cipher", "guard": "tm", "restore": "bin", "mom": "chat", "lie": "mail"}
	match _point_key:
		"lens": return G.hud.btn_lens
		"board": return G.hud.btn_board
		"wait": return G.hud.btn_wait
	if icons.has(_point_key):
		var ic = G.desk.icon_nodes.get(icons[_point_key])
		if ic and is_instance_valid(ic):
			return ic
	return null

func _update_point() -> void:
	if _point == null:
		return
	var tg := _point_target()
	var hide: bool = tg == null or not tg.is_visible_in_tree() or (G.stealth and G.stealth.phase != "") or panel.visible or card.visible
	_point.visible = not hide and fmod(Time.get_ticks_msec() / 450.0, 2.0) < 1.4
	if not hide:
		_point.position = tg.global_position - Vector2(2, 2)
		_point.size = tg.size + Vector2(4, 4)

# ---------------------------------------------------------------- «Как играть»
func show_help(first_time := false) -> void:
	_clear(panel)
	var h = G.L.help
	var v := _col(panel, 60, 16, 360, 4)
	v.add_child(UI.label(h.title, UI.PAPER, UI.logo, 8))
	for s in h.sections:
		v.add_child(UI.label(String(s[0]), UI.AMBER2))
		v.add_child(UI.label(String(s[1]), UI.LIGHT, null, 8, 360))
	v.add_child(UI.label(h.keys, UI.GREY3, null, 8, 360))
	var go := [false]
	var b := item(h.go if first_time else G.L.ui.back, func():
		go[0] = true
		_hide(panel, 0.15))
	v.add_child(b)
	_show(panel, 0.2)
	b.call_deferred("grab_focus")
	if first_time:
		while not go[0] and panel.visible:
			await get_tree().create_timer(0.1, true).timeout

func visit_flash() -> void:
	var tw := create_tween()
	tw.tween_property(visit_box, "position:x", visit_box.position.x + 4, 0.04)
	tw.tween_property(visit_box, "position:x", visit_box.position.x - 4, 0.04)
	tw.tween_property(visit_box, "position:x", visit_box.position.x, 0.04)

func monitor_off(on: bool) -> void:
	monitor.visible = on
	if on:
		var l := UI.label(G.L.cam.off, UI.GREY)
		l.position = Vector2(200, 80)
		_clear(monitor)
		monitor.add_child(l)
		monitor.mouse_filter = Control.MOUSE_FILTER_STOP

func fade(on: bool) -> void:
	var tw := create_tween()
	tw.tween_property(black, "modulate:a", 1.0 if on else 0.0, 0.1 if G.TEST else 1.0)
	await tw.finished

func scare() -> bool:
	if not G.settings.scares or G.TEST:
		return false
	_clear(scare_o)
	var t := TextureRect.new()
	t.texture = UI.tex("scare")
	t.position = Vector2(144, 39)
	scare_o.add_child(t)
	scare_o.visible = true
	Sfx.play("scare")
	var tw := create_tween()
	tw.tween_interval(0.45)
	tw.tween_callback(func(): scare_o.visible = false)
	return true
