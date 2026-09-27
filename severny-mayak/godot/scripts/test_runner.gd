extends Node
## Автотест версии 3: проходит ночи и все финалы, делает скриншоты.
## godot --path . -- --test [--lang=en] [--shots=/папка] [--only=a|t|b|c|title]

var failed := 0
var errors: Array = []
var scen := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = 10.0
	_run.call_deferred()

func shot(n: String) -> void:
	if G.shots_dir == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	G.screen.get_texture().get_image().save_png("%s/%s-%s-%s.png" % [G.shots_dir, G.settings.lang, scen, n])

func until(cond: Callable, sec := 60.0, what := "") -> bool:
	var t0 := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - t0 > sec * 1000.0:
			errors.append("timeout: " + what)
			return false
		await get_tree().process_frame
	return true

func wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout

func _run() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	if only in ["", "title"]:
		scen = "menu"
		G.menus.show_title()
		await wait(1.2)
		await shot("title")
		G.menus.open_panel("settings")
		await wait(0.4)
		await shot("settings")
		G.menus.panel.visible = false
		G.menus.show_help()
		await wait(0.4)
		await shot("help")
		G.menus.panel.visible = false
	for k in ["a", "t", "b", "c", "p", "s", "x"]:
		if only != "" and only != k:
			continue
		scen = k
		errors.clear()
		var ok = await _play(k)
		if ok and errors.is_empty():
			print("OK   %s ending %s: %s (night %d, палево max %d, дело %d, улики %d, Лёва %d ч)" % [G.settings.lang, k, G.L.endings[k].title,
				int(G.st.night), int(G.st.sus_max), int(G.st.case), int(G.st.pix), int(G.st.found_h)])
		else:
			failed += 1
			print("FAIL %s ending %s: %s" % [G.settings.lang, k, str(errors)])
			await shot("FAIL")
	print("TEST " + ("OK" if failed == 0 else "FAIL"))
	get_tree().quit(1 if failed else 0)

func solve(sid: String) -> void:
	var s := G.section(sid)
	var ans := G.section_blanks(s)
	for w in ans:
		G.collect(w)
	G.board.sel_section = sid
	for i in ans.size():
		G.board.sel_blank = i
		G.board.place(ans[i])

func to_night_end() -> void:
	G.st.mins = G.NIGHT_LEN - 1
	G.night.minute()

func _play(k: String) -> bool:
	G.meta.endings = {}
	G.main.start_run("new")
	if not await until(func(): return G.night.running, 30, "night 1 start"): return false
	await wait(0.5)
	await shot("n1-start")
	if not await until(func(): return G.st.f.get("goal", "") == "note", 30, "mom leaves"): return false
	await shot("n1-momleft")
	G.house.toggle(true)
	await wait(0.3)
	await shot("n1-house")
	G.house.toggle(false)
	G.docs.open_note()
	await wait(0.3)
	await shot("n1-point-lens")
	G.set_lens(true)
	G.collect("phone")
	if G.fget("goal", "") != "board":
		errors.append("tutorial: first word did not lead to the board")
	await wait(0.3)
	await shot("n1-note-lens")
	G.docs.open_web()
	G.docs.try_pin("0000")
	G.docs.try_pin("1403")
	G.docs.open_web()
	await wait(0.3)
	await shot("n1-web")
	if k == "a":
		# «Флажки»: у каждой страны есть картинка флага
		for c in G.L.flags.countries:
			if UI.tex("flag_" + c) == null:
				errors.append("no flag image: " + c)
		G.docs.open_flags()
		G.docs.flag_seq = ["fr", "jp", "ru", "de", "se", "br", "us", "gb", "it", "mayak"]
		G.docs.flag_round = 0
		G.docs._flags_round(G.desk.win("flags"))
		await wait(0.3)
		await shot("n1-flags")
		G.desk.close_win("flags")
	G.docs.open_drawing(2)
	G.docs.open_log()
	if k == "t":
		for i in 7:
			G.docs.collect_shard(i)
	solve("s1")
	G.board.toggle(true)
	await wait(0.4)
	await shot("n1-board")
	solve("s2")
	if not G.st.solved.has("s1") or not G.st.solved.has("s2"):
		errors.append("s1/s2 not solved")
	G.board.toggle(false)
	G.desk.close_all()
	G.docs.open_note()            # оставим одно окно открытым и одно свёрнутым — проверка должна их найти
	G.docs.open_log()
	G.desk.win("log").visible = false
	# визит: мама идёт в комнату в 23:35 (t=95)
	G.st.mins = 90
	G.night.minute()
	if not await until(func(): return G.stealth.phase == "in", 60, "visit in"): return false
	if not await until(func(): return G.stealth.found >= 2, 30, "check found traces"): return false
	await shot("n1-visit")
	var s0 := float(G.st.sus)
	var ev := InputEventMouseMotion.new()
	ev.position = Vector2(200, 150)
	ev.relative = Vector2(5, 0)
	G.screen.push_input(ev, true)
	await wait(0.4)
	G.screen.push_input(ev, true)
	if not await until(func(): return G.stealth.phase == "", 60, "visit end"): return false
	if not float(G.st.sus_max) > s0:
		errors.append("moving during visit did not raise exposure")
	# что спрятать/стереть до первого дня
	match k:
		"b": for f in ["web", "mail", "photos", "diary"]: G.docs.delete_file(f)
		"s": for f in ["log", "parental", "tale", "essay"]: G.docs.delete_file(f)
		"x": for f in ["mail", "diary"]: G.docs.delete_file(f)
		"a", "t":
			G.docs.hide_file("parental")
			G.docs.open_cache()
			await wait(0.3)
			await shot("n1-cache")
			G.desk.close_all()
	# конец ночи 1 → день 1: следователь
	to_night_end()
	if not await until(func(): return G.is_day() and G.stealth.phase == "in", 120, "day 1 cop in"): return false
	await wait(0.2)
	await shot("d1-check")
	if not await until(func(): return G.desk.win("inv") != null, 60, "day 1 inspect"): return false
	await wait(0.2)
	await shot("d1-copy")
	if k in ["a", "t"]:
		# звонок: курсор уже на почте — прячем её прямо из-под носа
		if not await until(func(): return G.day.away, 60, "day 1 away"): return false
		await shot("d1-away")
		G.docs.hide_file("log")
	if not await until(func(): return int(G.st.night) == 2 and G.night.running, 180, "night 2"): return false
	if G.st.copied.is_empty() or float(G.st.case) <= 0:
		errors.append("day 1 copied nothing")
	if k in ["a", "t"] and (G.st.copied.has("log") or G.st.copied.has("parental")):
		errors.append("hidden file was copied: %s" % str(G.st.copied))
	if k == "p" and not G.flag("lieDelete"):
		errors.append("Pixel did not lie about the parental log")
	if k in ["p", "s", "x"]:
		return await _police_run(k)
	await shot("n2-start")
	if k == "a":
		# рабочий стол изменился сам; шаги, которых нет
		if not G.flag("uFamily"):
			errors.append("family drawing did not change")
		if G.night.phantoms.is_empty():
			errors.append("no phantom steps planned for night 2")
		G.docs.open_drawing(2)
		await wait(0.3)
		await shot("n2-family")
		G.desk.close_all()
		G.stealth.phantom()
		await wait(0.2)
		await shot("n2-phantom")
		if not await until(func(): return G.flag("phantom1"), 30, "phantom steps"): return false
		# все галлюцинации по очереди + папа говорит в камеру
		G.docs.open_note()
		for kind in ["icon", "clock", "whisper", "cursor", "msg", "doc", "thought", "phantomIn", "gaze"]:
			G.madness.fire(kind)
			await wait(0.25)
			if kind in ["msg", "thought", "cursor"]:
				await shot("n2-mad-" + kind)
			if not await until(func(): return not G.madness.busy, 30, "madness " + kind): return false
		G.desk.close_all()
		G.night.script_dadTalk()
		await wait(0.8)
		await shot("n2-dadtalk")
		G.docs.open_essay()
		await wait(0.3)
		await shot("n2-essay")
		G.desk.close_all()
		# побочное: рыбка (ослабла за ночь), кормление, «Капитан и шторм», домашка, сны
		if int(G.fget("fish", 100)) >= 100:
			errors.append("fish did not get hungry")
		G.docs.open_fish()
		G.docs.feed_fish()
		await wait(0.3)
		await shot("n2-fish")
		G.docs.open_boat()
		G.docs._boat_play(G.desk.win("boat"))
		await wait(0.5)
		await shot("n2-boat")
		G.docs.restore(0)
		for i in 3:
			G.docs.open_dream(i)
		await wait(0.3)
		await shot("n2-dream")
		G.desk.close_all()
	G.st.mins = 21
	G.night.minute()
	if not await until(func(): return G.flag("momPolice"), 30, "mom police"): return false
	G.docs.open_chat()
	await wait(0.3)
	await shot("n2-chat")
	G.desk.close_all()
	G.docs.open_map()
	await wait(0.2)
	await shot("n2-map")
	G.docs.map_order = [0, 1, 2, 3, 4, 5, 6, 8, 7]
	G.docs.map_click(7)
	G.docs.map_click(8)
	if not G.flag("map"):
		errors.append("map not solved")
	if k == "b":
		G.docs.delete_file("map")
	G.docs.open_diary()
	G.docs.try_diary("северный маяк")
	await wait(0.3)
	await shot("n2-diary")
	if k == "b":
		# проигрыш и переигровка ночи
		G.stealth.add_sus(100, "cam")
		if not await until(func(): return G.ending == "caught", 20, "caught"): return false
		await wait(0.6)
		await shot("caught")
		G.main.start_run("night")
		if not await until(func(): return G.night.running and int(G.st.night) == 2, 30, "retry night"): return false
		G.set_flag("map")
		G.set_flag("diary")
	solve("s3")
	solve("s4")
	G.docs.open_tale()
	G.docs.open_chapter(3)
	await wait(0.3)
	await shot("n2-tale4")
	solve("s5")
	G.desk.close_all()
	G.docs.open_cipher()
	await wait(0.2)
	await shot("n2-cipher")
	for i in 3:
		G.docs.cipher_shift += 1
		G.docs.cipher_turn()
	if not G.flag("cipher"):
		errors.append("cipher not solved")
	if k == "b":
		G.docs.delete_file("cipher")
	G.docs.open_parental()
	solve("s6")
	if int(G.st.mem) < 100:
		errors.append("memory < 100: %d" % int(G.st.mem))
	G.board.toggle(true)
	await wait(0.3)
	await shot("n2-board-done")
	G.board.toggle(false)
	G.desk.close_all()
	G.docs.open_tm()
	await wait(0.3)
	await shot("n2-tm")
	for i in 3:
		G.docs.tm_sel = G.L.tm.guard[0]
		G.docs.end_process()
		await wait(0.3)
	if not await until(func(): return G.flag("guardKilled"), 30, "guard"): return false
	G.desk.close_all()
	G.docs.restore(1)
	await wait(0.3)
	await shot("n2-memfix")
	G.docs.mem_order = range(8)
	G.docs.mem_check()
	if not await until(func(): return G.flag("revealed"), 60, "reveal"): return false
	await shot("n2-reveal")
	if not await until(func(): return G.docs.choice_shown, 60, "choice"): return false
	await shot("n2-choice")
	match k:
		"a", "t": G.night.ending_tell()
		"b": G.night.ending_silent()
		"c": G.night.ending_pretend()
	if k == "t":
		if not await until(func(): return G.desk.win("letter") != null, 90, "epilogue"): return false
		await wait(0.3)
		await shot("epilogue")
	if not await until(func(): return G.ending == k, 120, "ending " + k): return false
	await wait(1.2)
	await shot("end")
	return true

## Сценарии, где Лёву находит следствие (p, s) или компьютер изымают (x): ночи просто проходят.
func _police_run(k: String) -> bool:
	for i in 4:
		if G.ending != "" and G.ending != "pending":
			break
		if not await until(func(): return G.night.running or G.ending in ["p", "s", "x", "b"], 180, "night"): return false
		if G.ending in ["p", "s", "x", "b"]:
			break
		if k == "x" and int(G.st.night) == 3:
			await wait(0.3)
			await shot("n3-seize")
		to_night_end()
		if not await until(func(): return G.is_day() or G.ending != "", 120, "day"): return false
		if not await until(func(): return int(G.st.night) > 1 and (G.night.running or G.ending in ["p", "s", "x", "b"]), 240, "day end"): return false
	if not await until(func(): return G.ending == k, 240, "ending " + k + " (got " + G.ending + ")"): return false
	await wait(1.2)
	await shot("end")
	return true
