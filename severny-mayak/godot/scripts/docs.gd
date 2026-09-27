class_name Docs
extends Node
## Документы и программы на компьютере Лёвы. Текст документов проходит через G.doc():
## в режиме лупы ключевые слова подсвечиваются и по клику уходят в банк слов.

var D: Desk
var CHATS := {}
var chat_sel := "mama"
var choice_shown := false
var mail_sel := ""
var tm_sel := ""
var mic_lines: Array = []       # что Пиксель успел услышать
var mic_live := false
var map_order: Array = []
var map_sel := -1
var mem_order: Array = []
var mem_sel := -1
var cipher_shift := 0

func _ready() -> void:
	D = G.desk

func say(lines, cb := Callable()) -> void:
	G.pix.say(lines, cb)

func desk_list() -> Array:
	var d = G.L.desk
	return [
		{"id": "note", "ic": "note", "label": func(): return d.note, "open": open_note},
		{"id": "draw", "ic": "folder", "label": func(): return d.draw, "open": open_drawings},
		{"id": "log", "ic": "pixel", "label": func(): return d.log, "open": open_log},
		{"id": "web", "ic": "web", "label": func(): return d.web, "open": open_web},
		{"id": "mail", "ic": "mail", "label": func(): return d.mail, "open": open_mail},
		{"id": "photos", "ic": "photo", "label": func(): return d.photos, "open": open_photos},
		{"id": "tale", "ic": "tale", "label": func(): return d.tale, "open": open_tale},
		{"id": "diary", "ic": "diary", "label": func(): return d.diary, "open": open_diary},
		{"id": "cam", "ic": "cam", "label": func(): return d.cam, "open": open_cam},
		{"id": "mic", "ic": "mic", "label": func(): return d.mic, "open": open_mic},
		{"id": "chat", "ic": "chat", "label": func(): return d.chat, "open": open_chat},
		{"id": "parental", "ic": "shield", "label": func(): return d.parental, "open": open_parental},
		{"id": "bin", "ic": "bin", "label": func(): return d.bin, "open": open_bin},
		{"id": "tm", "ic": "tm", "label": func(): return d.tm, "open": open_tm},
		{"id": "flags", "ic": "flags", "label": func(): return d.flags, "open": open_flags},
		{"id": "map", "ic": "map", "label": func(): return d.map, "open": open_map, "show": func(): return int(G.st.night) >= 2},
		{"id": "cipher", "ic": "noteRed", "label": func(): return G.L.cipher.file.get_basename(), "open": open_cipher,
			"show": func(): return G.st.solved.has("s4")},
		{"id": "dont", "ic": "noteRed", "label": func(): return d.dont, "open": open_dont,
			"show": func(): return G.flag("dontShown") and not G.flag("dontRead")},
		{"id": "cache", "ic": "cache", "label": func(): return d.cache, "open": open_cache,
			"show": func(): return not G.hidden_files().is_empty()},
	]

func entry(id: String) -> Dictionary:
	for e in desk_list():
		if e.id == id:
			return e
	return {}

func file_label(id: String) -> String:
	var e := entry(id)
	return String(e.label.call()) if e else id

# ---------------------------------------------------------------- спрятать / стереть
func _close_file_wins(id: String) -> void:
	for wid in G.FILE_WINS.get(id, [id]):
		D.close_win(wid)

## Спрятать файл в скрытую папку .кэш: следователь его не увидит (пока не придёт эксперт). Пиксель — может открыть.
func hide_file(id: String) -> void:
	if G.file_state(id) != "":
		return
	G.st.files[id] = "hidden"
	_close_file_wins(id)
	Sfx.play("paper")
	D.refresh_icons()
	D.changed.emit()
	G.save_game()
	first("hideFirst", G.L.lines.hideFirst)

func unhide_file(id: String) -> void:
	G.st.files.erase(id)
	D.refresh_icons()
	var w := D.win("cache")
	if w:
		if G.hidden_files().is_empty():
			w.close()
		else:
			w.rebuild()
	G.save_game()

func ask_delete(id: String) -> void:
	G.menus.confirm(G.L.ui.delConfirm % file_label(id), func(): delete_file(id))

## Стереть навсегда: ни следователь, ни Пиксель больше не прочитают. Слова, уже собранные в банк, остаются.
func delete_file(id: String) -> void:
	if G.file_state(id) == "deleted":
		return
	G.st.files[id] = "deleted"
	_close_file_wins(id)
	Sfx.play("err", -8.0)
	G.fx.glitch()
	D.refresh_icons()
	var w := D.win("cache")
	if w:
		if G.hidden_files().is_empty():
			w.close()
		else:
			w.rebuild()
	D.changed.emit()
	G.save_game()
	if int(G.FILES[id][1]) >= 15 and not G.flag("revealed"):
		first("deleteSelf", G.L.lines.deleteSelf)
	else:
		first("deleteFirst", G.L.lines.deleteFirst)

func open_cache() -> void:
	D.open_win("cache", G.L.ui.cacheTitle, "cache", 220, 90, func(w: OSWindow):
		var v := UI.vbox(2)
		v.add_child(UI.label(G.L.ui.cacheHint, UI.INK2, null, 8, 200))
		for id in G.hidden_files():
			var row := UI.hbox(2)
			row.mouse_filter = Control.MOUSE_FILTER_PASS
			var n := UI.label(file_label(id), UI.INK)
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(n)
			var e := entry(id)
			row.add_child(UI.button(G.L.ui.fileOpen, func(): e.open.call()))
			row.add_child(UI.button(G.L.ui.fileBack, func(): unhide_file(id)))
			row.add_child(UI.button(G.L.ui.fileDel, func(): ask_delete(id), "red"))
			v.add_child(row)
		w.set_content(UI.scroll(paper(v))))

# ---------------------------------------------------------------- общие детали
## Текст документа с поддержкой лупы.
func rt(bb: String, color := UI.INK, fit := true) -> RichTextLabel:
	var r := UI.rich(bb, fit)
	r.add_theme_color_override("default_color", color)
	r.meta_clicked.connect(func(m):
		if G.lens:
			G.collect(str(m)))
	return r

func paper(child: Control, bg := UI.PAPER, pad := 5) -> PanelContainer:
	return UI.panel(child, bg, Color(0, 0, 0, 0), 0, pad)

func first(key: String, lines: Array, cb := Callable()) -> void:
	if not G.flag(key):
		G.set_flag(key)
		say(lines, cb)

func shard_btn(i: int) -> Control:
	if G.st.shards.has(i):
		return Control.new()
	var b := TextureButton.new()
	b.texture_normal = UI.tex("shard_0")
	b.texture_hover = UI.tex("shard_1")
	b.pressed.connect(func():
		collect_shard(i)
		b.queue_free())
	var tw := b.create_tween().set_loops()
	tw.tween_property(b, "modulate:a", 0.3, 1.0)
	tw.tween_property(b, "modulate:a", 1.0, 1.0)
	return b

func collect_shard(i: int) -> void:
	if G.st.shards.has(i):
		return
	G.st.shards.append(i)
	Sfx.play("shard")
	G.menus.toast("%s %d/%d" % [G.L.ui.shards, G.st.shards.size(), G.L.shards.size()])
	if G.st.shards.size() == G.L.shards.size():
		G.achieve("SHARDS")
		say(G.L.lines.shardsAll)
	else:
		first("shard1", G.L.lines.shardFirst)
	G.save_game()

func chat_line(w: String, t: String) -> String:
	var lg = G.L.log
	match w:
		"gap": return "[color=#a8443c]%s[/color]" % G.doc(t)
		"sys": return "[color=#a8443c]%s[/color]" % G.doc(t)
		"ghost": return ("[color=#a8443c66]%s[/color]" % G.doc(t)) if G.st.ng else ""
	var col := "#3f5068" if w == "l" else "#5a4b75"
	return "[color=%s]%s:[/color] %s" % [col, lg.lev if w == "l" else lg.pix, G.doc(t)]

# ---------------------------------------------------------------- записка
func open_note() -> void:
	D.open_win("note", G.L.note.title, "note", 210, 150, func(w: OSWindow):
		w.set_content(UI.scroll(paper(rt(G.doc(G.L.note.body))))))
	first("note", G.L.lines.note, func():
		if not G.flag("lensTut"):
			G.set_flag("lensTut")
			G.pix.goal("lens")
			say(G.L.lines.lensTut))

# ---------------------------------------------------------------- рисунки
const DRAW := ["drawing_me", "drawing_tower", "drawing_family"]

func open_drawings() -> void:
	D.open_win("draw", G.L.drawings.folder, "folder", 170, 64, func(w: OSWindow):
		var h := UI.hbox(4)
		for i in 3:
			var b := TextureButton.new()
			var at := AtlasTexture.new()
			at.atlas = UI.tex(DRAW[i])
			at.region = Rect2(40, 20, 50, 36) if i > 0 else Rect2(60, 40, 50, 36)
			b.texture_normal = at
			b.pressed.connect(open_drawing.bind(i))
			h.add_child(b)
		w.set_content(paper(h, UI.LIGHT, 4)))

func open_drawing(i: int) -> void:
	var dr = G.L.drawings
	D.open_win("dr%d" % i, dr.names[i], "note", 250, 196, func(w: OSWindow):
		var v := UI.vbox(2)
		var t := TextureRect.new()
		t.texture = UI.tex("drawing_family_x" if i == 2 and G.flag("uFamily") else DRAW[i])
		t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		t.custom_minimum_size = Vector2(240, 168 if i > 0 else 125)
		v.add_child(t)
		v.add_child(UI.label(dr.captions[i], UI.BLUE))
		if i > 0:
			var sb := shard_btn(0 if i == 1 else 5)
			sb.position = Vector2(200, 10)
			t.add_child(sb)
		w.set_content(paper(v, UI.PAPER, 3)))
	if i == 0 and G.stage() >= 3 and not G.flag("scare"):
		G.set_flag("scare")
		if G.menus.scare():
			say(G.L.lines.scare)
	first("draw%d" % i, dr.react[i])
	if i == 2 and G.flag("uFamily"):
		first("uFamilySeen", G.L.lines.uFamily)

# ---------------------------------------------------------------- журнал бесед
func open_log() -> void:
	D.open_win("log", G.L.log.title, "pixel", 230, 160, func(w: OSWindow):
		var bb := ""
		var days: Array = G.L.log.days.duplicate()
		if G.flag("uLog"):
			# запись, которой не было: «сегодня, 03:12»
			days.append([G.L.uncanny.logDate, G.L.uncanny.log])
		for d in days:
			bb += "[color=#554b45]— %s —[/color]\n" % G.doc(d[0])
			for m in d[1]:
				var l := chat_line(m[0], m[1])
				if l != "":
					bb += l + "\n"
		w.set_content(UI.scroll(paper(rt(bb)))))
	if G.flag("uLog"):
		first("uLogSeen", G.L.lines.uLog)

# ---------------------------------------------------------------- браузер
func open_web() -> void:
	D.open_win("web", G.L.web.title, "web", 240, 130, func(w: OSWindow):
		if G.flag("pin"):
			var bb := ""
			for h in G.L.web.hist:
				bb += "[color=#554b45]%s[/color]  %s\n" % [G.doc(h[0]), G.doc(h[1])]
			w.set_content(UI.scroll(paper(rt(bb), Color("#e7dfcc"))))
		else:
			w.set_content(_pin_screen()))
	if not G.flag("pin"):
		first("pinSeen", G.L.lines.pinFirst, func(): G.pix.goal("pin"))

func _pin_screen() -> Control:
	var wb = G.L.web
	var v := UI.vbox(4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(UI.label(wb.locked, UI.INK, null, 8, 220))
	v.add_child(UI.label(wb.hint, UI.INK2, null, 8, 220))
	var row := UI.hbox(3)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var inp := LineEdit.new()
	inp.max_length = 4
	inp.custom_minimum_size = Vector2(40, 10)
	inp.secret = true
	row.add_child(inp)
	var err := UI.label("", UI.RED)
	var go := func():
		if not try_pin(inp.text):
			Sfx.play("err")
			G.stealth.add_sus(2, "beep")
			err.text = wb.err
			inp.text = ""
			G.st.f["pinTries"] = int(G.fget("pinTries")) + 1
			if int(G.fget("pinTries")) == 3:
				say(G.L.lines.pinHint)
	row.add_child(UI.button(wb.open, go, "red"))
	inp.text_submitted.connect(func(_t): go.call())
	v.add_child(row)
	v.add_child(err)
	inp.call_deferred("grab_focus")
	return paper(v, UI.PAPER, 8)

func try_pin(code: String) -> bool:
	if code.strip_edges() != String(G.L.web.code):
		return false
	Sfx.play("chime")
	G.set_flag("pin")
	say(G.L.lines.pinOk)
	var w := D.win("web")
	if w:
		w.rebuild()
	return true

# ---------------------------------------------------------------- почта
func open_mail() -> void:
	D.open_win("mail", G.L.mail.title, "mail", 260, 150, _mail_build)

func _mail_build(w: OSWindow) -> void:
	var ml = G.L.mail
	var h := UI.hbox(0)
	var list := UI.vbox(1)
	list.custom_minimum_size = Vector2(80, 0)
	list.mouse_filter = Control.MOUSE_FILTER_PASS
	for m in ml.letters:
		var b := Button.new()
		b.text = m.from
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size = Vector2(80, 10)
		var act: bool = m.id == mail_sel
		b.add_theme_stylebox_override("normal", UI.flat(UI.PAPER if act else UI.PAPER2, UI.PAPER3, 0, 2, 1))
		b.add_theme_stylebox_override("hover", UI.flat(UI.PAPER, UI.PAPER3, 0, 2, 1))
		var mid: String = m.id
		b.pressed.connect(func():
			mail_sel = mid
			Sfx.play("paper")
			w.rebuild())
		list.add_child(b)
	h.add_child(paper(list, UI.PAPER2, 1))
	var cur = null
	for m in ml.letters:
		if m.id == mail_sel:
			cur = m
	var right := UI.vbox(2)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if cur:
		right.add_child(rt("[color=#554b45]%s · %s[/color]\n%s" % [G.esc(cur.subj), cur.date, G.doc(cur.body)]))
		if cur.has("shard"):
			right.add_child(shard_btn(int(cur.shard)))
	else:
		right.add_child(UI.label(ml.pick, UI.INK2))
	h.add_child(UI.scroll(paper(right)))
	w.set_content(h)

# ---------------------------------------------------------------- фото
const PHOTOS := ["photo_river", "photo_tower", "photo_treehouse", "photo_screen"]

func open_photos() -> void:
	D.open_win("photos", G.L.photos.folder, "photo", 220, 60, func(w: OSWindow):
		var h := UI.hbox(3)
		for i in PHOTOS.size():
			var b := TextureButton.new()
			var at := AtlasTexture.new()
			at.atlas = UI.tex(PHOTOS[i])
			at.region = Rect2(60, 30, 48, 36)
			b.texture_normal = at
			b.pressed.connect(open_photo.bind(i))
			h.add_child(b)
		w.set_content(paper(h, UI.LIGHT, 4)))
	first("photos", G.L.lines.photo)

func open_photo(i: int) -> void:
	var it = G.L.photos.items[i]
	D.open_win("ph%d" % i, it.n, "photo", 216, 176, func(w: OSWindow):
		var v := UI.vbox(2)
		var t := TextureRect.new()
		t.texture = UI.tex(PHOTOS[i])
		t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		t.custom_minimum_size = Vector2(208, 138)
		v.add_child(t)
		var cap: String = G.L.uncanny.photoCap if i == 0 and G.flag("uPhoto") else String(it.cap)
		v.add_child(rt(G.doc(cap), UI.PAPER))
		w.set_content(paper(v, UI.DARK2, 3)), UI.DARK2)
	first("photo%d" % i, G.L.photos.react[i])
	if i == 0 and G.flag("uPhoto"):
		first("uPhotoSeen", G.L.lines.uPhoto)

# ---------------------------------------------------------------- сказка
func tale_count() -> int:
	return 4 if G.st.solved.has("s3") else 2

func open_tale() -> void:
	D.open_win("tale", G.L.tale.folder, "tale", 200, 50, func(w: OSWindow):
		var h := UI.hbox(3)
		for i in tale_count():
			var b := UI.button(G.L.tale.chapters[i].n.get_basename(), open_chapter.bind(i))
			h.add_child(b)
		w.set_content(paper(h, UI.LIGHT, 4)))

func open_chapter(i: int) -> void:
	var c = G.L.tale.chapters[i]
	D.open_win("ch%d" % i, c.n, "note", 230, 150, func(w: OSWindow):
		var v := UI.vbox(3)
		v.add_child(UI.label(c.title, UI.RED))
		var bb := ""
		for p in c.body:
			if p[0] == "l":
				bb += "[color=#3f5068]%s[/color]\n\n" % G.doc(p[1])
			else:
				bb += G.doc(p[1]) + "\n\n"
		v.add_child(rt(bb))
		v.add_child(rt("[color=#948c8e]%s[/color]" % G.doc(c.meta)))
		if c.has("shard"):
			v.add_child(shard_btn(int(c.shard)))
		w.set_content(UI.scroll(paper(v))))

# ---------------------------------------------------------------- дневник
func open_diary() -> void:
	D.open_win("diary", G.L.diary.title, "diary", 230, 150, func(w: OSWindow):
		if G.flag("diary"):
			var v := UI.vbox(3)
			for e in G.L.diary.entries:
				var r := rt("[color=#a8443c]%s[/color] %s" % [G.esc(e[0]), G.doc(e[1])], UI.BLUE)
				v.add_child(r)
			v.add_child(shard_btn(int(G.L.diary.shard)))
			w.set_content(UI.scroll(paper(v, Color("#e9e1cc"))))
		else:
			w.set_content(_diary_lock()))

func _diary_lock() -> Control:
	var dl = G.L.diary
	var v := UI.vbox(4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(UI.label(dl.locked, UI.INK))
	v.add_child(UI.label(dl.hint, UI.INK2))
	var row := UI.hbox(3)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var inp := LineEdit.new()
	inp.custom_minimum_size = Vector2(110, 10)
	row.add_child(inp)
	var err := UI.label("", UI.RED)
	var go := func():
		if not try_diary(inp.text):
			Sfx.play("err")
			G.stealth.add_sus(2, "beep")
			err.text = dl.err
	row.add_child(UI.button(dl.open, go, "red"))
	inp.text_submitted.connect(func(_t): go.call())
	v.add_child(row)
	v.add_child(err)
	inp.call_deferred("grab_focus")
	return paper(v, UI.PAPER, 8)

func try_diary(text: String) -> bool:
	var val := text.strip_edges().to_lower().replace("ё", "е")
	for a in G.LANGS.ru.diary.answers + G.LANGS.en.diary.answers:
		if val != "" and val.contains(a):
			Sfx.play("chime")
			G.set_flag("diary")
			var w := D.win("diary")
			if w:
				w.rebuild()
			return true
	return false

# ---------------------------------------------------------------- камера
func open_cam() -> void:
	D.open_win("cam", G.L.cam.title, "cam", 244, 174, _cam_build, UI.BLACK)
	first("cam", G.L.lines.cam)

func _cam_build(w: OSWindow) -> void:
	var c = G.L.cam
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	if G.flag("monitorOff"):
		var off := UI.label(c.off, UI.GREY3)
		off.position = Vector2(80, 70)
		root.add_child(off)
		w.set_content(root)
		return
	var dad_view: bool = G.flag("dadCamNow")
	var room := TextureRect.new()
	room.texture = UI.tex("cam_dad" if dad_view else "cam_room")
	root.add_child(room)
	var awake: Array = G.house.awake_in_lev()
	if not dad_view and (awake.size() > 0 or G.house.asleep_in_lev()):
		var mom := TextureRect.new()
		mom.texture = UI.tex("cam_mom")
		root.add_child(mom)
	if G.stage() >= 3:
		var dk := TextureRect.new()
		dk.texture = UI.tex("cam_dark")
		root.add_child(dk)
	var osd := UI.label("%s %s" % [c.osd, G.clock()], UI.PAPER)
	osd.position = Vector2(4, 2)
	root.add_child(osd)
	var rec := UI.label(c.rec, UI.ALARM)
	rec.position = Vector2(200, 2)
	root.add_child(rec)
	if awake.size() > 0 or dad_view:
		var led := UI.label(c.led, UI.ALARM)
		led.position = Vector2(4, 12)
		root.add_child(led)
	var who := []
	for a in awake:
		who.append(G.L.speakers[a])
	var cap := UI.label(c.person % ", ".join(who) if who.size() else c.empty, UI.PAPER)
	cap.position = Vector2(4, 150)
	root.add_child(cap)
	if G.stage() >= 1:
		var sb := shard_btn(2)
		sb.position = Vector2(60, 30)
		root.add_child(sb)
	w.set_content(root)

func refresh_cam() -> void:
	var w := D.win("cam")
	if w:
		w.rebuild()

# ---------------------------------------------------------------- микрофон
func open_mic() -> void:
	D.open_win("mic", G.L.mic.title, "mic", 210, 120, _mic_build, UI.DARK2)
	first("mic", G.L.lines.mic)

func _mic_build(w: OSWindow) -> void:
	var bb := ""
	if mic_lines.is_empty() and not mic_live:
		bb = "[color=#948c8e]%s[/color]" % G.L.mic.idle
	if mic_live:
		bb = "[color=#cf3f4f]%s[/color]\n" % G.L.mic.live
	for l in mic_lines:
		bb += l + "\n"
	var r := rt(bb, UI.LIGHT, false)
	r.scroll_following = true
	w.set_content(paper(r, UI.DARK2))

func mic_event(lines: Array) -> void:
	mic_live = true
	G.house.sound(60, G.L.snd.voices)
	D.blink_icon("mic")
	var heard := D.win("mic") != null
	for l in lines:
		if not await G.sleep(2.2):
			return
		if D.win("mic"):
			heard = true
			mic_lines.append("[color=#c49a45]%s:[/color] %s" % [G.L.speakers.get(l[0], l[0]), G.doc(l[1])])
			Sfx.play("type", -10.0)
			D.win("mic").rebuild()
		else:
			G.house.sound(60, G.L.snd.voices)
	mic_live = false
	if heard:
		mic_lines.append("[color=#948c8e]%s[/color]" % G.L.mic.lost)
	var w := D.win("mic")
	if w:
		w.rebuild()

# ---------------------------------------------------------------- мессенджер
func reset_chats() -> void:
	var p = G.L.chat.people
	CHATS = {
		"mama": {"name": p.mama.name, "on": false, "ms": p.mama.ms.duplicate(true)},
		"dima": {"name": p.dima.name, "on": true, "ms": p.dima.ms.duplicate(true)},
		"papa": {"name": p.papa.name, "on": false, "ms": p.papa.ms.duplicate(true)},
	}
	if G.flag("momPolice"):
		CHATS.mama.ms.append(["05.10 22:20", G.L.chat.momPolice])
	if G.flag("dimaNight"):
		CHATS.dima.ms.append(["05.10 00:40", G.L.chat.dimaNight])

func open_chat() -> void:
	D.open_win("chat", G.L.chat.title, "chat", 260, 150, _chat_build)

func _chat_build(w: OSWindow) -> void:
	var cl = G.L.chat
	var c: Dictionary = CHATS[chat_sel]
	var h := UI.hbox(0)
	var contacts := UI.vbox(1)
	contacts.custom_minimum_size = Vector2(56, 0)
	contacts.mouse_filter = Control.MOUSE_FILTER_PASS
	for k in CHATS:
		var o: Dictionary = CHATS[k]
		var b := Button.new()
		b.text = ("• " if o.on else "  ") + String(o.name)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_stylebox_override("normal", UI.flat(UI.PAPER if k == chat_sel else UI.PAPER2, UI.PAPER3, 0, 2, 1))
		b.pressed.connect(func():
			chat_sel = k
			w.rebuild())
		contacts.add_child(b)
	h.add_child(paper(contacts, UI.PAPER2, 1))
	var conv := UI.vbox(2)
	conv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conv.mouse_filter = Control.MOUSE_FILTER_PASS
	var bb := ""
	for m in c.ms:
		match String(m[0]):
			"me": bb += "[color=#5a4b75]%s:[/color] %s\n" % [cl.me, G.esc(m[1])]
			"lie": bb += "[color=#3f5068]%s:[/color] %s\n" % [cl.lie, G.esc(m[1])]
			"st": bb += "[color=#948c8e]%s[/color]\n" % G.esc(m[1])
			_: bb += "[color=#948c8e]%s[/color] [color=#a8443c]%s:[/color] %s\n" % [m[0], c.name, G.doc(m[1])]
	var r := rt(bb, UI.INK, false)
	r.scroll_following = true
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conv.add_child(r)
	if chat_sel == "mama" and G.st.mom_online and choice_shown and G.ending == "":
		conv.add_child(UI.button(cl.tell, func(): G.night.ending_tell(), "red"))
		conv.add_child(UI.button(cl.silent, func(): G.night.ending_silent()))
		conv.add_child(UI.button(cl.pretend, func(): G.night.ending_pretend()))
	elif G.ending == "":
		conv.add_child(UI.label(cl.disabled, UI.GREY3, null, 8, 190))
	h.add_child(paper(conv))
	w.set_content(h)

func push_msg(k: String, who: String, text: String) -> void:
	CHATS[k].ms.append([who, text])
	var w := D.win("chat")
	if w:
		w.rebuild()

func chat_notify() -> void:
	Sfx.play("msg")
	D.blink_icon("chat")

# ---------------------------------------------------------------- родительский контроль
func open_parental() -> void:
	D.open_win("parental", G.L.parental.title, "shield", 250, 110, func(w: OSWindow):
		var bb := ""
		for r in G.L.parental.rows:
			bb += "[color=#554b45]%s[/color]  %s\n" % [G.doc(r[0]), G.doc(r[1])]
		w.set_content(UI.scroll(paper(rt(bb), Color("#e7dfcc")))))
	first("parental", G.L.lines.parental)
	# Пиксель соврал, что здесь ничего нет
	if G.fget("goal", "") == "lie":
		G.pix.goal("board")
		first("lieCaught", G.L.lines.lieCaught)

# ---------------------------------------------------------------- корзина и сторож
func open_bin() -> void:
	D.open_win("bin", G.L.bin.title, "bin", 210, 60, func(w: OSWindow):
		var v := UI.vbox(2)
		for i in G.L.bin.files.size():
			var f = G.L.bin.files[i]
			var row := UI.hbox(4)
			row.mouse_filter = Control.MOUSE_FILTER_PASS
			var n := UI.label("%s  %s" % [f.n, f.s], UI.INK)
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(n)
			row.add_child(UI.button(G.L.bin.restore, restore.bind(i)))
			v.add_child(row)
		w.set_content(paper(v)))

func restore(i: int) -> void:
	var f = G.L.bin.files[i]
	if not f.has("key"):
		say([f.line])
		return
	if G.flag("restored"):
		open_dead(false)
		return
	if int(G.st.mem) < 100:
		D.alert(G.L.bin.title, G.L.bin.locked, "stop")
		G.fx.glitch()
		G.stealth.add_sus(4, "beep")
		return
	if not G.flag("guardKilled"):
		D.alert(G.L.bin.title, G.L.bin.lockedGuard, "stop")
		G.fx.glitch()
		G.stealth.add_sus(4, "beep")
		G.pix.goal("guard")
		return
	open_memfix()

func open_tm() -> void:
	D.open_win("tm", G.L.tm.title, "tm", 230, 100, _tm_build)
	if guard_visible():
		first("tmGuard", G.L.lines.guard)

func guard_visible() -> bool:
	return int(G.st.mem) >= 100 and not G.flag("guardKilled")

func _tm_build(w: OSWindow) -> void:
	var tl = G.L.tm
	var v := UI.vbox(1)
	var procs: Array = tl.procs.duplicate(true)
	if guard_visible():
		procs.append(tl.guard)
	for p in procs:
		var mem: int = p[2] if p[0] != "PIKSEL.EXE" else 2140 + int(G.st.mem) * 128
		var b := Button.new()
		b.text = "%-16s %s" % [p[0], p[1]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		var sel: bool = p[0] == tm_sel
		var bad: bool = p[0] == tl.guard[0]
		b.add_theme_stylebox_override("normal", UI.flat(UI.PURPLE if sel else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 2, 0))
		b.add_theme_color_override("font_color", UI.PAPER if sel else (UI.RED if bad else UI.INK))
		var pn: String = p[0]
		b.pressed.connect(func():
			tm_sel = pn
			w.rebuild())
		v.add_child(b)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(60, 11)
	var end := UI.button(tl.end, end_process, "red")
	end.name = "End"
	holder.add_child(end)
	v.add_child(holder)
	w.set_content(paper(v))

func end_process() -> void:
	var tl = G.L.tm
	if tm_sel != tl.guard[0]:
		D.alert(tl.title, tl.denied, "stop")
		G.stealth.add_sus(3, "beep")
		return
	var n := int(G.fget("guardTries")) + 1
	G.st.f["guardTries"] = n
	if n < 3:
		G.fx.glitch()
		tm_sel = ""
		var w := D.win("tm")
		w.rebuild()
		var end: Control = w.body.find_child("End", true, false)
		if end:
			end.create_tween().tween_property(end, "position", Vector2(120 + randf() * 60, 0), 0.1)
		G.pix.reset()
		say(G.L.lines.guard1 if n == 1 else G.L.lines.guard2)
		return
	G.pix.reset()
	say(G.L.lines.guard3, func():
		G.set_flag("guardKilled")
		tm_sel = ""
		Sfx.play("door")
		if D.win("tm"):
			D.win("tm").rebuild()
		G.pix.goal("restore"))

# ---------------------------------------------------------------- восстановление записи (пазл)
func _chunks() -> Array:
	var rows: Array = G.L.dead.rows
	var out := []
	var i := 0
	while i < rows.size() - 1:
		out.append([i, i + 1] if i + 1 < rows.size() - 1 else [i])
		i += 2
	return out

func open_memfix() -> void:
	var n := _chunks().size()
	if mem_order.is_empty():
		mem_order = [3, 6, 0, 5, 2, 7, 1, 4]
	D.open_win("memfix", G.L.mem.title, "pixel", 300, 200, _memfix_build, UI.BLACK)
	first("memFirst", G.L.lines.memFirst)

func _memfix_build(w: OSWindow) -> void:
	var ch := _chunks()
	var v := UI.vbox(2)
	v.add_child(UI.label(G.L.mem.hint, UI.GREY3, null, 8, 280))
	for pos in mem_order.size():
		var ci: int = mem_order[pos]
		var t: String = G.L.dead.times[ch[ci][0]]
		var bb := "[color=#cf3f4f]%s[/color] " % (t.substr(0, 3) + "?" + t.substr(4))
		for r in ch[ci]:
			var row = G.L.dead.rows[r]
			bb += chat_line(row[0], row[1]) + " "
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UI.flat(Color("#3a1d24") if pos == mem_sel else UI.DARK2, UI.ALARM if pos == mem_sel else UI.DARK3, 1, 3, 1))
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		var r := rt(bb, UI.LIGHT)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(r)
		p.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				mem_click(pos))
		v.add_child(p)
	v.add_child(UI.button(G.L.mem.check, mem_check, "red"))
	w.set_content(UI.scroll(paper(v, UI.BLACK, 3)))

func mem_click(pos: int) -> void:
	Sfx.play("key")
	if mem_sel == -1:
		mem_sel = pos
	elif mem_sel == pos:
		mem_sel = -1
	else:
		var t = mem_order[pos]
		mem_order[pos] = mem_order[mem_sel]
		mem_order[mem_sel] = t
		mem_sel = -1
	D.win("memfix").rebuild()

func mem_check() -> void:
	if mem_order == range(mem_order.size()):
		Sfx.play("chime")
		D.close_win("memfix")
		G.set_flag("restored")
		G.achieve("TRUTH")
		open_dead(true)
	else:
		Sfx.play("err")
		G.fx.glitch()
		say(G.L.lines.memWrong)

func open_dead(first_time: bool) -> void:
	var w := D.open_win("dead", G.L.dead.title, "pixel", 280, 190, Callable(), UI.BLACK)
	var r := rt("[color=#948c8e]%s[/color]\n" % G.L.dead.head, UI.LIGHT, false)
	r.scroll_following = true
	w.set_content(paper(r, UI.BLACK))
	for row in G.L.dead.rows:
		if first_time and not await G.sleep(1.1):
			return
		if not is_instance_valid(r):
			break
		r.append_text(chat_line(row[0], row[1]).replace("#5a4b75", "#cf3f4f") + "\n")
		Sfx.tick()
	if first_time:
		G.fx.glitch()
		if await G.sleep(1.0):
			G.night.reveal()

# ---------------------------------------------------------------- карта (пазл)
func open_map() -> void:
	if map_order.is_empty():
		map_order = range(9) if G.flag("map") else [4, 7, 2, 0, 8, 5, 1, 6, 3]
	D.open_win("map", G.L.map.title, "map", 246, 214, _map_build)
	first("mapSeen", G.L.lines.mapFirst, func(): if not G.flag("map"): G.pix.goal("map"))

func _map_build(w: OSWindow) -> void:
	var solved := G.flag("map")
	var v := UI.vbox(2)
	var board := Control.new()
	board.custom_minimum_size = Vector2(240, 180)
	for pos in 9:
		var piece: int = map_order[pos]
		var at := AtlasTexture.new()
		at.atlas = UI.tex("map_full")
		at.region = Rect2((piece % 3) * 80, int(piece / 3) * 60, 80, 60)
		var b := TextureButton.new()
		b.texture_normal = at
		b.position = Vector2((pos % 3) * 80, int(pos / 3) * 60)
		b.disabled = solved
		if pos == map_sel:
			b.modulate = Color(1.3, 1.2, 0.8)
		b.pressed.connect(map_click.bind(pos))
		board.add_child(b)
	v.add_child(board)
	v.add_child(rt(G.doc(G.L.map.done) if solved else G.L.map.hint))
	w.set_content(paper(v, UI.PAPER, 2))

func map_click(pos: int) -> void:
	Sfx.play("key")
	if map_sel == -1:
		map_sel = pos
	elif map_sel == pos:
		map_sel = -1
	else:
		var t = map_order[pos]
		map_order[pos] = map_order[map_sel]
		map_order[map_sel] = t
		map_sel = -1
	if map_order == range(9) and not G.flag("map"):
		Sfx.play("chime")
		G.set_flag("map")
		G.achieve("MAP")
		say(G.L.lines.mapDone)
	D.win("map").rebuild()

# ---------------------------------------------------------------- шифровка
func _shift(text: String, sh: int) -> String:
	var ab: String = G.L.cipher.alphabet
	var n := ab.length()
	var out := ""
	for c in text.replace("ё", "е"):
		var i := ab.find(c)
		out += ab[(i + sh + n * 4) % n] if i >= 0 else c
	return out

func open_cipher() -> void:
	D.open_win("cipher", G.L.cipher.title, "noteRed", 230, 110, _cipher_build)
	first("cipherSeen", G.L.lines.cipherFirst, func(): G.pix.goal("cipher"))

func _cipher_build(w: OSWindow) -> void:
	var cp = G.L.cipher
	var solved := G.flag("cipher")
	var plain := G.plain(cp.text)
	var v := UI.vbox(3)
	v.add_child(UI.label(cp.hint, UI.INK2, null, 8, 216))
	if solved:
		v.add_child(rt(G.doc(cp.text)))
	else:
		v.add_child(rt("[color=#a8443c]%s[/color]" % G.esc(_shift(_shift(plain, int(cp.key)), -cipher_shift))))
		var row := UI.hbox(4)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(UI.button("<", func():
			cipher_shift -= 1
			cipher_turn()))
		row.add_child(UI.label(cp.shift % posmod(cipher_shift, String(cp.alphabet).length()), UI.INK))
		row.add_child(UI.button(">", func():
			cipher_shift += 1
			cipher_turn()))
		v.add_child(row)
	w.set_content(paper(v))

func cipher_turn() -> void:
	Sfx.play("key")
	var n: int = String(G.L.cipher.alphabet).length()
	if posmod(cipher_shift, n) == int(G.L.cipher.key) and not G.flag("cipher"):
		Sfx.play("chime")
		G.set_flag("cipher")
		G.achieve("CIPHER")
		say(G.L.lines.cipherDone)
	D.win("cipher").rebuild()

# ---------------------------------------------------------------- не_открывай
func open_dont() -> void:
	if G.flag("dontRead"):
		return
	var w := D.open_win("dontw", G.L.dontFile.title, "noteRed", 180, 80)
	var r := rt("")
	w.set_content(paper(r))
	for ch in String(G.L.dontFile.text):
		if not await G.sleep(0.09) or not is_instance_valid(r):
			return
		r.add_text(ch)
		Sfx.play("key", -8.0)
	if await G.sleep(1.4):
		G.fx.glitch()
		D.close_win("dontw")
		G.set_flag("dontRead")
		D.refresh_icons()
		say(G.L.lines.dont)

# ---------------------------------------------------------------- «Флажки»
var flag_round := 0
var flag_score := 0
var flag_seq: Array = []

func open_flags() -> void:
	D.open_win("flags", G.L.flags.title, "flags", 150, 130, func(w: OSWindow): _flags_menu(w, ""), UI.LIGHT)
	first("flagsSeen", G.L.lines.flagsFirst)

func _flags_menu(w: OSWindow, res: String) -> void:
	var fl = G.L.flags
	var v := UI.vbox(4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	if res != "":
		v.add_child(UI.label(res, UI.INK))
	v.add_child(UI.label(fl.record, UI.INK2))
	var go := UI.button(fl.start if res == "" else fl.again, func():
		var keys: Array = G.L.flags.countries.keys()
		keys.erase("mayak")
		keys.shuffle()
		flag_seq = keys.slice(0, 10)
		if G.stage() >= 3:
			flag_seq[9] = "mayak"
		flag_round = 0
		flag_score = 0
		_flags_round(w), "red")
	v.add_child(go)
	w.set_content(paper(v, UI.LIGHT, 6))

func _flags_round(w: OSWindow) -> void:
	if not is_instance_valid(w):
		return
	var fl = G.L.flags
	var key: String = flag_seq[flag_round]
	var v := UI.vbox(3)
	v.add_child(UI.label(fl.round % (flag_round + 1), UI.INK2))
	var t := TextureRect.new()
	t.texture = UI.tex("flag_" + key)
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.custom_minimum_size = Vector2(60, 40)
	v.add_child(t)
	var opts := [key]
	var others: Array = G.L.flags.countries.keys()
	others.erase("mayak")
	others.erase(key)
	others.shuffle()
	opts += others.slice(0, 3)
	opts.shuffle()
	if key == "mayak":
		opts = ["mayak", "mayak", "mayak", "mayak"]
	var g := GridContainer.new()
	g.columns = 2
	for o in opts:
		var ok: bool = o == key
		var b := UI.button(G.L.flags.countries[o], func(): pass)
		b.custom_minimum_size = Vector2(66, 0)
		b.clip_text = true
		b.pressed.connect(func():
			if key == "mayak":
				G.fx.glitch()
				say(G.L.lines.flagsDark)
			elif ok:
				flag_score += 1
				Sfx.play("chime", -8.0)
			else:
				Sfx.play("err")
				G.menus.toast(fl.wrong % G.L.flags.countries[key])
			flag_round += 1
			if flag_round >= 10:
				if flag_score > 8 and not G.flag("flagsBeat"):
					G.set_flag("flagsBeat")
					say(G.L.lines.flagsBeat)
				if flag_score == 10:
					G.achieve("FLAGS")
				_flags_menu(w, fl.result % flag_score)
			else:
				_flags_round(w))
		g.add_child(b)
	v.add_child(g)
	w.set_content(paper(v, UI.LIGHT, 4))
