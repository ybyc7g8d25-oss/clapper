class_name Apps
extends Node
## Программы на компьютере Лёвы. Каждая функция open_*() открывает окно и при первом открытии запускает реплики.

var D: Desktop
var P: PixelVoice
var CHATS := {}
var chat_sel := "mama"
var choice_shown := false
var mail_box := "inbox"
var mail_sel := ""
var tm_sel := ""

func _init_refs() -> void:
	D = G.desk
	P = G.pix

func L() -> Dictionary:
	return G.L

func say(lines, cb := Callable()) -> void:
	P.say(lines, cb)

func desk_list() -> Array:
	var l = G.L.desk
	return [
		{"id": "note", "ic": "note", "label": func(): return l.note, "open": open_note},
		{"id": "draw", "ic": "folder", "label": func(): return l.draw, "open": open_drawings},
		{"id": "pixel", "ic": "pixel", "label": func(): return l.pixelDark if G.stage() >= 3 else l.pixel, "open": open_log},
		{"id": "web", "ic": "web", "label": func(): return l.web, "open": open_browser},
		{"id": "mail", "ic": "mail", "label": func(): return l.mail, "open": open_mail},
		{"id": "tale", "ic": "tale", "label": func(): return l.tale, "open": open_tale},
		{"id": "diary", "ic": "diary", "label": func(): return l.diary, "open": open_diary},
		{"id": "cam", "ic": "cam", "label": func(): return l.cam, "open": open_cam},
		{"id": "chat", "ic": "chat", "label": func(): return l.chat, "open": open_chat},
		{"id": "bin", "ic": "bin", "label": func(): return l.bin, "open": open_bin},
		{"id": "photos", "ic": "photo", "label": func(): return G.L.photos.folder, "open": open_photos},
		{"id": "flags", "ic": "star", "label": func(): return G.L.flags.title, "open": open_flags},
		{"id": "boat", "ic": "boat", "label": func(): return G.L.boat.title, "open": open_boat},
		{"id": "map", "ic": "web", "label": func(): return G.L.map.title.split(" ")[0], "open": open_map,
			"show": func(): return int(G.st.part) >= 2},
		{"id": "dont", "ic": "noteRed", "label": func(): return l.dont, "open": open_dont,
			"show": func(): return G.flag("dontShown") and not G.flag("dontRead")},
	]

func start_menu_items() -> Array:
	var l = G.L
	return [
		{"text": l.desk.draw, "ic": "folder", "cb": open_drawings},
		{"text": l.desk.pixel, "ic": "pixel", "cb": open_log},
		{"text": l.desk.web, "ic": "web", "cb": open_browser},
		{"text": l.desk.mail, "ic": "mail", "cb": open_mail},
		{"text": l.desk.chat, "ic": "chat", "cb": open_chat},
		{},
		{"text": l.os.taskmgr, "ic": "tm", "cb": open_tm},
		{"text": l.parental.title.split(" — ")[0], "ic": "shield", "cb": open_parental},
		{"text": l.ui.settings, "ic": "gear", "cb": func(): G.menus.open_pause(true)},
		{},
		{"text": l.os.off, "ic": "power", "cb": power_off},
	]

# ---------------------------------------------------------------- общие детали
func paper_rich(bb: String, bg := Color.WHITE, pad := 12) -> PanelContainer:
	var r := UI.rich(bb)
	return UI.panel(r, bg, Color(0, 0, 0, 0), 0, pad)

func strip(items: Array) -> Control:
	var h := UI.hbox(16)
	for s in items:
		h.add_child(UI.label(s, null, 16, Color("#444")))
	return UI.panel(h, Color("#f7f9fc"), Color(0, 0, 0, 0), 0, 3)

func shard_button(i: int) -> Control:
	if G.st.shards.has(i):
		return Control.new()
	var b := TextureButton.new()
	b.texture_normal = UI.tex("shard_0")
	b.texture_hover = UI.tex("shard_1")
	b.tooltip_text = "✦"
	b.pressed.connect(func():
		collect_shard(i)
		b.queue_free())
	var tw := b.create_tween().set_loops()
	tw.tween_property(b, "modulate:a", 0.3, 1.2)
	tw.tween_property(b, "modulate:a", 1.0, 1.2)
	return b

func collect_shard(i: int) -> void:
	if G.st.shards.has(i) or G.ending != "":
		return
	G.st.shards.append(i)
	G.save_game()
	Sfx.play("shard")
	D.update_shards()
	G.menus.toast(G.L.ui.shards, "%d / %d — «%s»" % [G.st.shards.size(), G.L.shards.size(), G.L.shards[i]])
	if G.st.shards.size() == G.L.shards.size():
		G.achieve("SHARDS")
		say(G.L.lines.shardsAll)
	elif not G.flag("shard1"):
		G.set_flag("shard1")
		say(G.L.lines.shardFirst)
	else:
		say(G.L.lines.shard)

func msg_bb(w: String, t: String) -> String:
	var lg = G.L.log
	match w:
		"gap": return "[i][color=#c9372f]%s[/color][/i]\n" % G.esc(t)
		"sys": return "[i][color=#999]%s[/color][/i]\n" % G.esc(t)
		"ghost": return ("[i][color=#c9372f55]%s[/color][/i]\n" % G.esc(t)) if G.st.ng else ""
	var col := "#2b6fd6" if w == "l" else "#5b3fb5"
	return "[color=%s][b]%s:[/b][/color] %s\n" % [col, lg.lev if w == "l" else lg.pix, G.clue(t)]

# ---------------------------------------------------------------- записка мамы
func open_note() -> void:
	D.open_win("note", G.L.note.title, "note", 440, 330, func(w: OSWindow):
		var v := UI.vbox(0)
		v.add_child(strip(G.L.os.menuStrip))
		v.add_child(paper_rich(G.clue(G.L.note.body)))
		w.set_content(v))
	if not G.flag("note"):
		G.set_flag("note")
		G.achieve("NOTE")
		say(G.L.lines.note, func():
			P.goal("find")
			G.stealth.schedule_visit(25.0))

# ---------------------------------------------------------------- рисунки
const DRAW_TEX := ["drawing_me_and_pixel", "drawing_tower", "drawing_family"]

func open_drawings() -> void:
	D.open_win("draw", G.L.drawings.folder, "folder", 440, 230, func(w: OSWindow):
		var g := GridContainer.new()
		g.columns = 3
		g.add_theme_constant_override("h_separation", 12)
		for i in 3:
			var b := Button.new()
			b.custom_minimum_size = Vector2(124, 120)
			b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			b.add_theme_stylebox_override("hover", UI.flat(Color("#efeafd"), UI.GRAPE, 2, 0, 4))
			b.add_theme_stylebox_override("pressed", UI.flat(Color("#efeafd"), UI.GRAPE, 2, 0, 4))
			b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			var v := UI.vbox(4)
			v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var th := TextureRect.new()
			th.texture = UI.tex(DRAW_TEX[i])
			th.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			th.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			th.custom_minimum_size = Vector2(112, 70)
			th.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(th)
			var nl := UI.label(G.L.drawings.names[i], null, 16, UI.INK, true)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(nl)
			b.add_child(v)
			v.position = Vector2(6, 4)
			b.pressed.connect(open_drawing.bind(i))
			g.add_child(b)
		w.set_content(UI.panel(g, Color.WHITE, Color(0, 0, 0, 0), 0, 10)))
	if not G.flag("draw"):
		G.set_flag("draw")
		say(G.L.lines.draw)

func _kid(text: String, pos: Vector2, size := 28, col := Color("#3a2f8f")) -> Label:
	var l := UI.label(text, UI.kid, size, col)
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func open_drawing(i: int) -> void:
	var a = G.L.art
	D.open_win("img%d" % i, G.L.drawings.names[i] + " — " + G.L.os.viewer, "note", 504, 400, func(w: OSWindow):
		var bg := ColorRect.new()
		bg.color = Color("#2b2b33")
		var stage := Control.new()
		stage.mouse_filter = Control.MOUSE_FILTER_PASS
		var tr := TextureRect.new()
		tr.texture = UI.tex(DRAW_TEX[i])
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(tr)
		if i == 0:
			stage.scale = Vector2(0.5, 0.5)
			stage.position = Vector2(8, 60)
			stage.add_child(_kid(a.wallMe, Vector2(236, 420), 48))
			stage.add_child(_kid(a.wallLives, Vector2(470, 52), 32))
		elif i == 1:
			stage.position = Vector2(8, 8)
			stage.add_child(_kid(a.tower, Vector2(24, 296), 30, Color.WHITE))
			var sb := shard_button(0)
			sb.position = Vector2(340, 30)
			stage.add_child(sb)
		else:
			stage.position = Vector2(8, 8)
			stage.add_child(_kid(a.famTitle, Vector2(170, 2), 34))
			stage.add_child(_kid(a.famBday, Vector2(300, 60), 26, Color("#c9372f")))
			for p in [[a.famMom, 50], [a.famDad, 150], [a.famMe, 290], [a.famPix, 370]]:
				stage.add_child(_kid(p[0], Vector2(p[1], 284), 26, Color("#333")))
			var sb := shard_button(5)
			sb.position = Vector2(440, 40)
			stage.add_child(sb)
		bg.add_child(stage)
		w.set_content(bg))
	if i == 0 and G.stage() >= 3 and not G.flag("scare"):
		G.set_flag("scare")
		if G.menus.scare():
			say(G.L.lines.scare)
	if i == 1 and not G.flag("tower"):
		G.set_flag("tower")
		say(G.L.lines.tower)
		G.story.check_part1()
	if i == 2 and not G.flag("family"):
		G.set_flag("family")
		say(G.L.lines.family)

# ---------------------------------------------------------------- журнал бесед
func open_log() -> void:
	D.open_win("pixel", G.L.log.title, "pixel", 480, 400, func(w: OSWindow):
		var bb := ""
		for d in G.L.log.days:
			bb += "[b][color=#667085]%s[/color][/b]\n" % G.esc(d[0])
			for m in d[1]:
				bb += msg_bb(m[0], m[1])
			bb += "\n"
		w.set_content(paper_rich(bb, Color("#f8f9fc"))))
	if not G.flag("mem"):
		G.set_flag("mem")
		say(G.L.lines.mem)
		G.story.check_part1()

# ---------------------------------------------------------------- браузер (секретный режим с PIN)
func open_browser() -> void:
	var w := D.open_win("web", G.L.web.title, "web", 560, 380)
	if w.body.get_child_count() == 0:
		if G.flag("pin"):
			_browser_history(w)
		else:
			_browser_pin(w)
	if not G.flag("pinSeen") and not G.flag("pin"):
		G.set_flag("pinSeen")
		say(G.L.lines.pinFirst, func(): P.goal("pin"))

func _browser_pin(w: OSWindow) -> void:
	var pn = G.L.pin
	var v := UI.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(UI.icon_rect("diary", 48))
	var t := UI.label(pn.locked, null, 16, UI.INK, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var h := UI.label(pn.hint, null, 16, UI.GREY, true)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var row := UI.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var inp := LineEdit.new()
	inp.max_length = 4
	inp.custom_minimum_size = Vector2(90, 0)
	inp.alignment = HORIZONTAL_ALIGNMENT_CENTER
	inp.secret = true
	row.add_child(inp)
	var err := UI.label("", null, 16, UI.ALERT)
	var try_it := func():
		if try_pin(inp.text):
			pass
		else:
			Sfx.play("err")
			G.stealth.add_sus(2, "beep")
			err.text = pn.err
			inp.text = ""
			G.st.f["pinTries"] = int(G.fget("pinTries")) + 1
			if int(G.fget("pinTries")) == 3:
				say(G.L.lines.pinHint)
	row.add_child(UI.button(pn.open, try_it, "primary"))
	inp.text_submitted.connect(func(_t): try_it.call())
	v.add_child(row)
	err.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(err)
	w.set_content(UI.panel(v, Color.WHITE, Color(0, 0, 0, 0), 0, 16))
	inp.call_deferred("grab_focus")

func try_pin(code: String) -> bool:
	if code.strip_edges() != String(G.L.pin.code):
		return false
	Sfx.play("chime")
	G.set_flag("pin")
	G.achieve("PIN")
	var w := D.win("web")
	if w:
		_browser_history(w)
	_after_pin()
	return true

func _browser_history(w: OSWindow) -> void:
	var wb = G.L.web
	var v := UI.vbox(0)
	var addr := UI.hbox(8)
	addr.add_child(UI.label(wb.addr, null, 16, UI.GREY))
	var box := UI.panel(UI.label(wb.url, null, 16, Color("#555")), Color.WHITE, Color("#9aa4b4"), 2, 3)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	addr.add_child(box)
	v.add_child(UI.panel(addr, Color("#f2f4f8"), Color(0, 0, 0, 0), 0, 5))
	v.add_child(UI.panel(UI.label(wb.offline, null, 16, Color("#6b5a1d"), true), Color("#fff6d6"), Color(0, 0, 0, 0), 0, 6))
	var bb := "[table=2]"
	for h in wb.hist:
		var col := "#1a4fa8" if int(h[2]) == 1 else UI.INK.to_html(false)
		bb += "[cell][color=#8890a0]%s  [/color][/cell][cell][color=%s]%s[/color][/cell]" % [h[0], col, G.clue(h[1])]
	bb += "[/table]"
	v.add_child(paper_rich(bb))
	w.set_content(v)

func _after_pin() -> void:
	if G.flag("web"):
		return
	G.set_flag("web")
	await get_tree().create_timer(1.2, false).timeout
	G.story.set_stage(1)
	say(G.L.lines.web, func():
		P.goal("where")
		G.story.mom_police_later())

# ---------------------------------------------------------------- почта
func open_mail() -> void:
	D.open_win("mail", G.L.mail.title, "mail", 640, 430)
	render_mail()
	if not G.flag("mail"):
		G.set_flag("mail")
		say(G.L.lines.mailFirst)

func render_mail() -> void:
	var w := D.win("mail")
	if not w:
		return
	var ml = G.L.mail
	var h := UI.hbox(0)
	var boxes := UI.vbox(2)
	boxes.custom_minimum_size = Vector2(140, 0)
	for k in ml.boxes:
		var n := 0
		for m in ml.letters:
			if m.box == k:
				n += 1
		var b := _list_button("%s (%d)" % [ml.boxes[k], n], k == mail_box)
		b.pressed.connect(func():
			mail_box = k
			mail_sel = ""
			render_mail())
		boxes.add_child(b)
	h.add_child(UI.panel(boxes, Color("#f3f6fb"), Color(0, 0, 0, 0), 0, 4))
	var right := UI.vbox(0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var list := UI.vbox(0)
	for m in ml.letters:
		if m.box != mail_box:
			continue
		var who: String = m.from.split(" <")[0] if m.box == "inbox" else String(m.get("to", ""))
		var subj: String = m.subj if m.subj != "" else ml.none
		var b := _list_button("%s%s — %s" % ["" if G.flag("mail_" + m.id) else "● ", who, subj], m.id == mail_sel)
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.pressed.connect(read_mail.bind(m.id))
		list.add_child(b)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 120)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	right.add_child(UI.panel(sc, Color.WHITE, Color(0, 0, 0, 0), 0, 0))
	var sep := ColorRect.new()
	sep.color = UI.LINE
	sep.custom_minimum_size = Vector2(0, 2)
	right.add_child(sep)
	var reader := UI.vbox(6)
	reader.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var cur = null
	for m in ml.letters:
		if m.id == mail_sel:
			cur = m
	if cur:
		var hd := "[color=#667085][b]%s:[/b] %s\n[b]%s:[/b] %s\n" % [ml.subj, G.esc(cur.subj if cur.subj != "" else ml.none), ml.from, G.esc(cur.from)]
		if cur.has("to"):
			hd += "[b]%s:[/b] %s\n" % [ml.to, G.esc(cur.to)]
		hd += "[b]%s:[/b] %s[/color]\n\n" % [ml.date, cur.date]
		var r := UI.rich(hd + G.clue(cur.body))
		reader.add_child(r)
		if cur.has("shard"):
			reader.add_child(shard_button(int(cur.shard)))
	else:
		reader.add_child(UI.label(ml.pick, null, 16, UI.GREY))
	right.add_child(UI.panel(reader, Color.WHITE, Color(0, 0, 0, 0), 0, 10))
	h.add_child(right)
	w.set_content(h)

func _list_button(text: String, active: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var bg := Color("#dbe5f5") if active else Color(0, 0, 0, 0)
	b.add_theme_stylebox_override("normal", UI.flat(bg, Color(0, 0, 0, 0), 0, 0, 6, 3))
	b.add_theme_stylebox_override("hover", UI.flat(Color("#efeafd"), Color(0, 0, 0, 0), 0, 0, 6, 3))
	b.add_theme_stylebox_override("pressed", UI.flat(Color("#dbe5f5"), Color(0, 0, 0, 0), 0, 0, 6, 3))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

func read_mail(id: String) -> void:
	mail_sel = id
	Sfx.play("click")
	var m = null
	for x in G.L.mail.letters:
		if x.id == id:
			m = x
	if not G.flag("mail_" + id):
		G.set_flag("mail_" + id)
		if m.has("react"):
			say(m.react)
		var all := true
		for x in G.L.mail.letters:
			if not G.flag("mail_" + x.id):
				all = false
		if all:
			G.achieve("MAIL")
		if id == "gran":
			G.story.check_part1()
	render_mail()

# ---------------------------------------------------------------- сказка
func tale_count() -> int:
	return 4 if int(G.st.part) >= 2 else 2

func open_tale() -> void:
	D.open_win("tale", G.L.tale.folder, "folder", 580, 220)
	render_tale()
	if not G.flag("tale"):
		G.set_flag("tale")
		say(G.L.lines.taleFirst)
	if tale_count() == 4 and not G.flag("taleNew"):
		G.set_flag("taleNew")
		say(G.L.lines.taleNew + G.L.lines.cipherAppear)

func render_tale() -> void:
	var w := D.win("tale")
	if not w:
		return
	var g := GridContainer.new()
	g.columns = 5
	for i in tale_count():
		var c = G.L.tale.chapters[i]
		var b := Button.new()
		b.text = c.n
		b.icon = UI.tex("icon_note")
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.custom_minimum_size = Vector2(100, 90)
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", UI.flat(Color("#efeafd"), UI.GRAPE, 2, 0, 4))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.pressed.connect(open_chapter.bind(i))
		g.add_child(b)
	if int(G.st.part) >= 2:
		g.add_child(_cipher_file_button())
	w.set_content(UI.panel(g, Color.WHITE, Color(0, 0, 0, 0), 0, 10))

func _cipher_file_button() -> Button:
	var cb := Button.new()
	cb.text = G.L.cipher.file
	cb.icon = UI.tex("icon_noteRed")
	cb.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cb.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	cb.custom_minimum_size = Vector2(100, 90)
	cb.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	cb.add_theme_stylebox_override("hover", UI.flat(Color("#efeafd"), UI.GRAPE, 2, 0, 4))
	cb.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	cb.pressed.connect(open_cipher)
	return cb

func open_chapter(i: int) -> void:
	var c = G.L.tale.chapters[i]
	D.open_win("ch%d" % i, c.n + " — " + G.L.os.notepad, "note", 500, 400, func(w: OSWindow):
		var v := UI.vbox(8)
		var r := RichTextLabel.new()
		r.bbcode_enabled = true
		r.fit_content = true
		r.scroll_active = false
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.push_font(UI.kid, 30)
		r.push_color(Color("#3a2f8f"))
		r.add_text(c.title + "\n")
		r.pop()
		r.pop()
		for p in c.body:
			if p[0] == "shard":
				continue
			if p[0] == "l":
				r.push_font(UI.kid, 26)
				r.push_color(Color("#2c3a7a"))
				r.append_text(G.clue(p[1]) + "\n")
				r.pop()
				r.pop()
			else:
				r.append_text(G.clue(p[1]) + "\n")
			r.add_text("\n")
		v.add_child(r)
		for p in c.body:
			if p[0] == "shard":
				v.add_child(shard_button(int(p[1])))
		v.add_child(UI.label(c.meta, null, 16, Color("#8a8a8a"), true))
		var sc := ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(v)
		w.set_content(UI.panel(sc, Color("#fbf8ef"), Color(0, 0, 0, 0), 0, 14)))
	if not G.flag("tale%d" % i):
		G.set_flag("tale%d" % i)
		say(c.react)
		G.story.check_part1()
		G.story.check_part2()

# ---------------------------------------------------------------- дневник
func open_diary() -> void:
	var w := D.open_win("diary", G.L.diary.title, "diary", 480, 420)
	if w.body.get_child_count() == 0:
		if G.flag("diary"):
			_diary_text(w)
		else:
			_diary_lock(w)

func _diary_lock(w: OSWindow) -> void:
	var dl = G.L.diary
	var v := UI.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(UI.icon_rect("diary", 48))
	var t := UI.label(dl.locked, UI.head, 16, UI.INK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var h := UI.label(dl.hint, null, 16, UI.GREY)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var row := UI.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var inp := LineEdit.new()
	inp.custom_minimum_size = Vector2(220, 0)
	row.add_child(inp)
	var err := UI.label("", null, 16, UI.ALERT)
	err.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var try_it := func():
		if try_diary(inp.text):
			pass
		else:
			Sfx.play("err")
			G.stealth.add_sus(2, "beep")
			err.text = dl.err
			G.st.f["pwTries"] = int(G.fget("pwTries")) + 1
			if int(G.fget("pwTries")) == 3:
				say(G.L.lines.pwHint)
	row.add_child(UI.button(dl.open, try_it, "primary"))
	inp.text_submitted.connect(func(_t): try_it.call())
	v.add_child(row)
	v.add_child(err)
	w.set_content(UI.panel(v, Color.WHITE, Color(0, 0, 0, 0), 0, 16))
	inp.call_deferred("grab_focus")

func try_diary(text: String) -> bool:
	var val := text.strip_edges().to_lower().replace("ё", "е")
	var ok := false
	for a in G.LANGS.ru.diary.answers + G.LANGS.en.diary.answers:
		if val != "" and val.contains(a):
			ok = true
	if not ok:
		return false
	Sfx.play("chime")
	G.set_flag("diary")
	var w := D.win("diary")
	if w:
		_diary_text(w)
	after_diary()
	return true

func _diary_text(w: OSWindow) -> void:
	var v := UI.vbox(8)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.push_font(UI.kid, 26)
	for e in G.L.diary.entries:
		r.push_color(Color("#b0433a"))
		r.add_text(e[0] + " ")
		r.pop()
		r.push_color(Color("#2c3a7a"))
		r.append_text(G.clue(e[1]) + "\n\n")
		r.pop()
	r.pop()
	v.add_child(r)
	v.add_child(shard_button(4))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	w.set_content(UI.panel(sc, Color("#fffef6"), Color(0, 0, 0, 0), 0, 16))

func after_diary() -> void:
	G.achieve("DIARY")
	G.story.set_stage(2)
	say(G.L.lines.afterDiary, func(): P.goal("part2"))
	G.story.check_part2()
	if await G.sleep(26.0) and not G.flag("dontShown"):
		G.set_flag("dontShown")
		D.add_icon("dont")
		Sfx.play("err")
		G.fx.glitch()
		say(G.L.lines.dontAppear)

# ---------------------------------------------------------------- не_открывай.txt
func open_dont() -> void:
	if G.flag("dontRead"):
		return
	var w := D.open_win("dontw", G.L.dontFile.title, "noteRed", 420, 260)
	var r := UI.rich("")
	w.set_content(UI.panel(r, Color.WHITE, Color(0, 0, 0, 0), 0, 12))
	var txt: String = G.L.dontFile.text
	for ch in txt:
		if not await G.sleep(0.09) or not is_instance_valid(w):
			return
		r.add_text(ch)
		Sfx.play("key")
	if await G.sleep(1.6):
		G.fx.glitch()
		D.close_win("dontw")
		D.remove_icon("dont")
		G.set_flag("dontRead")
		say(G.L.lines.dont)

# ---------------------------------------------------------------- камера
func open_cam() -> void:
	D.open_win("cam", G.L.cam.title, "cam", 488, 336)
	render_cam()
	var key := "cam3" if G.stage() >= 3 else ("cam2" if G.stage() == 2 else "cam0")
	if not G.flag(key):
		G.set_flag(key)
		say(G.L.lines.camDark if G.stage() >= 3 else (G.L.lines.camMom if G.stage() == 2 else G.L.lines.camEmpty))

func render_cam(dad := false) -> void:
	var w := D.win("cam")
	if not w:
		return
	var c = G.L.cam
	var root := ColorRect.new()
	root.color = Color.BLACK
	var room := TextureRect.new()
	room.texture = UI.tex("cam_dad" if dad else "cam_room")
	room.position = Vector2.ZERO
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(room)
	if not dad and G.stage() == 2:
		var mom := TextureRect.new()
		mom.texture = UI.tex("cam_mom")
		mom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(mom)
	if not dad and G.stage() >= 3:
		var dk := TextureRect.new()
		dk.texture = UI.tex("cam_dark")
		dk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(dk)
	var osd := UI.shadowed(UI.label("%s %s" % [c.osd, G.clock_str(int(G.st.mins))], null, 16, Color("#e8e8e8")))
	osd.position = Vector2(10, 6)
	root.add_child(osd)
	var rec := UI.label(c.rec, null, 16, Color("#ff4d4d"))
	rec.position = Vector2(400, 6)
	var tw := rec.create_tween().set_loops()
	tw.tween_property(rec, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(rec, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_EXPO)
	root.add_child(rec)
	if G.stage() == 2 and not dad:
		var led := UI.shadowed(UI.label(c.led, null, 16, Color("#ff8a80")))
		led.position = Vector2(10, 26)
		root.add_child(led)
	var capt: String = c.dad if dad else (c.dark if G.stage() >= 3 else (c.mom if G.stage() == 2 else c.empty))
	var cap := UI.panel(UI.label(capt, null, 16, Color("#dddddd"), true), Color(0, 0, 0, 0.6), Color(0, 0, 0, 0), 0, 6)
	cap.position = Vector2(0, 268)
	cap.custom_minimum_size = Vector2(480, 36)
	root.add_child(cap)
	if G.stage() >= 1 and not dad:
		var sb := shard_button(2)
		sb.position = Vector2(110, 60)
		root.add_child(sb)
	w.set_content(root)

# ---------------------------------------------------------------- корзина
func open_bin() -> void:
	D.open_win("bin", G.L.bin.title, "bin", 520, 230, func(w: OSWindow):
		var bl = G.L.bin
		var v := UI.vbox(2)
		var hd := UI.hbox(8)
		hd.add_child(_cell(bl.name, 240, UI.GREY))
		hd.add_child(_cell(bl.del, 110, UI.GREY))
		v.add_child(UI.panel(hd, Color("#f2f4f8"), Color(0, 0, 0, 0), 0, 4))
		for i in bl.files.size():
			var f = bl.files[i]
			var row := UI.hbox(8)
			row.add_child(UI.icon_rect(f.ic, 16))
			row.add_child(_cell(f.n, 220))
			row.add_child(_cell(f.s, 110))
			var b := UI.button(bl.restore, func(): pass)
			b.pressed.connect(restore.bind(i))
			row.add_child(b)
			v.add_child(UI.margin(row, 4))
		w.set_content(UI.panel(v, Color.WHITE, Color(0, 0, 0, 0), 0, 6)))

func _cell(t: String, wdt: int, col := UI.INK) -> Label:
	var l := UI.label(t, null, 16, col)
	l.custom_minimum_size = Vector2(wdt, 0)
	l.clip_text = true
	return l

func restore(i: int) -> void:
	var bl = G.L.bin
	var f = bl.files[i]
	if not f.has("key"):
		Sfx.play("click")
		say([f.line])
		return
	if G.flag("restored"):
		open_dead_log(false)
		return
	if int(G.st.part) < 3:
		D.alert(bl.lockedTitle, bl.locked, "stop")
		G.fx.glitch()
		G.stealth.add_sus(4, "beep")
		if not G.flag("binTry"):
			G.set_flag("binTry")
			say(G.L.lines.binLocked)
		return
	if not G.flag("guardKilled"):
		D.alert(bl.lockedTitle, bl.lockedGuard, "stop")
		G.fx.glitch()
		G.stealth.add_sus(6, "beep")
		if not G.flag("binGuard"):
			G.set_flag("binGuard")
			say(G.L.lines.binGuard, func(): P.goal("tm"))
		return
	say(G.L.lines.restoreStart)
	open_memfix()

# ---------------------------------------------------------------- восстановление записи (головоломка)
var mem_order: Array = []
var mem_sel := -1

func _mem_chunks() -> Array:
	var rows: Array = G.L.dead.rows
	var times: Array = G.L.dead.times
	var chunks := []
	var i := 0
	while i < rows.size() - 1:
		var part := [i]
		if i + 1 < rows.size() - 1:
			part.append(i + 1)
		chunks.append({"rows": part, "time": times[i]})
		i += 2
	return chunks

func open_memfix() -> void:
	var chunks := _mem_chunks()
	if mem_order.is_empty():
		mem_order = range(chunks.size())
		var rng := RandomNumberGenerator.new()
		rng.seed = 58
		while mem_order == range(chunks.size()):
			for k in range(mem_order.size() - 1, 0, -1):
				var j := rng.randi_range(0, k)
				var tmp = mem_order[k]
				mem_order[k] = mem_order[j]
				mem_order[j] = tmp
	D.open_win("memfix", G.L.mem.title, "pixel", 660, 488)
	render_memfix()
	if not G.flag("memFirst"):
		G.set_flag("memFirst")
		say(G.L.lines.memFirst)

func _corrupt(t: String, k: int) -> String:
	var pos: int = [1, 3, 4][k % 3]
	return t.substr(0, pos) + "?" + t.substr(pos + 1)

func render_memfix() -> void:
	var w := D.win("memfix")
	if not w:
		return
	var chunks := _mem_chunks()
	var v := UI.vbox(4)
	v.add_child(UI.label(G.L.mem.hint, null, 16, UI.GREY, true))
	for pos in mem_order.size():
		var ci: int = mem_order[pos]
		var ch = chunks[ci]
		var bb := "[color=#ff5a4d]%s[/color]  " % _corrupt(ch.time, ci)
		for r in ch.rows:
			var row = G.L.dead.rows[r]
			bb += msg_bb(row[0], row[1]).replace("\n", "  ")
		var r := UI.rich(bb.strip_edges(), true)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.add_theme_color_override("default_color", Color("#d9d3c7"))
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var active := pos == mem_sel
		var b := PanelContainer.new()
		b.add_theme_stylebox_override("panel", UI.flat(Color("#3a1d24") if active else Color("#1a1620"), Color("#ff5a4d") if active else Color("#2b2840"), 2, 0, 6))
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.add_child(r)
		b.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_mem_click(pos))
		v.add_child(b)
	var row2 := UI.hbox(8)
	row2.alignment = BoxContainer.ALIGNMENT_END
	row2.add_child(UI.button(G.L.mem.check, _mem_check, "danger"))
	v.add_child(row2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(v)
	w.set_content(UI.panel(sc, Color("#0b0a0e"), Color(0, 0, 0, 0), 0, 10))

func _mem_click(pos: int) -> void:
	Sfx.play("key")
	if mem_sel == -1:
		mem_sel = pos
	elif mem_sel == pos:
		mem_sel = -1
	else:
		var tmp = mem_order[pos]
		mem_order[pos] = mem_order[mem_sel]
		mem_order[mem_sel] = tmp
		mem_sel = -1
		if randf() < 0.25:
			G.fx.glitch(0.5)
	render_memfix()

func _mem_check() -> void:
	if mem_order == range(mem_order.size()):
		Sfx.play("chime")
		D.close_win("memfix")
		G.set_flag("restored")
		G.achieve("TRUTH")
		open_dead_log(true)
	else:
		Sfx.play("err")
		G.fx.glitch()
		G.stealth.add_sus(3, "beep")
		say(G.L.lines.memWrong)

func open_dead_log(first: bool) -> void:
	var w := D.open_win("dead", G.L.dead.title, "pixel", 500, 440)
	var r := UI.rich("[b][color=#667085]%s[/color][/b]\n\n" % G.L.dead.head)
	r.add_theme_color_override("default_color", Color("#d9d3c7"))
	w.set_content(UI.panel(r, Color("#0b0a0e"), Color(0, 0, 0, 0), 0, 12))
	var rows: Array = G.L.dead.rows
	if not first:
		for row in rows:
			r.append_text(msg_bb(row[0], row[1]).replace("#5b3fb5", "#ff5a4d"))
		return
	for row in rows:
		if not await G.sleep(1.1):
			return
		if not is_instance_valid(r):
			break
		var bb := msg_bb(row[0], row[1]).replace("#5b3fb5", "#ff5a4d")
		if row[0] == "sys":
			bb = "[color=#ff5a4d]%s[/color]\n" % G.esc(row[1])
		r.append_text(bb)
		Sfx.tick()
	G.fx.glitch()
	if await G.sleep(0.9):
		G.story.reveal()

# ---------------------------------------------------------------- диспетчер задач
func guard_visible() -> bool:
	return int(G.st.part) >= 3 and G.stage() >= 2 and not G.flag("guardKilled")

func open_tm() -> void:
	D.open_win("tm", G.L.tm.title, "tm", 520, 360)
	render_tm()
	if not G.flag("tm"):
		G.set_flag("tm")
		say(G.L.lines.tmFirst)
	if guard_visible() and not G.flag("tmGuard"):
		G.set_flag("tmGuard")
		say(G.L.lines.tmGuard + G.L.lines.guardMsg)

func render_tm() -> void:
	var w := D.win("tm")
	if not w:
		return
	var tl = G.L.tm
	var v := UI.vbox(0)
	var hd := UI.hbox(8)
	hd.add_child(_cell(tl.name, 150, UI.GREY))
	hd.add_child(_cell(tl.desc, 220, UI.GREY))
	hd.add_child(_cell(tl.mem, 90, UI.GREY))
	v.add_child(UI.panel(hd, Color("#f2f4f8"), Color(0, 0, 0, 0), 0, 4))
	var procs: Array = tl.procs.duplicate(true)
	for p in procs:
		if p[0] == "PIKSEL.EXE":
			p[2] = [2140, 4870, 9310, 15020][G.stage()]
	if guard_visible():
		procs.append(tl.guard)
	for p in procs:
		var sel: bool = p[0] == tm_sel
		var bad: bool = p[0] == tl.guard[0]
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 26)
		var h := UI.hbox(8)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var col := Color.WHITE if sel else (Color("#b0433a") if bad else UI.INK)
		for c in [[p[0], 150], [p[1], 220], ["%d %s" % [int(p[2]), tl.mb], 90]]:
			var l := _cell(String(c[0]), c[1], col)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(l)
		b.add_child(h)
		h.position = Vector2(4, 4)
		b.add_theme_stylebox_override("normal", UI.flat(UI.GRAPE if sel else Color.WHITE, Color(0, 0, 0, 0), 0, 0, 2))
		b.add_theme_stylebox_override("hover", UI.flat(UI.GRAPE if sel else Color("#efeafd"), Color(0, 0, 0, 0), 0, 0, 2))
		b.add_theme_stylebox_override("pressed", UI.flat(UI.GRAPE, Color(0, 0, 0, 0), 0, 0, 2))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var pname: String = p[0]
		b.pressed.connect(func():
			tm_sel = pname
			Sfx.play("click")
			render_tm())
		v.add_child(b)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var foot := UI.hbox(8)
	foot.add_child(UI.label("%s: %d%%" % [tl.cpu, [12, 37, 71, 99][G.stage()]], null, 16, UI.GREY))
	if G.stage() >= 2:
		foot.add_child(shard_button(6))
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(sp2)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(170, 28)
	var end := UI.button(tl.end, end_process)
	end.name = "End"
	end.position = Vector2(0, 0)
	holder.add_child(end)
	foot.add_child(holder)
	v.add_child(UI.panel(foot, Color("#f7f9fc"), Color(0, 0, 0, 0), 0, 6))
	w.set_content(UI.panel(v, Color.WHITE, Color(0, 0, 0, 0), 0, 0))

func end_process() -> void:
	var tl = G.L.tm
	if tm_sel == "":
		Sfx.play("err")
		return
	if tm_sel == "PIKSEL.EXE":
		D.alert(tl.title, tl.pixErr, "stop")
		G.stealth.add_sus(4, "beep")
		say(G.L.lines.tmPix)
		return
	if tm_sel != tl.guard[0]:
		D.alert(tl.title, G.esc(tl.sysErr), "stop")
		G.stealth.add_sus(4, "beep")
		return
	var n := int(G.fget("guardTries")) + 1
	G.st.f["guardTries"] = n
	if n < 3:
		G.fx.glitch()
		Sfx.play("err")
		tm_sel = ""                  # выделение «само» слетает
		render_tm()
		var w := D.win("tm")
		var end: Control = w.body.find_child("End", true, false)
		if end:
			var tw := end.create_tween()   # кнопка «убегает»
			tw.tween_property(end, "position", Vector2(-80 - randf() * 180, -randf() * 6), 0.12)
		P.reset()
		say(G.L.lines.guard1 if n == 1 else G.L.lines.guard2)
		return
	P.reset()
	say(G.L.lines.guard3, func():
		G.set_flag("guardKilled")
		tm_sel = ""
		render_tm()
		G.achieve("GUARD")
		Sfx.play("door")
		D.alert(tl.title, G.esc(tl.ended), "info")
		say(G.L.lines.guardDone, func(): P.goal("restore")))

# ---------------------------------------------------------------- осколки
func open_shards() -> void:
	D.open_win("shards", G.L.ui.shards, "tale", 480, 380, func(w: OSWindow):
		var bb := ""
		for i in G.L.shards.size():
			bb += (G.esc(G.L.shards[i]) if G.st.shards.has(i) else "[color=#bbbbbb]…[/color]") + "\n\n"
		var v := UI.vbox(6)
		v.add_child(UI.label("%s — %d/%d" % [G.L.ui.shards, G.st.shards.size(), G.L.shards.size()], UI.kid, 30, Color("#3a2f8f")))
		v.add_child(UI.rich(bb))
		w.set_content(UI.panel(v, Color("#fbf8ef"), Color(0, 0, 0, 0), 0, 14)))

# ---------------------------------------------------------------- выключение
func power_off() -> void:
	Sfx.play("err")
	var n := int(G.fget("off")) + 1
	G.st.f["off"] = n
	G.save_game()
	if n == 3:
		G.achieve("OFF")
		say(G.L.lines.offThird)
		return
	say(G.L.lines.offDark if G.stage() >= 3 else G.L.lines.off)

# ---------------------------------------------------------------- мессенджер «Шёпот»
func reset_chats() -> void:
	var p = G.L.chat.people
	CHATS = {
		"mama": {"name": p.mama.name, "on": false, "ms": p.mama.ms.duplicate(true)},
		"dima": {"name": p.dima.name, "on": true, "ms": p.dima.ms.duplicate(true)},
		"papa": {"name": p.papa.name, "on": false, "ms": p.papa.ms.duplicate(true)},
	}
	chat_sel = "mama"
	choice_shown = false
	if G.flag("momPolice"):
		CHATS.mama.ms.append(["06.10 21:58", G.L.chat.momPolice])
	if G.flag("dimaNight"):
		CHATS.dima.ms.append(["07.10 00:41", G.L.chat.dimaNight])

func open_chat() -> void:
	var w := D.open_win("chat", G.L.chat.title, "chat", 600, 420)
	if w.task_button:
		w.task_button.modulate = Color.WHITE
	render_chat()
	if not G.flag("chat") and G.stage() < 3:
		G.set_flag("chat")
		say(G.L.lines.chatFirst)

func render_chat() -> void:
	var w := D.win("chat")
	if not w:
		return
	var cl = G.L.chat
	var c: Dictionary = CHATS[chat_sel]
	var h := UI.hbox(0)
	var contacts := UI.vbox(2)
	contacts.custom_minimum_size = Vector2(130, 0)
	contacts.add_child(UI.label(cl.contacts, null, 16, Color("#6a7a60")))
	for k in CHATS:
		var o: Dictionary = CHATS[k]
		var b := _list_button(("● " if o.on else "○ ") + String(o.name), k == chat_sel)
		b.add_theme_color_override("font_color", UI.INK)
		b.pressed.connect(func():
			chat_sel = k
			render_chat())
		contacts.add_child(b)
	h.add_child(UI.panel(contacts, Color("#f4f7f2"), Color(0, 0, 0, 0), 0, 6))
	var conv := UI.vbox(0)
	conv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hd := UI.hbox(8)
	hd.add_child(UI.label(String(c.name), UI.head, 16, UI.INK))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(sp)
	hd.add_child(UI.label(cl.online if c.on else cl.offline, null, 16, Color("#778899")))
	conv.add_child(UI.panel(hd, Color("#f9fbf8"), Color(0, 0, 0, 0), 0, 6))
	var bb := ""
	for m in c.ms:
		match String(m[0]):
			"me": bb += "[color=#5b3fb5][b]%s:[/b][/color] %s\n" % [cl.me, G.esc(m[1])]
			"lie": bb += "[color=#8a96a8]%s[/color] [color=#2b6fd6][b]%s:[/b][/color] %s\n" % [m[2] if m.size() > 2 else "", cl.lie, G.esc(m[1])]
			"st": bb += "[i][color=#8a96a8]%s[/color][/i]\n" % G.esc(m[1])
			_: bb += "[color=#8a96a8]%s[/color] [color=#b8431f][b]%s:[/b][/color] %s\n" % [m[0], c.name, G.esc(m[1])]
	var r := UI.rich(bb)
	r.scroll_following = true
	conv.add_child(UI.panel(r, Color.WHITE, Color(0, 0, 0, 0), 0, 8))
	var inp := UI.vbox(6)
	if chat_sel == "mama" and G.st.mom_online and G.ending == "" and choice_shown:
		inp.add_child(UI.button(cl.tell, func(): G.story.ending_tell(), "primary"))
		inp.add_child(UI.button(cl.silent, func(): G.story.ending_silent()))
		inp.add_child(UI.button(cl.pretend, func(): G.story.ending_pretend(), "danger"))
	elif G.ending != "":
		pass
	elif chat_sel == "dima" and G.stage() < 3 and not G.flag("dimaAsked"):
		inp.add_child(UI.button(cl.askDima, ask_dima, "danger"))
	else:
		var row := UI.hbox(6)
		var le := LineEdit.new()
		le.editable = false
		le.placeholder_text = cl.disabled
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(le)
		var sb := UI.button(cl.send, func(): pass)
		sb.disabled = true
		row.add_child(sb)
		inp.add_child(row)
	conv.add_child(UI.panel(inp, Color("#f4f6f9"), Color(0, 0, 0, 0), 0, 6))
	h.add_child(conv)
	w.set_content(h)

func push_msg(k: String, who: String, text: String, extra := "") -> void:
	var m := [who, text]
	if extra != "":
		m.append(extra)
	CHATS[k].ms.append(m)
	render_chat()

func chat_notify() -> void:
	Sfx.play("msg")
	var w := D.win("chat")
	if w and w.task_button:
		var tw := w.task_button.create_tween().set_loops(4)
		tw.tween_property(w.task_button, "modulate", Color("#ffcf5a"), 0.4)
		tw.tween_property(w.task_button, "modulate", Color.WHITE, 0.4)

## Рискованная подсказка: написать Диме от имени Лёвы (сильно палит компьютер).
func ask_dima() -> void:
	if G.flag("dimaAsked"):
		return
	G.set_flag("dimaAsked")
	var dm = G.L.chat.dima
	var t := func(): return "06.10 " + G.clock_str(int(G.st.mins))
	push_msg("dima", "lie", dm.q, t.call())
	for a in [dm.a1, dm.a2, dm.a3]:
		if not await G.sleep(1.6):
			return
		Sfx.play("msg")
		push_msg("dima", t.call(), a)
	G.stealth.add_sus(45, "dima")
	if G.ending == "":
		say(dm.think)

# ---------------------------------------------------------------- «Флажки»
var flag_round := 0
var flag_score := 0
var flag_seq: Array = []

func open_flags() -> void:
	D.open_win("flags", G.L.flags.title, "star", 440, 420)
	_flags_start_screen()
	if not G.flag("flags"):
		G.set_flag("flags")
		say(G.L.lines.flagsFirst)

func _flags_start_screen() -> void:
	var w := D.win("flags")
	if not w:
		return
	var fl = G.L.flags
	var v := UI.vbox(12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := UI.label(fl.title.to_upper(), UI.pixf, 16, UI.GRAPE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var row := UI.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for k in ["ru", "jp", "br", "se"]:
		var tr := TextureRect.new()
		tr.texture = UI.tex("flag_" + k)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.custom_minimum_size = Vector2(60, 40)
		row.add_child(tr)
	v.add_child(row)
	var rec := UI.label(fl.record, null, 16, UI.GREY)
	rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(rec)
	if G.fget("flagsBest", -1) != -1:
		var b := UI.label("★ %d / 10" % int(G.fget("flagsBest")), null, 16, UI.INK)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(b)
	var go := UI.button(fl.start, _flags_begin, "primary")
	go.custom_minimum_size = Vector2(160, 0)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(go)
	w.set_content(UI.panel(v, Color.WHITE, Color(0, 0, 0, 0), 0, 16))

func _flags_begin() -> void:
	var keys: Array = G.L.flags.countries.keys()
	keys.erase("mayak")
	keys.shuffle()
	flag_seq = keys.slice(0, 10)
	if G.stage() >= 3:
		flag_seq[9] = "mayak"
	flag_round = 0
	flag_score = 0
	_flags_round()

func _flags_round() -> void:
	var w := D.win("flags")
	if not w:
		return
	var fl = G.L.flags
	var key: String = flag_seq[flag_round]
	var v := UI.vbox(10)
	v.add_child(UI.label(fl.round % (flag_round + 1), null, 16, UI.GREY))
	var tr := TextureRect.new()
	tr.texture = UI.tex("flag_" + key)
	tr.custom_minimum_size = Vector2(240, 160)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(tr)
	var q := UI.label(fl.q, UI.head, 16, UI.INK)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(q)
	var opts := [key]
	if key == "mayak":
		opts = ["mayak", "mayak", "mayak", "mayak"]
	else:
		var others: Array = G.L.flags.countries.keys()
		others.erase("mayak")
		others.erase(key)
		others.shuffle()
		opts += others.slice(0, 3)
		opts.shuffle()
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var fb := UI.label("", UI.head, 16, UI.MINT)
	fb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for o in opts:
		var b := UI.button(G.L.flags.countries[o], func(): pass)
		b.custom_minimum_size = Vector2(190, 0)
		var ok: bool = o == key
		b.pressed.connect(func():
			for c in g.get_children():
				c.disabled = true
			if key == "mayak":
				G.fx.glitch()
				Sfx.play("scare", -8.0)
				say(G.L.lines.flagsDark)
				fb.text = "…"
			elif ok:
				flag_score += 1
				Sfx.play("chime", -6.0)
				fb.text = fl.right
				fb.add_theme_color_override("font_color", UI.MINT)
			else:
				Sfx.play("err")
				fb.text = fl.wrong % G.L.flags.countries[key]
				fb.add_theme_color_override("font_color", UI.ALERT)
			await get_tree().create_timer(1.1, false).timeout
			flag_round += 1
			if flag_round >= 10:
				_flags_result()
			else:
				_flags_round())
		g.add_child(b)
	v.add_child(g)
	v.add_child(fb)
	w.set_content(UI.panel(v, Color.WHITE, Color(0, 0, 0, 0), 0, 14))

func _flags_result() -> void:
	var w := D.win("flags")
	if not w:
		return
	var fl = G.L.flags
	var v := UI.vbox(12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var res := UI.label(fl.result % flag_score, UI.head, 16, UI.INK)
	res.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(res)
	if flag_score > int(G.fget("flagsBest", 0)):
		G.st.f["flagsBest"] = flag_score
		G.save_game()
	if flag_score > 8:
		var b := UI.label(fl.beat, UI.head, 16, UI.MINT)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(b)
		if not G.flag("flagsBeat"):
			G.set_flag("flagsBeat")
			say(G.L.lines.flagsBeat)
	if flag_score == 10:
		G.achieve("FLAGS")
	var again := UI.button(fl.again, _flags_begin, "primary")
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(again)
	w.set_content(UI.panel(v, Color.WHITE, Color(0, 0, 0, 0), 0, 16))

# ---------------------------------------------------------------- карта (пазл 3x3)
var map_order: Array = []
var map_sel := -1

func open_map() -> void:
	if map_order.is_empty():
		map_order = [4, 7, 2, 0, 8, 5, 1, 6, 3]
		if G.flag("map"):
			map_order = range(9)
	D.open_win("map", G.L.map.title, "web", 504, 488)
	render_map()
	if not G.flag("mapFirst"):
		G.set_flag("mapFirst")
		say(G.L.lines.mapFirst, func(): if not G.flag("map"): P.goal("map"))

func render_map() -> void:
	var w := D.win("map")
	if not w:
		return
	var solved := G.flag("map")
	var v := UI.vbox(6)
	v.add_child(UI.label(G.L.map.done if solved else G.L.map.hint, null, 16, UI.MINT.darkened(0.3) if solved else UI.GREY, true))
	var board := Control.new()
	board.custom_minimum_size = Vector2(480, 360)
	var full: Texture2D = UI.tex("map_full")
	for pos in 9:
		var piece: int = map_order[pos]
		var at := AtlasTexture.new()
		at.atlas = full
		at.region = Rect2((piece % 3) * 160, int(piece / 3) * 120, 160, 120)
		var b := TextureButton.new()
		b.texture_normal = at
		b.position = Vector2((pos % 3) * 160, int(pos / 3) * 120)
		b.disabled = solved
		if pos == map_sel:
			b.modulate = Color(1.2, 1.1, 0.7)
		b.pressed.connect(_map_click.bind(pos))
		board.add_child(b)
		if not solved:
			var fr := Panel.new()
			fr.add_theme_stylebox_override("panel", UI.flat(Color(0, 0, 0, 0), Color("#ff5a4d") if pos == map_sel else Color(0, 0, 0, 0.35), 2, 0, 0))
			fr.position = b.position
			fr.size = Vector2(160, 120)
			fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			board.add_child(fr)
	if solved:
		var lb = G.L.map.labels
		for p in [[lb.home, Vector2(40, 330)], [lb.school, Vector2(40, 124)], [lb.shop, Vector2(150, 230)], [lb.garages, Vector2(236, 256)], [lb.tower, Vector2(250, 6)], [lb.gran, Vector2(8, 4)]]:
			var l := UI.shadowed(UI.label(p[0], UI.head, 16, UI.INK), Color.WHITE)
			l.position = p[1]
			board.add_child(l)
	v.add_child(board)
	w.set_content(UI.panel(v, Color.WHITE, Color(0, 0, 0, 0), 0, 8))

func _map_click(pos: int) -> void:
	Sfx.play("key")
	if map_sel == -1:
		map_sel = pos
	elif map_sel == pos:
		map_sel = -1
	else:
		var tmp = map_order[pos]
		map_order[pos] = map_order[map_sel]
		map_order[map_sel] = tmp
		map_sel = -1
	if map_order == range(9) and not G.flag("map"):
		Sfx.play("chime")
		G.set_flag("map")
		G.achieve("MAP")
		render_map()
		say(G.L.lines.mapDone, func(): G.story.check_part2())
		return
	render_map()

# ---------------------------------------------------------------- фото
const PHOTO_TEX := ["photo_river", "photo_tower", "photo_treehouse", "photo_school", "photo_screen"]

func open_photos() -> void:
	D.open_win("photos", G.L.photos.folder, "photo", 600, 290, func(w: OSWindow):
		var g := GridContainer.new()
		g.columns = 5
		g.add_theme_constant_override("h_separation", 6)
		var items: Array = G.L.photos.items
		for i in items.size():
			var b := Button.new()
			b.custom_minimum_size = Vector2(108, 110)
			b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			b.add_theme_stylebox_override("hover", UI.flat(Color("#efeafd"), UI.GRAPE, 2, 0, 4))
			b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			var v := UI.vbox(4)
			v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var th := TextureRect.new()
			th.texture = UI.tex(PHOTO_TEX[i])
			th.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			th.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			th.custom_minimum_size = Vector2(100, 66)
			th.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(th)
			var nl := UI.label(items[i].n, null, 16, UI.INK, true)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.custom_minimum_size = Vector2(100, 0)
			nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(nl)
			v.position = Vector2(4, 2)
			b.add_child(v)
			b.pressed.connect(open_photo.bind(i))
			g.add_child(b)
		w.set_content(UI.panel(g, Color.WHITE, Color(0, 0, 0, 0), 0, 10)))
	if not G.flag("photos"):
		G.set_flag("photos")
		say(G.L.lines.photosFirst)

func open_photo(i: int) -> void:
	var it = G.L.photos.items[i]
	D.open_win("ph%d" % i, it.n + " — " + G.L.os.viewer, "photo", 440, 360, func(w: OSWindow):
		var v := UI.vbox(8)
		var tr := TextureRect.new()
		tr.texture = UI.tex(PHOTO_TEX[i])
		tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		tr.custom_minimum_size = Vector2(416, 276)
		v.add_child(tr)
		if i == 4:
			var cap := UI.label(G.L.dead.rows[0][1], null, 16, Color.WHITE, true)
			cap.position = Vector2(48, 208)
			cap.size = Vector2(320, 40)
			tr.add_child(cap)
		v.add_child(UI.label(it.cap, null, 16, Color("#cfd8e3"), true))
		w.set_content(UI.panel(v, Color("#2b2b33"), Color(0, 0, 0, 0), 0, 8)))
	if not G.flag("photo%d" % i):
		G.set_flag("photo%d" % i)
		var lines: Array = []
		for l in it.react:
			lines.append(G.plain(l))
		say(lines)

# ---------------------------------------------------------------- журнал родительского контроля
func open_parental() -> void:
	D.open_win("parental", G.L.parental.title, "shield", 600, 300, func(w: OSWindow):
		var bb := "[table=2]"
		for r in G.L.parental.rows:
			bb += "[cell][color=#8890a0]%s   [/color][/cell][cell]%s[/cell]" % [r[0], G.clue(r[1])]
		bb += "[/table]"
		w.set_content(paper_rich(bb)))
	if not G.flag("parental"):
		G.set_flag("parental")
		say(G.L.lines.parentalFirst + G.L.lines.parentalNight)

# ---------------------------------------------------------------- шифровка Лёвы
var cipher_shift := 0

func _shift_text(text: String, sh: int) -> String:
	var ab: String = G.L.cipher.alphabet
	var n := ab.length()
	var out := ""
	for ch in text.replace("ё", "е"):
		var i := ab.find(ch)
		out += ab[(i + sh + n * 4) % n] if i >= 0 else ch
	return out

func open_cipher() -> void:
	D.open_win("cipher", G.L.cipher.title, "noteRed", 520, 330)
	render_cipher()
	if not G.flag("cipherSeen"):
		G.set_flag("cipherSeen")
		say(G.L.lines.cipherFirst)

func render_cipher() -> void:
	var w := D.win("cipher")
	if not w:
		return
	var cp = G.L.cipher
	var solved := G.flag("cipher")
	var enc := _shift_text(cp.text, int(cp.key))
	var shown: String = cp.text if solved else _shift_text(enc, -cipher_shift)
	var v := UI.vbox(10)
	v.add_child(UI.label(cp.hint, null, 16, UI.GREY, true))
	var r := UI.rich("[color=%s]%s[/color]" % ["#1d1a2b" if solved else "#b0433a", G.esc(shown)], true)
	r.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	v.add_child(UI.panel(r, Color("#fffef6"), UI.LINE, 2, 12))
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var minus := UI.button("◀", func():
		cipher_shift -= 1
		_cipher_changed())
	var plus := UI.button("▶", func():
		cipher_shift += 1
		_cipher_changed())
	minus.disabled = solved
	plus.disabled = solved
	row.add_child(minus)
	row.add_child(UI.label(cp.shift % (int(cp.key) if solved else posmod(cipher_shift, 40)), UI.head, 16, UI.INK))
	row.add_child(plus)
	v.add_child(row)
	w.set_content(UI.panel(v, Color.WHITE, Color(0, 0, 0, 0), 0, 12))

func _cipher_changed() -> void:
	Sfx.play("key")
	var n: int = String(G.L.cipher.alphabet).length()
	if posmod(cipher_shift, n) == int(G.L.cipher.key) and not G.flag("cipher"):
		Sfx.play("chime")
		G.set_flag("cipher")
		G.achieve("CIPHER")
		render_cipher()
		say(G.L.lines.cipherDone, func(): G.story.check_part2())
		return
	render_cipher()

# ---------------------------------------------------------------- «Капитан и шторм»
func open_boat() -> void:
	D.open_win("boat", G.L.boat.title, "boat", 424, 440)
	_boat_menu("")
	if not G.flag("boat"):
		G.set_flag("boat")
		say(G.L.lines.boatFirst)

func _boat_menu(result: String) -> void:
	var w := D.win("boat")
	if not w:
		return
	var bt = G.L.boat
	var v := UI.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := UI.label(bt.title.to_upper(), UI.pixf, 16, UI.GRAPE, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	if result != "":
		var rl := UI.label(result, UI.head, 16, UI.INK, true)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(rl)
	for s in [bt.help, bt.record]:
		var l := UI.label(s, null, 16, UI.GREY, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var go := UI.button(bt.start if result == "" else bt.again, _boat_play, "primary")
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(go)
	w.set_content(UI.panel(v, Color.WHITE, Color(0, 0, 0, 0), 0, 16))
	go.call_deferred("grab_focus")

func _boat_play() -> void:
	var w := D.win("boat")
	if not w:
		return
	var game := BoatGame.new()
	var holder := CenterContainer.new()
	holder.add_child(game)
	w.set_content(UI.panel(holder, Color("#0b0a0e"), Color(0, 0, 0, 0), 0, 4))
	game.finished.connect(func(n: int, dark: bool):
		if n >= 3:
			G.achieve("BOAT")
			say(G.L.lines.boatWin)
		if dark:
			say(G.L.lines.boatDark)
		await get_tree().create_timer(1.2, false).timeout
		var bt = G.L.boat
		_boat_menu(bt.darkLose if dark else ((bt.win if n > 0 else bt.lose) + "  " + bt.score % n)))
	game.call_deferred("start")
