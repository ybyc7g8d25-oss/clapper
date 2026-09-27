class_name Night
extends Node
## Ночной цикл: время идёт (22:00 → 06:00), по расписанию в доме происходят события,
## решённые разделы доски двигают сюжет. В конце ночи — отчёт; правда — развязка и финал.

const SEC_PER_MIN := 1.8       # 1 игровая минута = 1,8 с (ночь ≈ 14 минут; «ждать» — в 6 раз быстрее)
var running := false
var events: Array = []
var ev_i := 0
var _acc := 0.0
var phantoms: Array = []       # минуты ночи, когда Пикселю послышатся шаги, которых нет

func say(lines, cb := Callable()) -> void:
	G.pix.say(lines, cb)

# ---------------------------------------------------------------- запуск
func new_game() -> void:
	G.new_state()
	G.st.ng = not G.meta.endings.is_empty()
	G.meta.runs = int(G.meta.runs) + 1
	G.save_meta()
	G.clear_save()
	start_night(true)

func resume(s: Dictionary, from_start := false) -> void:
	if s.is_empty():
		new_game()
		return
	G._merge(G.st, s)
	G.st.mom_online = false
	if G.st.phase == "day":
		# день всегда начинается заново с контрольной точки
		var cp := G.load_night()
		if not cp.is_empty():
			G._merge(G.st, cp)
		G.st.mom_online = false
		G.day.run()
		return
	start_night(from_start)

func start_night(fresh: bool) -> void:
	G.in_game = true
	G.ending = ""
	var n: int = int(G.st.night)
	G.st.phase = "night"
	if fresh:
		G.st.mins = 0
		G.save_night()
	G.docs.reset_chats()
	# между ночами рабочий стол меняется сам (никто, кроме Пикселя, к нему не прикасался)
	# рыбка: каждую новую ночь слабеет, кормить можно раз за ночь
	if fresh and n >= 2 and not G.flag("fishDead"):
		G.st.f["fish"] = int(G.fget("fish", 100)) - 45
		if int(G.st.f.fish) <= 0:
			G.st.f["fishDead"] = 1
	if fresh:
		G.st.f.erase("fedToday")
	for k in [["uFamily", 2], ["uLog", 3], ["uPhoto", 4]]:
		if n >= int(k[1]) and not G.flag(k[0]):
			G.st.f[k[0]] = 1
	G.desk.build_icons(G.docs.desk_list())
	update_stage(true)
	G.hud.refresh()
	G.stealth.render()
	# перед самой первой ночью — «Как играть» (потом его можно открыть из паузы)
	if fresh and n == 1 and not G.meta.get("helpSeen", false) and not G.TEST:
		await G.menus.show_help(true)
		G.meta["helpSeen"] = true
		G.save_meta()
	await G.menus.night_card(n)
	# события ночи по порядку; всё, что уже прошло, применяется сразу
	events = G.L.events[clampi(n - 1, 0, G.L.events.size() - 1)].duplicate(true)
	events.sort_custom(func(a, b): return a.t < b.t)
	ev_i = 0
	_plan_phantoms(n)
	var pos := {}
	while ev_i < events.size() and int(events[ev_i].t) <= int(G.st.mins):
		var e: Dictionary = events[ev_i]
		if e.type == "house":
			pos[e.who] = e.room
		ev_i += 1
	for who in ["mom", "dad"]:
		G.house.place(who, pos.get(who, "bed"))
	G.house.place("cop", "out")
	G.house.set_day(false)
	Sfx.set_drone(G.stage())
	G.pix.show_pix(true)
	G.pix.goal(String(G.fget("goal", "")))
	running = true
	if fresh:
		match n:
			1: say(G.L.lines.bootNg if G.st.ng else G.L.lines.boot, func(): G.pix.goal("freeze"))
			2: say(G.L.lines.night2, func(): G.pix.goal("night2"))
			3: say(G.L.lines.night3)
			4: say(G.L.lines.night4)
			_: say(G.L.lines.night5)
		if G.flag("seize"):
			say(G.L.lines.seizeWarn)
		if G.flag("lieDelete") and G.file_state("parental") == "deleted" and not G.flag("lieDeletedSaid"):
			G.set_flag("lieDeletedSaid")
			say(G.L.lines.lieDeleted)
	else:
		say(G.L.lines.welcome)
		if G.flag("revealed"):
			mom_online()

func _process(delta: float) -> void:
	if not running or G.ending != "" or get_tree().paused or G.flag("monitorOffNow"):
		if G.flag("monitorOffNow") and running and not get_tree().paused:
			_acc += delta * 3.0
			_tick_acc()
		return
	_acc += delta * (6.0 if G.hud.fast else 1.0)
	_tick_acc()

func _tick_acc() -> void:
	while _acc >= SEC_PER_MIN:
		_acc -= SEC_PER_MIN
		minute()

func minute() -> void:
	G.st.mins = int(G.st.mins) + 1
	G.hud.refresh()
	while ev_i < events.size() and int(events[ev_i].t) <= int(G.st.mins):
		fire(events[ev_i])
		ev_i += 1
	if phantoms.has(int(G.st.mins)):
		G.stealth.phantom()
	if int(G.st.mins) % 5 == 0:
		G.save_game()
	if int(G.st.mins) >= G.NIGHT_LEN and not G.st.mom_online and not G.flag("revealed"):
		end_night()

func fire(e: Dictionary) -> void:
	match String(e.type):
		"house":
			G.house.move(e.who, e.room)
		"mic":
			G.hud.set_fast(false)
			G.docs.mic_event(e.lines)
		"msg":
			G.set_flag(e.id)
			G.docs.reset_chats()
			G.docs.chat_notify()
			var w: OSWindow = G.desk.win("chat")
			if w:
				w.rebuild()
			G.hud.set_fast(false)
		"script":
			call("script_" + String(e.id))

## Со второй ночи Пиксель иногда слышит шаги, которых нет. Не рядом с настоящими визитами.
func _plan_phantoms(n: int) -> void:
	phantoms.clear()
	if n < 2:
		return
	var busy := []
	for e in events:
		if e.type == "house" and String(e.room) in ["lev", "levbed"]:
			busy.append(int(e.t))
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 7919 + int(G.meta.runs)
	var tries := 0
	while phantoms.size() < mini(n - 1, 3) and tries < 200:
		tries += 1
		var m := rng.randi_range(40, 440)
		var ok := true
		for b in busy + phantoms:
			if absi(int(b) - m) < 25:
				ok = false
		if ok:
			phantoms.append(m)

# ---------------------------------------------------------------- сценки
func script_momLeft() -> void:
	say(G.L.lines.momLeft, func(): G.pix.goal("note"))

## Папа садится за компьютер и говорит прямо в камеру — Пикселю. Он в комнате: замри.
func script_dadTalk() -> void:
	G.hud.set_fast(false)
	for l in G.L.scenes.dadTalk:
		if not await G.sleep(3.2):
			return
		G.menus.subtitle(G.L.speakers[l[0]], l[1], 3.0)
	if not await G.sleep(3.4):
		return
	G.pix.say(G.L.lines.dadTalk)

func script_dadCam() -> void:
	G.hud.set_fast(false)
	G.set_flag("dadCamNow")
	G.docs.open_cam()
	G.docs.refresh_cam()
	Sfx.play("heart")
	await G.pix.say_wait(G.L.lines.dadCam)
	if not await G.sleep(4.0):
		return
	G.st.f.erase("dadCamNow")
	G.set_flag("monitorOffNow")
	G.set_flag("monitorOff")
	G.menus.monitor_off(true)
	Sfx.play("click")
	say(G.L.lines.dadOff)
	if not await G.sleep(12.0):
		return
	G.st.f.erase("monitorOffNow")
	G.st.f.erase("monitorOff")
	G.menus.monitor_off(false)
	G.docs.refresh_cam()

# ---------------------------------------------------------------- стадии мрачности
func update_stage(instant := false) -> void:
	var s := G.stage()
	var target := s
	if int(G.st.night) >= 2 or G.st.solved.size() >= 2:
		target = maxi(target, 1)
	if int(G.st.night) >= 3 or int(G.st.mem) >= 60:
		target = maxi(target, 2)
	if G.flag("revealed"):
		target = 3
	set_stage(target, instant)

func set_stage(n: int, instant := false) -> void:
	var changed := n != G.stage()
	G.st.stage = n
	G.fx.set_stage(n, instant)
	G.desk.set_stage_visual(n)
	G.house.set_stage(n)
	G.pix.set_stage(n)
	Sfx.set_drone(n)
	if changed and not instant:
		G.fx.glitch()
	if n >= 2 and not G.flag("dontShown"):
		_dont_later()

func _dont_later() -> void:
	if not await G.sleep(30.0) or G.flag("dontShown"):
		return
	G.set_flag("dontShown")
	G.desk.refresh_icons()
	G.fx.glitch()
	say(G.L.lines.dontAppear)

# ---------------------------------------------------------------- доска
func on_solved(sid: String) -> void:
	var lines: Array = []
	if not G.flag("firstRight"):
		G.set_flag("firstRight")
		lines += G.L.lines.firstRight
	lines += G.L.lines.get(sid, [])
	say(lines)
	update_stage()
	match sid:
		"s1", "s2":
			if G.st.solved.has("s1") and G.st.solved.has("s2"):
				G.pix.goal("wait")
		"s3":
			G.docs.say(G.L.lines.taleNew)
			G.pix.goal("tale")
		"s4":
			G.desk.refresh_icons()
			G.desk.blink_icon("cipher")
		"s5":
			# Пиксель понял, что главу написал он, — и уводит от журнала контроля
			if not G.st.solved.has("s6") and not G.flag("lieCaught"):
				G.pix.goal("lie")
	if int(G.st.mem) >= 100:
		G.pix.goal("guard")
		G.desk.blink_icon("tm")

# ---------------------------------------------------------------- конец ночи
func end_night() -> void:
	running = false
	G.hud.set_fast(false)
	G.stealth.reset_visits()
	await G.pix.say_wait(G.L.lines.endNight)
	var n: int = int(G.st.night)
	if n == 1:
		G.achieve("NIGHT1")
	G.desk.close_all()
	G.board.toggle(false)
	await G.menus.report(n)
	if G.ending != "":
		return
	# днём за компьютер садится следователь
	G.day.run()

# ---------------------------------------------------------------- развязка
func reveal() -> void:
	if G.flag("revealed"):
		return
	G.set_flag("revealed")
	if int(G.st.night) <= 2:
		G.achieve("FAST")
	update_stage()
	var lines: Array = G.L.lines.reveal.duplicate()
	if G.flag("lieDelete"):
		lines += G.L.lines.lieConfess
	say(lines, mom_online)

func mom_online() -> void:
	G.stealth.reset_visits()
	G.st.mom_online = true
	G.docs.CHATS.mama.on = true
	G.docs.chat_sel = "mama"
	G.stealth.render()
	G.pix.goal("mom")
	G.docs.open_chat()
	Sfx.play("msg")
	if not await G.sleep(1.5): return
	G.docs.push_msg("mama", G.clock(), G.L.chat.momOn1)
	Sfx.play("msg")
	if not await G.sleep(2.5): return
	G.docs.push_msg("mama", G.clock(), G.L.chat.momOn2)
	Sfx.play("msg")
	if not await G.sleep(1.5): return
	G.docs.choice_shown = true
	G.desk.win("chat").rebuild() if G.desk.win("chat") else null
	say(G.L.lines.choice)

func _lock() -> void:
	G.ending = "pending"
	running = false
	G.pix.goal("")
	G.pix.reset()
	if G.desk.win("chat"):
		G.desk.win("chat").rebuild()

func ending_tell() -> void:
	_lock()
	var a = G.L.endA
	var D: Docs = G.docs
	D.push_msg("mama", "me", a.msg)
	if not await G.sleep(1.5): return
	D.push_msg("mama", "st", G.L.chat.typing)
	if not await G.sleep(2.0): return
	D.CHATS.mama.ms.pop_back()
	Sfx.play("msg")
	D.push_msg("mama", G.clock(), a.r1)
	if not await G.sleep(1.2): return
	Sfx.play("msg")
	D.push_msg("mama", G.clock(), a.r2)
	if not await G.sleep(1.5): return
	D.CHATS.mama.on = false
	Sfx.play("door")
	G.house.move("mom", "out")
	G.house.sound(250, G.L.snd.door)
	D.push_msg("mama", "st", G.L.chat.momOff)
	await G.pix.say_wait(a.run)
	if not await G.sleep(3.0): return
	G.fx.flash(0.5, 0.4)
	var idx := G.leva_idx(G.hours_gone())
	D.CHATS.mama.on = true
	Sfx.play("msg")
	D.push_msg("mama", "06:15", a.found[idx])
	if not await G.sleep(2.5): return
	if idx < 3:
		D.push_msg("mama", "06:16", a.f2)
		if not await G.sleep(2.0): return
		D.push_msg("mama", "06:18", a.f3)
		await G.pix.say_wait(a.after)
	if G.st.shards.size() == G.L.shards.size() and idx < 3:
		await G.pix.say_wait(a.askShards)
		D.push_msg("mama", "me", a.shardMsg)
		if not await G.sleep(2.2): return
		D.push_msg("mama", "06:24", a.shardReply)
		if not await G.sleep(1.5): return
		uninstall(true)
	else:
		uninstall(false)

func uninstall(full: bool) -> void:
	var a = G.L.endA
	var w: OSWindow = G.desk.open_win("un", a.unTitle, "pixel", 200, 50, Callable(), UI.LIGHT)
	var v := UI.vbox(3)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 6)
	bar.add_theme_stylebox_override("background", UI.flat(UI.PAPER, UI.INK, 1, 0, 0))
	bar.add_theme_stylebox_override("fill", UI.flat(UI.RED, UI.RED, 0, 0, 0))
	v.add_child(bar)
	var part := UI.label(a.parts[0], UI.INK)
	v.add_child(part)
	w.set_content(UI.panel(v, UI.LIGHT, Color(0, 0, 0, 0), 0, 5))
	var li := 0
	for p in range(0, 101, 2):
		if not await G.sleep(0.22):
			return
		bar.value = p
		part.text = a.parts[mini(a.parts.size() - 1, p / 17)]
		if p % 30 == 0 and p > 0 and li < a.unLines.size():
			say([a.unLines[li]])
			li += 1
	if not await G.sleep(2.0):
		return
	G.pix.show_pix(false)
	if full:
		true_epilogue()
	else:
		show_end("a")

func true_epilogue() -> void:
	G.desk.close_all()
	Sfx.stop_drone()
	await G.menus.fade(true)
	G.st.stage = 0
	G.fx.set_stage(0, true)
	G.desk.wall.texture = UI.tex("wall")
	G.desk.build_icons([{"id": "letter", "ic": "note", "label": func(): return G.L.endT.file.get_basename(), "open": _letter}])
	G.house.visible = true
	await G.menus.fade(false)
	Sfx.play("soft")
	if await G.sleep(2.5):
		_letter()

func _letter() -> void:
	if G.desk.win("letter"):
		return
	var w: OSWindow = G.desk.open_win("letter", G.L.endT.file, "note", 220, 170, func(ww: OSWindow):
		ww.set_content(UI.scroll(G.docs.paper(G.docs.rt(G.esc(G.L.endT.text))))))
	w.on_close = func(): show_end("t")
	if await G.sleep(40.0):
		show_end("t")

func ending_silent() -> void:
	_lock()
	var b = G.L.endB
	say(b.think)
	if not await G.sleep(3.0): return
	Sfx.play("msg")
	G.docs.push_msg("mama", G.clock(), b.m1)
	if not await G.sleep(3.0): return
	G.docs.CHATS.mama.on = false
	G.docs.push_msg("mama", "st", G.L.chat.momOff)
	await _pass_days(["…", "…", "…"])
	# дальше ищут без Пикселя: успеет ли следствие
	if G.day.simulate() == "police":
		show_end("p" if float(G.st.pix) >= 50.0 else "s")
	else:
		show_end("b")

func ending_pretend() -> void:
	_lock()
	var c = G.L.endC
	var D: Docs = G.docs
	D.push_msg("mama", "lie", c.lie1)
	if not await G.sleep(1.5): return
	say(c.think1)
	if not await G.sleep(1.8): return
	Sfx.play("msg")
	D.push_msg("mama", G.clock(), c.r1)
	if not await G.sleep(2.2): return
	D.push_msg("mama", "lie", c.lie2)
	if not await G.sleep(1.8): return
	D.push_msg("mama", G.clock(), c.r2)
	if not await G.sleep(5.0): return
	G.fx.glitch()
	D.push_msg("mama", G.clock(), c.r3)
	if not await G.sleep(1.8): return
	D.push_msg("mama", G.clock(), c.r4)
	if not await G.sleep(2.0): return
	D.push_msg("mama", "lie", c.lie3)
	if not await G.sleep(1.5): return
	D.CHATS.mama.on = false
	D.push_msg("mama", "st", G.L.chat.momOff)
	D.push_msg("mama", "lie", c.lie4)
	await _pass_days(["23:58", "23:58", "23:58"])
	show_end("c")

func _pass_days(labels: Array) -> void:
	for l in labels:
		if not await G.sleep(4.0):
			return
		G.fx.glitch()
		var ids: Array = G.desk.icon_nodes.keys()
		if ids.size() > 1:
			G.desk.icon_nodes[ids[ids.size() - 1]].visible = false
			G.desk.icon_nodes.erase(ids[ids.size() - 1])
		G.pix.goal_text(l)
	await G.sleep(2.0)

func show_end(k: String) -> void:
	if G.ending != "" and G.ending != "pending":
		return
	G.stealth.reset_visits()
	running = false
	G.ending = k
	G.in_game = false
	G.meta.endings[k] = G.meta.endings.get(k, Time.get_unix_time_from_system())
	G.save_meta()
	G.clear_save()
	G.achieve("END_" + k.to_upper())
	if k == "t":
		G.achieve("END_A")
	if k in ["a", "t"] and not G.flag("fishDead") and G.flag("fishFed"):
		G.achieve("FISH")
	if float(G.st.sus_max) < 35.0:
		G.achieve("GHOST")
	G.pix.reset()
	if k in ["a", "t"]:
		Sfx.play("sad")
		Sfx.stop_drone()
	else:
		Sfx.set_drone(3)
	G.menus.show_end(k)
