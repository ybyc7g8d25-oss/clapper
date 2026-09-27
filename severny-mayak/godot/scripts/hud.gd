class_name Hud
extends Control
## Строка статуса (y 72..84): ночь и дата, часы, палево, сколько нет Лёвы, память Пикселя.
## И нижняя полоса кнопок (y 258..270): доска, лупа, спрятать, ждать, меню.

var night_l: Label
var clock_l: Label
var sus_bar: ColorRect
var sus_box: Control
var case_bar: ColorRect
var pix_bar: ColorRect
var gone_l: Label
var mem_l: Label
var btn_board: Button
var btn_lens: Button
var btn_wait: Button
var fast := false
var tray: HBoxContainer

func build() -> void:
	position = Vector2.ZERO
	size = Vector2(480, 270)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# статус
	var bar := ColorRect.new()
	bar.color = UI.BLACK
	bar.position = Vector2(0, 72)
	bar.size = Vector2(480, 12)
	add_child(bar)
	var line := ColorRect.new()
	line.color = UI.DARK3
	line.position = Vector2(0, 83)
	line.size = Vector2(480, 1)
	add_child(line)
	night_l = _lab(4, UI.LIGHT)
	clock_l = _lab(96, UI.AMBER2)
	var sl := _lab(126, UI.GREY3)
	sl.text = G.L.ui.exposure
	sus_box = Control.new()
	sus_box.position = Vector2(160, 76)
	add_child(sus_box)
	var sb_bg := ColorRect.new()
	sb_bg.color = UI.DARK3
	sb_bg.size = Vector2(34, 4)
	sus_box.add_child(sb_bg)
	sus_bar = ColorRect.new()
	sus_bar.color = UI.GREEN2
	sus_bar.size = Vector2(0, 4)
	sus_box.add_child(sus_bar)
	# «Дело»: синяя полоса — как близко следствие к Лёве; красная ниточка под ней — улики против Пикселя
	var cl := _lab(202, UI.GREY3)
	cl.text = G.L.ui.case
	var cb := Control.new()
	cb.position = Vector2(226, 76)
	add_child(cb)
	var cb_bg := ColorRect.new()
	cb_bg.color = UI.DARK3
	cb_bg.size = Vector2(40, 5)
	cb.add_child(cb_bg)
	case_bar = ColorRect.new()
	case_bar.color = UI.BLUE2
	case_bar.size = Vector2(0, 3)
	cb.add_child(case_bar)
	pix_bar = ColorRect.new()
	pix_bar.color = UI.RED2
	pix_bar.position = Vector2(0, 4)
	pix_bar.size = Vector2(0, 1)
	cb.add_child(pix_bar)
	gone_l = _lab(278, UI.RED2)
	mem_l = _lab(390, UI.PURPLE2)
	# кнопки внизу
	var bot := ColorRect.new()
	bot.color = UI.BLACK
	bot.position = Vector2(0, 258)
	bot.size = Vector2(480, 12)
	add_child(bot)
	var h := UI.hbox(3)
	h.position = Vector2(2, 259)
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(h)
	btn_board = _btn(G.L.ui.board + " [Tab]", func(): G.board.toggle())
	btn_lens = _btn(G.L.ui.lens + " [Q]", func(): G.set_lens(not G.lens))
	h.add_child(btn_board)
	h.add_child(btn_lens)
	h.add_child(_btn(G.L.ui.hide + " [D]", func(): G.desk.hide_all()))
	btn_wait = _btn(G.L.ui.wait + " [W]", func(): set_fast(not fast))
	h.add_child(btn_wait)
	var r := UI.hbox(3)
	r.position = Vector2(440, 259)
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(r)
	r.add_child(_btn(G.L.ui.menu, func(): G.menus.open_pause()))
	tray = UI.hbox(1)
	tray.position = Vector2(300, 259)
	tray.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(tray)
	G.lens_changed.connect(func(on): _set_on(btn_lens, on))
	G.desk.changed.connect(render_tray)
	refresh()

## Свёрнутые окна висят значками на нижней панели — их видно тому, кто проверяет компьютер.
func render_tray() -> void:
	for c in tray.get_children():
		c.queue_free()
	for w in G.desk.hidden_windows():
		var b := TextureButton.new()
		var at := AtlasTexture.new()
		at.atlas = UI.tex("icon_" + w.icon_name)
		at.region = Rect2(3, 3, 10, 10)
		b.texture_normal = at
		b.tooltip_text = w.id
		var win: OSWindow = w
		b.pressed.connect(func():
			win.visible = true
			G.desk.focus(win.id))
		tray.add_child(b)

func _lab(x: int, c: Color) -> Label:
	var l := UI.label("", c)
	l.position = Vector2(x, 73)
	add_child(l)
	return l

func _btn(text: String, cb: Callable) -> Button:
	var b := UI.button(text, cb, "dark")
	b.add_theme_stylebox_override("normal", UI.flat(UI.DARK2, UI.DARK3, 1, 3, 0))
	b.add_theme_stylebox_override("hover", UI.flat(UI.DARK3, UI.GREY, 1, 3, 0))
	b.add_theme_stylebox_override("pressed", UI.flat(UI.GREY, UI.GREY3, 1, 3, 0))
	b.custom_minimum_size = Vector2(0, 10)
	return b

func _set_on(b: Button, on: bool) -> void:
	b.add_theme_stylebox_override("normal", UI.flat(UI.AMBER if on else UI.DARK2, UI.AMBER2 if on else UI.DARK3, 1, 3, 0))
	b.add_theme_color_override("font_color", UI.INK if on else UI.LIGHT)

func set_fast(on: bool) -> void:
	fast = on
	_set_on(btn_wait, on)

func refresh() -> void:
	var n: int = int(G.st.night)
	var day := G.is_day()
	night_l.text = "%s %d · %s" % [G.L.ui.day if day else G.L.ui.night, n, G.date_str(n, day)]
	case_bar.size.x = 40.0 * float(G.st.case) / 100.0
	pix_bar.size.x = 40.0 * float(G.st.pix) / 100.0
	clock_l.text = G.clock()
	gone_l.text = "%s %s" % [G.L.ui.gone, G.L.ui.hours % G.hours_gone()]
	mem_l.text = "%s %d%%" % [G.L.ui.memory, int(G.st.mem)]
	var v := float(G.st.sus)
	sus_bar.size.x = 42.0 * v / 100.0
	sus_bar.color = UI.ALARM if v >= 80 else (UI.AMBER if v >= 50 else UI.GREEN2)
