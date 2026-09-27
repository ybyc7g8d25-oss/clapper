extends Node
## Автотест: проходит игру целиком во всех финалах и делает скриншоты.
## Запуск:  godot --path . -- --test [--lang=en] [--shots=/папка] [--only=a]
## (в конце печатает TEST OK / TEST FAIL и выходит с кодом 0/1)

var failed := 0
var shots := ""
var errors: Array = []
var scen := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	shots = G.shots_dir
	Engine.time_scale = 10.0
	_run.call_deferred()

func shot(name: String) -> void:
	if shots == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s-%s-%s.png" % [shots, G.settings.lang, scen, name])

func until(cond: Callable, sec := 60.0, what := "") -> bool:
	var t0 := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - t0 > sec * 1000.0:
			push_error("timeout: " + what)
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
	if only == "" or only == "title":
		scen = "menu"
		G.menus.show_title()
		await wait(1.5)
		await shot("title")
		G.menus.open_panel("settings")
		await wait(0.5)
		await shot("settings")
		G.menus.panel.visible = false
	for k in ["a", "t", "b", "c"]:
		if only != "" and only != k and only != "title":
			continue
		if only == "title":
			break
		scen = k
		errors.clear()
		var ok = await _play(k)
		if ok and errors.is_empty():
			print("OK   %s ending %s: %s  (палево max %d)" % [G.settings.lang, k, G.L.endings[k].title, int(G.st.sus_max)])
		else:
			failed += 1
			print("FAIL %s ending %s: %s" % [G.settings.lang, k, str(errors)])
			await shot("FAIL")
	print("TEST " + ("OK" if failed == 0 else "FAIL"))
	get_tree().quit(1 if failed else 0)

func _play(k: String) -> bool:
	var A: Apps
	G.meta.endings = {}
	G.main.start_run(false)
	A = G.apps
	if not await until(func(): return G.st.goal == "note", 30, "boot"): return false
	await shot("desk-part1")
	A.open_note()
	if not await until(func(): return G.st.goal == "find", 30, "note lines"): return false
	A.open_drawings()
	A.open_drawing(1)
	A.open_drawing(2)
	await shot("drawing-family")
	A.open_log()
	A.open_cam()
	if k == "t":
		for i in 7:
			A.collect_shard(i)
	G.desk.close_all()
	A.open_browser()
	await wait(0.3)
	await shot("pin")
	A.try_pin("0000")
	A.try_pin("1403")
	if not await until(func(): return G.stage() == 1, 30, "stage 1"): return false
	await shot("history")
	if not await until(func(): return G.flag("momPolice"), 60, "mom police msg"): return false
	await shot("chat-police")
	G.desk.close_all()
	A.open_mail()
	A.read_mail("gran")
	A.read_mail("draft")
	await shot("mail")
	A.open_flags()
	A._flags_begin()
	await shot("flags")
	A.open_photos()
	A.open_photo(1)
	await shot("photo")
	A.open_parental()
	await shot("parental")
	A.open_boat()
	A._boat_play()
	await wait(1.0)
	await shot("boat")
	G.desk.close_all()
	if k == "a":
		# прятки: тихо пересидеть визит — палево падает; дёргать мышь — растёт
		G.set_meta("visits", true)
		G.stealth.start_visit()
		if not await until(func(): return G.stealth.phase == "in", 30, "visit in"): return false
		await shot("visit")
		var s1 := float(G.st.sus)
		for i in 5:
			var ev := InputEventMouseMotion.new()
			ev.position = Vector2(300 + i * 30, 300)
			ev.relative = Vector2(30, 0)
			Input.parse_input_event(ev)
			await wait(0.5)
		if not await until(func(): return G.stealth.phase == "", 60, "visit end"): return false
		if not float(G.st.sus_max) > s1:
			errors.append("moving during visit did not raise suspicion")
		G.remove_meta("visits")
	# конец части 1 → комендантский час → часть 2
	if not await until(func(): return int(G.st.part) == 2, 120, "part 2"): return false
	if not await until(func(): return G.st.goal == "map", 60, "wake lines"): return false
	await shot("desk-part2")
	A.open_map()
	await wait(0.2)
	await shot("map-scrambled")
	A.map_order = [0, 1, 2, 3, 4, 5, 6, 8, 7]
	A._map_click(7)
	A._map_click(8)
	if not await until(func(): return G.flag("map"), 10, "map solved"): return false
	await shot("map-solved")
	A.open_diary()
	A.try_diary("северный маяк")
	if not await until(func(): return G.stage() == 2, 30, "stage 2"): return false
	await shot("diary")
	A.open_tale()
	A.open_chapter(2)
	A.open_chapter(3)
	await shot("tale4")
	A.open_cipher()
	await wait(0.2)
	await shot("cipher")
	for i in 3:
		A.cipher_shift += 1
		A._cipher_changed()
	if not G.flag("cipher"):
		errors.append("cipher not solved at shift 3")
	G.desk.close_all()
	if k == "b":
		# камера при маме в комнате поднимает палево; потом проверяем проигрыш и загрузку
		A.open_cam()
		await wait(0.6)
		await shot("cam-mom")
		G.desk.close_win("cam")
		if not float(G.st.sus) > 0:
			errors.append("camera did not raise suspicion")
		G.save_game()
		G.stealth.add_sus(100, "cam")
		if not await until(func(): return G.ending == "caught", 10, "caught"): return false
		await wait(0.6)
		await shot("caught")
		G.main.start_run(true)
		if not await until(func(): return G.in_game and G.st.goal != "", 30, "continue after caught"): return false
		A = G.apps
		G.st.sus = 10.0
	# конец части 2 → папа → часть 3
	if not await until(func(): return G.desk.win("cam") != null or int(G.st.part) == 3, 120, "dad scene"): return false
	await wait(0.3)
	await shot("dad")
	if not await until(func(): return int(G.st.part) == 3 and G.st.goal == "bin", 120, "part 3"): return false
	await shot("desk-part3")
	A.open_bin()
	A.restore(2)
	if not await until(func(): return G.st.goal == "tm", 30, "guard lock"): return false
	G.desk.close_all()
	A.open_tm()
	await wait(0.3)
	await shot("tm")
	for i in 3:
		A.tm_sel = G.L.tm.guard[0]
		A.end_process()
		await wait(0.4)
	if not await until(func(): return G.flag("guardKilled"), 30, "guard killed"): return false
	G.desk.close_all()
	A.open_bin()
	A.restore(2)
	await wait(0.3)
	await shot("memfix")
	A.mem_order = range(A._mem_chunks().size())
	A._mem_check()
	if not await until(func(): return G.stage() == 3, 60, "reveal"): return false
	await shot("dead-log")
	if not await until(func(): return A.choice_shown, 60, "choice"): return false
	await shot("choice")
	match k:
		"a", "t": G.story.ending_tell()
		"b": G.story.ending_silent()
		"c": G.story.ending_pretend()
	if k == "t":
		if not await until(func(): return G.desk.win("letter") != null, 120, "epilogue"): return false
		await wait(0.3)
		await shot("epilogue")
	if not await until(func(): return G.ending == k, 180, "ending " + k): return false
	await wait(1.5)
	await shot("end")
	return true
