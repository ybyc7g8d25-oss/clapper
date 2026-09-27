class_name Desktop
extends Control
## Рабочий стол Nimbus Kids: обои по слоям, значки, окна, панель задач, меню, часы и «шёпот».

const AREA_H := 500
var wall: Control
var layers := {}
var icons_box: Control
var win_layer: Control
var tasks: HBoxContainer
var clock: Label
var start_menu: PanelContainer
var sus_bar: ColorRect
var sus_box: Control
var frag_btn: Button
var snd_btn: TextureButton
var W := {}                    # id → OSWindow
var icon_nodes := {}           # id → DeskIcon
var DESK := []                 # описание значков (заполняет Apps)
var _casc := 0
var _active := ""

func build() -> void:
	UI.full(self)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_wall()
	icons_box = Control.new()
	icons_box.position = Vector2.ZERO
	icons_box.size = Vector2(960, AREA_H)
	icons_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icons_box)
	win_layer = Control.new()
	win_layer.size = Vector2(960, AREA_H)
	win_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(win_layer)
	_build_taskbar()
	_build_start_menu()
	var t := Timer.new()
	t.wait_time = 60.0
	t.autostart = true
	t.timeout.connect(func():
		if G.in_game and G.ending == "":
			G.st.mins += 1
			show_clock())
	add_child(t)
	var w := Timer.new()
	w.wait_time = 1.0
	w.autostart = true
	w.timeout.connect(_whisper_tick)
	add_child(w)

# ---------------------------------------------------------------- обои
func _layer(n: String, tex: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = UI.tex(tex)
	r.position = Vector2.ZERO
	r.size = Vector2(960, AREA_H)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wall.add_child(r)
	layers[n] = r
	return r

func _build_wall() -> void:
	wall = Control.new()
	wall.size = Vector2(960, AREA_H)
	wall.mouse_filter = Control.MOUSE_FILTER_STOP
	wall.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			get_tree().call_group("desk_icons", "set_selected", false)
			start_menu.visible = false)
	add_child(wall)
	_layer("base", "wall_base")
	_layer("glow", "wall_glow")
	_layer("tower", "wall_tower")
	_layer("lamp", "wall_lamp")
	_layer("boy", "wall_boy")
	var me := UI.label(G.L.art.wallMe, UI.kid, 48, Color("#3a2f8f"))
	me.position = Vector2(236, 420)
	wall.add_child(me)
	layers["me"] = me
	var lives := UI.label(G.L.art.wallLives, UI.kid, 32, Color("#3a2f8f"))
	lives.position = Vector2(470, 52)
	wall.add_child(lives)
	var sc := TextureRect.new()
	sc.texture = UI.tex("wall_scratch")
	sc.position = Vector2(230, 432)
	sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sc.modulate.a = 0
	wall.add_child(sc)
	layers["scratch"] = sc

func set_epilogue_wall() -> void:
	for k in layers:
		layers[k].visible = false
	var r := TextureRect.new()
	r.texture = UI.tex("wall_epilogue")
	r.size = Vector2(960, AREA_H)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wall.add_child(r)
	var us := UI.label(G.L.art.newWall, UI.kid, 64, Color("#3a2f8f"))
	us.position = Vector2(440, 410)
	wall.add_child(us)
	var sub := UI.label(G.L.art.newWallSub, UI.kid, 26, Color("#3a2f8f"))
	sub.position = Vector2(24, 400)
	wall.add_child(sub)

## Стадия мрачности на обоях (плавно).
func set_stage_visual(n: int, instant := false) -> void:
	var d := 0.0 if instant else 3.0
	var tw := create_tween().set_parallel()
	tw.tween_property(layers.boy, "modulate:a", [1.0, 1.0, 0.45, 0.0][n], d)
	tw.tween_property(layers.scratch, "modulate:a", 1.0 if n >= 3 else 0.0, d)
	if n >= 3:
		layers.lamp.texture = UI.tex("wall_lamp_red")
		layers.glow.texture = UI.tex("wall_glow_red")
	else:
		layers.lamp.texture = UI.tex("wall_lamp")
		layers.glow.texture = UI.tex("wall_glow")
	if icon_nodes.has("pixel"):
		icon_nodes.pixel.set_text(G.L.desk.pixelDark if n >= 3 else G.L.desk.pixel)
		icon_nodes.pixel.icon.texture = UI.tex("icon_pixelDark" if n >= 3 else "icon_pixel")

# ---------------------------------------------------------------- значки
func build_icons(list: Array) -> void:
	DESK = list
	for c in icons_box.get_children():
		c.queue_free()
	icon_nodes.clear()
	for d in list:
		if d.has("show") and not d.show.call():
			continue
		_add_icon_node(d)
	_layout_icons()

func _add_icon_node(d: Dictionary) -> DeskIcon:
	var ic := DeskIcon.new()
	ic.setup(d.id, d.ic, d.label.call())
	ic.add_to_group("desk_icons")
	ic.open_requested.connect(func(_id):
		if G.ending == "" and not G.stealth.frozen():
			d.open.call())
	icons_box.add_child(ic)
	icon_nodes[d.id] = ic
	return ic

func _layout_icons() -> void:
	var i := 0
	for d in DESK:
		if not icon_nodes.has(d.id):
			continue
		var n: DeskIcon = icon_nodes[d.id]
		n.position = Vector2(4 + int(i / 6) * 110, 6 + (i % 6) * 80)
		i += 1

func add_icon(id: String) -> void:
	if icon_nodes.has(id):
		return
	for d in DESK:
		if d.id == id:
			var n := _add_icon_node(d)
			_layout_icons()
			n.scale = Vector2(0.2, 0.2)
			n.pivot_offset = n.size / 2
			create_tween().tween_property(n, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)

func remove_icon(id: String) -> void:
	if icon_nodes.has(id):
		icon_nodes[id].queue_free()
		icon_nodes.erase(id)

func hide_icon(id: String) -> void:
	if icon_nodes.has(id):
		icon_nodes[id].visible = false

func visible_icon_ids() -> Array:
	var out := []
	for k in icon_nodes:
		if icon_nodes[k].visible:
			out.append(k)
	return out

# ---------------------------------------------------------------- окна
func win(id: String) -> OSWindow:
	var w = W.get(id)
	return w if w and is_instance_valid(w) else null

## Открыть окно. Если уже открыто — показать. build(body_window) вызывается только для нового.
func open_win(id: String, title: String, icon: String, w: int, h: int, build: Callable = Callable()) -> OSWindow:
	Sfx.play("click")
	var ex := win(id)
	if ex:
		ex.visible = true
		focus(id)
		return ex
	var ww := mini(w, 960 - 12)
	var hh := mini(h, AREA_H - 12)
	var nw := OSWindow.new()
	nw.setup(id, title, icon, ww, hh)
	nw.position = Vector2(clampi(150 + _casc * 26, 8, 960 - ww - 8), clampi(24 + _casc * 22, 4, AREA_H - hh - 4))
	if hh > AREA_H - 60:
		nw.position.y = 4
	_casc = (_casc + 1) % 6
	win_layer.add_child(nw)
	W[id] = nw
	# кнопка на панели задач
	var tb := Button.new()
	tb.toggle_mode = true
	tb.text = title
	tb.icon = UI.tex("icon_" + icon)
	tb.expand_icon = false
	tb.clip_text = true
	tb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tb.custom_minimum_size = Vector2(150, 30)
	tb.add_theme_constant_override("icon_max_width", 16)
	tb.add_theme_color_override("font_color", Color.WHITE)
	tb.add_theme_color_override("font_hover_color", Color.WHITE)
	tb.add_theme_color_override("font_pressed_color", Color.WHITE)
	tb.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	tb.add_theme_color_override("font_focus_color", Color.WHITE)
	tb.add_theme_stylebox_override("normal", UI.flat(Color(1, 1, 1, 0.14), Color(1, 1, 1, 0.35), 2, 0, 6, 2))
	tb.add_theme_stylebox_override("hover", UI.flat(Color(1, 1, 1, 0.24), Color(1, 1, 1, 0.5), 2, 0, 6, 2))
	tb.add_theme_stylebox_override("pressed", UI.flat(Color(0, 0, 0, 0.3), Color(0, 0, 0, 0.4), 2, 0, 6, 2))
	tb.add_theme_stylebox_override("hover_pressed", UI.flat(Color(0, 0, 0, 0.3), Color(0, 0, 0, 0.4), 2, 0, 6, 2))
	tb.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	tb.pressed.connect(func():
		if not nw.visible:
			nw.visible = true
			focus(id)
		elif _active == id:
			nw.minimize()
		else:
			focus(id))
	tasks.add_child(tb)
	nw.task_button = tb
	nw.focused.connect(func(): focus(id))
	nw.closed.connect(func():
		W.erase(id)
		tb.queue_free()
		if _active == id:
			_active = "")
	if build.is_valid():
		build.call(nw)
	focus(id)
	return nw

func focus(id: String) -> void:
	var w := win(id)
	if not w:
		return
	w.move_to_front()
	_active = id
	for k in W:
		var o := win(k)
		if o:
			o.set_active(k == id)
			if o.task_button:
				o.task_button.set_pressed_no_signal(k == id and o.visible)

func close_win(id: String) -> void:
	var w := win(id)
	if w:
		w.close()

func close_all() -> void:
	for k in W.keys():
		close_win(k)
	_casc = 0

func hide_all() -> void:
	for k in W:
		var w := win(k)
		if w:
			w.minimize()
	start_menu.visible = false
	Sfx.play("click")

func visible_windows() -> int:
	var n := 0
	for k in W:
		var w := win(k)
		if w and w.visible:
			n += 1
	return n

## Окно-сообщение.
func alert(title: String, bb: String, icon := "warn") -> OSWindow:
	Sfx.play("err")
	var id := "alert%d" % Time.get_ticks_msec()
	var w := open_win(id, title, icon, 380, 170)
	var box := UI.hbox(12)
	box.add_child(UI.icon_rect(icon, 32))
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var r := UI.rich(bb, true)
	v.add_child(r)
	var row := UI.hbox()
	row.alignment = BoxContainer.ALIGNMENT_END
	var ok := UI.button(G.L.os.ok, func(): close_win(id), "primary")
	ok.custom_minimum_size = Vector2(80, 0)
	row.add_child(ok)
	v.add_child(row)
	box.add_child(v)
	w.set_content(UI.margin(box, 14))
	ok.call_deferred("grab_focus")
	return w

# ---------------------------------------------------------------- панель задач
func _build_taskbar() -> void:
	var bar := Control.new()
	bar.position = Vector2(0, AREA_H)
	bar.size = Vector2(960, 40)
	add_child(bar)
	var bg := TextureRect.new()
	bg.texture = UI.tex("ui_taskbar")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = bar.size
	bar.add_child(bg)
	var sb := TextureButton.new()
	sb.texture_normal = UI.tex("ui_start")
	sb.position = Vector2(0, 0)
	sb.pressed.connect(func():
		Sfx.play("click")
		if G.ending == "" and not G.stealth.frozen():
			start_menu.visible = not start_menu.visible)
	bar.add_child(sb)
	var cl := UI.icon_rect("cloud", 32)
	cl.position = Vector2(6, 4)
	sb.add_child(cl)
	var sl := UI.shadowed(UI.label(G.L.os.start, UI.head, 16, Color.WHITE), Color("#145c3b"))
	sl.position = Vector2(40, 10)
	sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb.add_child(sl)
	var hide := Button.new()
	hide.icon = UI.tex("icon_hide")
	hide.tooltip_text = G.L.ui.hideAll
	hide.position = Vector2(94, 5)
	hide.custom_minimum_size = Vector2(38, 30)
	hide.add_theme_stylebox_override("normal", UI.flat(Color(1, 1, 1, 0.14), Color(1, 1, 1, 0.35), 2, 0, 2))
	hide.add_theme_stylebox_override("hover", UI.flat(Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.5), 2, 0, 2))
	hide.add_theme_stylebox_override("pressed", UI.flat(Color(0, 0, 0, 0.3), Color(1, 1, 1, 0.5), 2, 0, 2))
	hide.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hide.pressed.connect(hide_all)
	bar.add_child(hide)
	tasks = UI.hbox(4)
	tasks.position = Vector2(140, 5)
	tasks.size = Vector2(560, 30)
	tasks.clip_contents = true
	bar.add_child(tasks)
	# трей
	var tray := TextureRect.new()
	tray.texture = UI.tex("ui_tray")
	tray.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tray.stretch_mode = TextureRect.STRETCH_SCALE
	tray.position = Vector2(710, 0)
	tray.size = Vector2(250, 40)
	bar.add_child(tray)
	var th := UI.hbox(10)
	th.position = Vector2(722, 4)
	th.size = Vector2(230, 32)
	th.alignment = BoxContainer.ALIGNMENT_END
	bar.add_child(th)
	sus_box = UI.hbox(4)
	sus_box.tooltip_text = G.L.ui.sus
	sus_box.mouse_filter = Control.MOUSE_FILTER_PASS
	var eye := UI.icon_rect("eye", 16)
	eye.custom_minimum_size = Vector2(16, 32)
	sus_box.add_child(eye)
	var bar_bg := Panel.new()
	bar_bg.custom_minimum_size = Vector2(48, 12)
	bar_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_bg.add_theme_stylebox_override("panel", UI.flat(Color(0, 0, 0, 0.3), Color.WHITE, 2, 0, 0))
	sus_bar = ColorRect.new()
	sus_bar.position = Vector2(2, 2)
	sus_bar.size = Vector2(0, 8)
	sus_bar.color = Color("#8ee6bb")
	bar_bg.add_child(sus_bar)
	sus_box.add_child(bar_bg)
	th.add_child(sus_box)
	frag_btn = Button.new()
	frag_btn.icon = UI.tex("icon_star")
	frag_btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	frag_btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	frag_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	frag_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	frag_btn.add_theme_color_override("font_color", Color.WHITE)
	frag_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	frag_btn.tooltip_text = G.L.ui.shards
	frag_btn.pressed.connect(func(): if G.ending == "": G.apps.open_shards())
	th.add_child(frag_btn)
	snd_btn = TextureButton.new()
	snd_btn.texture_normal = UI.tex("icon_spk")
	snd_btn.custom_minimum_size = Vector2(32, 32)
	snd_btn.ignore_texture_size = true
	snd_btn.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	snd_btn.pressed.connect(func():
		var on := Sfx.toggle()
		snd_btn.texture_normal = UI.tex("icon_spk" if on else "icon_mute"))
	th.add_child(snd_btn)
	clock = UI.label("21:40", null, 16, Color.WHITE)
	clock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	th.add_child(clock)
	update_shards()

func show_clock() -> void:
	clock.text = G.clock_str(int(G.st.mins))

func update_shards() -> void:
	var n: int = G.st.shards.size()
	frag_btn.visible = n > 0
	frag_btn.text = "%d/%d" % [n, G.L.shards.size()]

func set_sus(v: float, active: bool) -> void:
	sus_box.visible = active
	sus_bar.size.x = 44.0 * v / 100.0
	sus_bar.color = Color("#ff5a4d") if v >= 80 else (Color("#f2c94c") if v >= 50 else Color("#8ee6bb"))

# ---------------------------------------------------------------- меню «Меню»
func _build_start_menu() -> void:
	start_menu = PanelContainer.new()
	start_menu.add_theme_stylebox_override("panel", UI.flat(Color.WHITE, UI.GRAPE, 4, 6, 0))
	start_menu.position = Vector2(0, AREA_H - 330)
	start_menu.custom_minimum_size = Vector2(270, 0)
	start_menu.visible = false
	add_child(start_menu)

func fill_start_menu(items: Array) -> void:
	for c in start_menu.get_children():
		c.queue_free()
	var v := UI.vbox(0)
	var head := UI.hbox(10)
	var hp := PanelContainer.new()
	hp.add_theme_stylebox_override("panel", UI.flat(UI.GRAPE, UI.GRAPE, 0, 0, 8))
	head.add_child(UI.icon_rect("pixel", 32))
	head.add_child(UI.shadowed(UI.label(G.L.os.user, UI.head, 16, Color.WHITE)))
	hp.add_child(head)
	v.add_child(hp)
	for it in items:
		if it.is_empty():
			var sep := ColorRect.new()
			sep.color = UI.LINE
			sep.custom_minimum_size = Vector2(0, 2)
			v.add_child(sep)
			continue
		var b := Button.new()
		b.text = it.text
		b.icon = UI.tex("icon_" + it.ic)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_constant_override("h_separation", 10)
		b.add_theme_stylebox_override("normal", UI.flat(Color.WHITE, Color.WHITE, 0, 0, 8, 6))
		b.add_theme_stylebox_override("hover", UI.flat(UI.GRAPE, UI.GRAPE, 0, 0, 8, 6))
		b.add_theme_stylebox_override("pressed", UI.flat(UI.GRAPE_LO, UI.GRAPE, 0, 0, 8, 6))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.pressed.connect(func():
			start_menu.visible = false
			Sfx.play("click")
			it.cb.call())
		v.add_child(b)
	start_menu.add_child(v)
	start_menu.reset_size()
	start_menu.position.y = AREA_H - start_menu.get_combined_minimum_size().y

# ---------------------------------------------------------------- «шёпот»: подписи и часы на миг меняются
func _whisper_tick() -> void:
	if not G.in_game or G.ending != "" or G.stage() < 2:
		return
	if randf() < (0.035 if G.stage() == 2 else 0.08):
		G.fx.glitch()
		var ids := icon_nodes.keys()
		if ids.size():
			var n: DeskIcon = icon_nodes[ids[randi() % ids.size()]]
			var old := n.label.text
			var wl: Array = G.L.whispers
			n.label.text = wl[randi() % wl.size()]
			get_tree().create_timer(0.65).timeout.connect(func(): if is_instance_valid(n): n.label.text = old)
		var o := clock.text
		clock.text = "23:58"
		get_tree().create_timer(0.65).timeout.connect(func(): clock.text = o)
