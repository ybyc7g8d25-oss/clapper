class_name Story
extends Node
## Сюжет: три части одной ночи, развязка, финалы и эпилог.

var D: Desktop
var P: PixelVoice
var A: Apps

func refs() -> void:
	D = G.desk
	P = G.pix
	A = G.apps

func say(lines, cb := Callable()) -> void:
	P.say(lines, cb)

# ---------------------------------------------------------------- стадии мрачности
func set_stage(n: int, quiet := false) -> void:
	if n <= G.stage() and not quiet:
		return
	G.st.stage = n
	G.fx.set_stage(n, quiet)
	D.set_stage_visual(n, quiet)
	P.set_stage(n)
	Sfx.set_drone(n)
	if not quiet:
		G.fx.glitch()
	if D.win("cam"):
		A.render_cam()
	if D.win("tm"):
		A.render_tm()
	G.save_game()

# ---------------------------------------------------------------- запуск
func new_game() -> void:
	refs()
	G.st.ng = not G.meta.endings.is_empty()
	G.st.part = 1
	if G.st.ng:
		G.achieve("NG")
	G.meta.runs = int(G.meta.runs) + 1
	G.save_meta()
	G.clear_save()
	_apply_state()
	var lines: Array = G.L.boot.lines.duplicate()
	if G.st.ng:
		lines[lines.size() - 1] = G.L.boot.ng
	await G.menus.boot(lines)
	await G.menus.part_card(1)
	_enter_desktop()
	Sfx.play("chime")
	G.achieve("BOOT")
	if not await G.sleep(0.9):
		return
	P.show_pix()
	say(G.L.lines.bootNg if G.st.ng else G.L.lines.boot, func(): P.goal("note"))

func continue_game(save: Dictionary) -> void:
	refs()
	G._merge(G.st, save)
	G.st.erase("v")
	G.st.mom_online = false
	_apply_state()
	await G.menus.boot(G.L.boot.lines if int(G.st.part) == 1 else G.L.wake.boot)
	_enter_desktop()
	Sfx.play("chime")
	if not await G.sleep(0.7):
		return
	P.show_pix()
	P.goal(G.st.goal)
	if G.flag("note"):
		G.stealth.schedule_visit(30.0)
	say(G.L.lines.welcome[G.stage()], func():
		if G.flag("restored") and not G.flag("revealed"):
			reveal()
		elif G.flag("revealed"):
			mom_online()
		elif int(G.st.part) == 1 and G.flag("p1done"):
			curfew()
		elif int(G.st.part) == 2 and G.flag("p2done"):
			dad_scene())

func _apply_state() -> void:
	G.in_game = true
	G.ending = ""
	A.reset_chats()
	D.build_icons(A.desk_list())
	D.fill_start_menu(A.start_menu_items())
	D.show_clock()
	D.update_shards()
	set_stage(G.stage(), true)
	G.stealth.render()
	G.save_game()

func _enter_desktop() -> void:
	D.visible = true
	Sfx.set_drone(G.stage())

# ---------------------------------------------------------------- часть 1
func mom_police_later() -> void:
	if not await G.sleep(9.0) or G.flag("momPolice"):
		return
	G.set_flag("momPolice")
	A.CHATS.mama.ms.append(["06.10 " + G.clock_str(int(G.st.mins)), G.L.chat.momPolice])
	A.render_chat()
	A.chat_notify()
	D.open_win("chat", G.L.chat.title, "chat", 600, 420)
	A.render_chat()
	say(G.L.lines.momPolice, func(): P.goal("where"))
	check_part1()

func check_part1() -> void:
	if int(G.st.part) != 1 or G.flag("p1done") or not (G.flag("web") and G.flag("momPolice")):
		return
	var n := 0
	for k in ["mail_gran", "mem", "tale1", "tower"]:
		if G.flag(k):
			n += 1
	if n < 2:
		return
	G.set_flag("p1done")
	if await G.sleep(25.0):
		curfew()

func curfew() -> void:
	if int(G.st.part) != 1:
		return
	var cf = G.L.curfew
	var w := D.open_win("curfew", cf.title, "info", 380, 150)
	var lab := UI.label("", null, 16, UI.INK, true)
	w.set_content(UI.margin(lab, 14))
	Sfx.play("err")
	say(G.L.lines.curfew)
	for s in range(15, -1, -1):
		if not is_instance_valid(lab):
			break
		lab.text = cf.text % s
		if not await G.sleep(1.0):
			return
	await to_part(2)

## Переход к части n: экран гаснет, заставка, новое время.
func to_part(n: int) -> void:
	G.stealth.reset_visits()
	P.reset()
	P.show_pix(false)
	Sfx.stop_drone()
	await G.menus.fade_black(true)
	D.close_all()
	G.st.part = n
	G.st.mins = 23 * 60 + 58 if n == 2 else 3 * 60 + 12
	D.build_icons(A.desk_list())
	D.show_clock()
	G.save_game()
	await G.menus.part_card(n)
	if n == 2:
		await G.menus.boot(G.L.wake.boot)
	G.menus.fade_black(false)
	Sfx.set_drone(G.stage())
	if not await G.sleep(0.8):
		return
	P.show_pix()
	if n == 2:
		say(G.L.lines.wake, func():
			P.goal("map")
			G.stealth.schedule_visit(40.0))
		_dima_night()
	else:
		say(G.L.lines.part3, func():
			P.goal("bin")
			G.stealth.schedule_visit(45.0))

# ---------------------------------------------------------------- часть 2
func _dima_night() -> void:
	if not await G.sleep(95.0) or G.flag("dimaNight") or int(G.st.part) != 2:
		return
	G.set_flag("dimaNight")
	A.CHATS.dima.ms.append(["07.10 00:41", G.L.chat.dimaNight])
	A.render_chat()
	A.chat_notify()
	say(G.L.lines.dimaNight)

func check_part2() -> void:
	if int(G.st.part) != 2 or G.flag("p2done"):
		return
	if not (G.flag("map") and G.flag("diary") and G.flag("tale3") and G.flag("cipher")):
		return
	G.set_flag("p2done")
	if not await G.sleep(3.0):
		return
	await P.say_wait(G.L.lines.part2End)
	if await G.sleep(6.0):
		dad_scene()

## Папа не спит: заходит, садится за стол, смотрит в камеру и выключает монитор.
func dad_scene() -> void:
	G.stealth.reset_visits()
	await G.stealth.scripted_visit(G.L.visit.dad, 5.0)
	if G.ending != "":
		return
	D.open_win("cam", G.L.cam.title, "cam", 488, 336)
	A.render_cam(true)
	Sfx.play("heart")
	G.fx.glitch(0.4)
	await P.say_wait(G.L.lines.dadSits)
	if not await G.sleep(1.2):
		return
	Sfx.play("click")
	await to_part(3)

# ---------------------------------------------------------------- развязка
func reveal() -> void:
	if G.flag("revealed"):
		return
	G.set_flag("revealed")
	set_stage(3)
	say(G.L.lines.reveal, mom_online)

func mom_online() -> void:
	G.stealth.reset_visits()
	G.st.mom_online = true
	A.CHATS.mama.on = true
	A.chat_sel = "mama"
	Sfx.play("msg")
	G.save_game()
	G.stealth.render()
	P.goal("mom")
	A.open_chat()
	var t := func(): return "07.10 " + G.clock_str(int(G.st.mins))
	if not await G.sleep(1.5): return
	Sfx.play("msg")
	A.push_msg("mama", t.call(), G.L.chat.momOn1)
	if not await G.sleep(2.7): return
	Sfx.play("msg")
	A.push_msg("mama", t.call(), G.L.chat.momOn2)
	if not await G.sleep(2.0): return
	A.choice_shown = true
	A.render_chat()
	say(G.L.lines.choice)

func _lock() -> void:
	G.ending = "pending"
	A.render_chat()

func _t() -> String:
	return "07.10 " + G.clock_str(int(G.st.mins))

# ---------------------------------------------------------------- финал А: правда (и настоящий)
func ending_tell() -> void:
	_lock()
	P.goal("")
	P.reset()
	var a = G.L.endA
	A.chat_sel = "mama"
	A.push_msg("mama", "me", a.msg)
	if not await G.sleep(1.4): return
	A.push_msg("mama", "st", G.L.chat.typing)
	if not await G.sleep(2.0): return
	A.CHATS.mama.ms.pop_back()
	Sfx.play("msg")
	A.push_msg("mama", _t(), a.r1)
	if not await G.sleep(1.2): return
	Sfx.play("msg")
	A.push_msg("mama", _t(), a.r2)
	if not await G.sleep(1.6): return
	A.CHATS.mama.on = false
	Sfx.play("door")
	A.push_msg("mama", "st", G.L.chat.momOff)
	say(a.run)
	if not await G.sleep(4.8): return
	G.fx.glitch()
	G.st.mins = 6 * 60 + 15
	D.show_clock()
	G.fx.flash(0.5, 0.4)
	if not await G.sleep(1.5): return
	A.CHATS.mama.on = true
	Sfx.play("msg")
	A.push_msg("mama", "07.10 06:15", a.f1)
	if not await G.sleep(2.5): return
	Sfx.play("msg")
	A.push_msg("mama", "07.10 06:16", a.f2)
	if not await G.sleep(2.5): return
	Sfx.play("msg")
	A.push_msg("mama", "07.10 06:18", a.f3)
	await P.say_wait(a.after)
	if G.st.shards.size() == G.L.shards.size():
		await P.say_wait(a.askShards)
		A.push_msg("mama", "me", a.shardMsg)
		if not await G.sleep(2.6): return
		Sfx.play("msg")
		A.push_msg("mama", "07.10 06:24", a.shardReply)
		if not await G.sleep(1.8): return
		uninstall(true)
	else:
		uninstall(false)

func uninstall(full: bool) -> void:
	var a = G.L.endA
	var w := D.open_win("un", a.unTitle, "pixel", 400, 150)
	var v := UI.vbox(8)
	v.add_child(UI.label(a.unProg, null, 16, UI.INK))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	bar.add_theme_stylebox_override("background", UI.flat(Color.WHITE, Color("#7f8aa0"), 2, 0, 0))
	bar.add_theme_stylebox_override("fill", UI.flat(UI.MINT, UI.MINT, 0, 0, 0))
	v.add_child(bar)
	var part := UI.label(a.parts[0], null, 16, UI.GREY)
	v.add_child(part)
	w.set_content(UI.margin(v, 14))
	var li := 0
	for p in range(0, 101, 2):
		if not await G.sleep(0.26):
			return
		bar.value = p
		part.text = a.parts[mini(a.parts.size() - 1, int(p / 17))]
		if p % 30 == 0 and p > 0 and li < a.unLines.size():
			say([a.unLines[li]])
			li += 1
		if p == 60:
			P.root.modulate.a = 0.6
	if not await G.sleep(2.6):
		return
	P.show_pix(false)
	if full:
		true_epilogue()
	else:
		show_end("a")

## Настоящий финал: компьютер отформатирован, через месяц его включает Лёва.
func true_epilogue() -> void:
	G.ending = "pending"
	D.close_all()
	P.reset()
	Sfx.stop_drone()
	await G.menus.fade_black(true)
	await G.menus.boot(G.L.endT.boot)
	G.st.stage = 0
	G.fx.set_stage(0, true)
	D.set_epilogue_wall()
	D.build_icons([{"id": "letter", "ic": "note", "label": func(): return G.L.endT.file, "open": _open_letter}])
	D.sus_box.visible = false
	D.frag_btn.visible = false
	G.st.mins = 16 * 60 + 5
	D.show_clock()
	G.menus.fade_black(false)
	Sfx.play("soft")
	if await G.sleep(3.5):
		_open_letter()

func _open_letter() -> void:
	if D.win("letter"):
		return
	var w := D.open_win("letter", G.L.endT.fileTitle, "note", 470, 420)
	w.set_content(A.paper_rich(G.esc(G.L.endT.text)))
	w.on_close = func(): get_tree().create_timer(0.9, false).timeout.connect(func(): show_end("t"))
	if await G.sleep(45.0):
		show_end("t")

# ---------------------------------------------------------------- финал Б: молчание
func ending_silent() -> void:
	_lock()
	P.goal("")
	P.reset()
	var b = G.L.endB
	say(b.think)
	if not await G.sleep(3.0): return
	Sfx.play("msg")
	A.push_msg("mama", _t(), b.m1)
	if not await G.sleep(3.5): return
	A.CHATS.mama.on = false
	A.push_msg("mama", "st", G.L.chat.momOff)
	await _pass_days(b.days, b.talk, 2.5, func(d, _i): P.goal_text(d + b.dayGoal))
	show_end("b")

func _pass_days(days: Array, talk: Array, start: float, on_day: Callable) -> void:
	if not await G.sleep(start):
		return
	for i in days.size():
		G.fx.glitch()
		G.st.mins = (int(G.st.mins) + 997) % (24 * 60)
		D.show_clock()
		var ids := D.visible_icon_ids()
		ids.erase("pixel")
		if ids.size():
			D.hide_icon(ids[ids.size() - 1])
		for k in D.W.keys():
			if k != "chat" and randf() < 0.6:
				D.close_win(k)
		on_day.call(days[i], i)
		P.reset()
		say([talk[i]])
		if not await G.sleep(5.2):
			return
	await G.sleep(2.5)

# ---------------------------------------------------------------- финал В: голос капитана
func ending_pretend() -> void:
	_lock()
	P.goal("")
	P.reset()
	var c = G.L.endC
	var lie := func(text: String, time := ""):
		Sfx.play("key")
		A.push_msg("mama", "lie", text, time if time != "" else _t())
	lie.call(c.lie1)
	if not await G.sleep(1.5): return
	say(c.think1)
	if not await G.sleep(1.8): return
	Sfx.play("msg")
	A.push_msg("mama", _t(), c.r1)
	if not await G.sleep(2.4): return
	lie.call(c.lie2)
	if not await G.sleep(1.8): return
	Sfx.play("msg")
	A.push_msg("mama", _t(), c.r2)
	say(c.think2)
	if not await G.sleep(6.5): return
	Sfx.play("msg")
	G.fx.glitch()
	A.push_msg("mama", _t(), c.r3)
	if not await G.sleep(1.8): return
	Sfx.play("msg")
	A.push_msg("mama", _t(), c.r4)
	if not await G.sleep(2.2): return
	lie.call(c.lie3)
	if not await G.sleep(1.6): return
	A.CHATS.mama.on = false
	A.push_msg("mama", "st", G.L.chat.momOff)
	if not await G.sleep(1.4): return
	lie.call(c.lie4)
	await _pass_days(c.days, c.talk, 4.0, func(d, _i):
		P.goal_text(d)
		lie.call(c.talk[3], d))
	show_end("c")

# ---------------------------------------------------------------- экран финала
func show_end(k: String) -> void:
	if G.ending != "" and G.ending != "pending":
		return
	G.stealth.reset_visits()
	G.ending = k
	G.in_game = false
	G.meta.endings[k] = G.meta.endings.get(k, Time.get_unix_time_from_system())
	G.save_meta()
	G.clear_save()
	G.achieve({"a": "END_A", "b": "END_B", "c": "END_C", "t": "END_T"}[k])
	if k == "t":
		G.achieve("END_A")
	if float(G.st.sus_max) < 35.0:
		G.achieve("GHOST")
	P.reset()
	if k in ["a", "t"]:
		Sfx.play("sad")
		Sfx.stop_drone()
	else:
		Sfx.set_drone(3)
	G.menus.show_end(k)
