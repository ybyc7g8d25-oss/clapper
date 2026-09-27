class_name Day
extends Node
## День. За компьютером Лёвы сидит следователь Орлов: открывает файлы по очереди и копирует их на флешку.
## Каждый скопированный файл двигает «Дело» (поиск Лёвы) и добавляет улики против Пикселя.
## Пока он смотрит — замри. Когда ему звонят и он отворачивается — можно быстро спрятать или стереть файл.
## Потом он поворачивается обратно и проверяет экран.

const COPY_SEC := 3.5          # сколько идёт копирование одного файла
const AWAY_SEC := 6.0          # сколько длится звонок
const FIELD := 8.0             # поиски на местности: столько «Дело» растёт за день само
const HIDE_PENALTY := 15.0     # эксперт нашёл скрытую папку — это подозрительно

var away := false
var calls := 0                 # сколько звонков уже было сегодня
var active := false            # день идёт (не заставка и не отчёт)
var cur: TextureRect
var copied_today: Array = []
var missed_today: Array = []

func per_day(d: int) -> int:
	return [4, 5, 6][clampi(d - 1, 0, 2)]

## С третьего дня с Орловым эксперт — он находит скрытую папку.
func expert(d: int) -> bool:
	return d >= 3

## Файл есть на компьютере (карта появляется со второй ночи, шифровка — после раздела «Маршрут»).
func exists(id: String) -> bool:
	var e: Dictionary = G.docs.entry(id)
	return not e.is_empty() and (not e.has("show") or e.show.call())

func plan(d: int) -> Array:
	var out := []
	if expert(d) and not G.hidden_files().is_empty():
		out.append("cache")
	for id in G.INV_ORDER:
		if out.size() >= per_day(d):
			break
		if G.st.copied.has(id) or G.file_state(id) != "" or not exists(id):
			continue
		out.append(id)
	return out

## Скопировать файл в дело (без анимации). cache — всё, что лежит в скрытой папке.
func apply_copy(id: String) -> Array:
	var ids := G.hidden_files() if id == "cache" else [id]
	var got := []
	for f in ids:
		if G.st.copied.has(f):
			continue
		G.st.copied.append(f)
		G.add_case(float(G.FILES[f][0]))
		G.add_pix(float(G.FILES[f][1]))
		got.append(f)
	if id == "cache" and not got.is_empty():
		G.add_pix(HIDE_PENALTY)
		for f in got:
			G.st.files.erase(f)
		G.desk.refresh_icons()
	return got

func _alive(id: int) -> bool:
	return id == G.run_id and G.ending == ""

func _until(cond: Callable, sec := 60.0) -> bool:
	var id := G.run_id
	var t := 0.0
	while not cond.call():
		await get_tree().process_frame
		t += get_process_delta_time()
		if not _alive(id) or t > sec:
			return false
	return true

# ---------------------------------------------------------------- день целиком
func run() -> void:
	var d: int = int(G.st.night)
	var rid := G.run_id
	G.in_game = true
	G.ending = ""
	active = false
	G.st.phase = "day"
	G.st.mins = 0
	copied_today.clear()
	missed_today.clear()
	G.save_night()
	G.desk.close_all()
	G.board.toggle(false)
	G.docs.reset_chats()
	G.desk.build_icons(G.docs.desk_list())
	G.night.update_stage(true)
	Sfx.set_drone(G.stage())
	G.house.place("mom", "kitchen")
	G.house.place("dad", "out")
	G.house.place("cop", "out")
	G.house.set_day(true)
	G.hud.refresh()
	G.pix.show_pix(false)
	var seize := G.flag("seize")
	await G.menus.day_card(d, seize)
	if not _alive(rid):
		return
	G.pix.show_pix(true)
	if seize:
		await seized(d)
		return
	active = true
	if G.fget("goal", "") != "day":
		G.st.f["goalNight"] = G.fget("goal", "")
	G.pix.goal("day")
	if not G.flag("dayTut"):
		G.set_flag("dayTut")
		await G.pix.say_wait(G.L.lines.dayIntro)
		# Пиксель врёт: журнал контроля — улика против него самого
		if G.file_state("parental") == "" and not G.st.solved.has("s6"):
			G.set_flag("lieDelete")
			await G.pix.say_wait(G.L.lines.lieDelete)
	else:
		await G.pix.say_wait(G.L.lines.dayAgain)
	if expert(d) and not G.flag("expertSeen"):
		G.set_flag("expertSeen")
		await G.pix.say_wait(G.L.lines.expert)
	if not await G.sleep(1.5):
		return
	# сцена дня: кто что говорит, пока Орлов идёт к компьютеру
	var intro: Array = G.L.day.intro[clampi(d - 1, 0, G.L.day.intro.size() - 1)]
	for l in intro:
		G.menus.subtitle(G.L.speakers[l[0]], l[1], 2.8)
		if not await G.sleep(3.0):
			return
	# Орлов заходит; stealth сам предупредит («идёт сюда») и проверит экран
	G.house.move("cop", "desk")
	calls = 0
	if not await _until(func(): return G.stealth.phase == "in" and G.stealth.checked, 90.0):
		return
	_make_cursor()
	var todo := plan(d)
	var i := 0
	for id in todo:
		if not _alive(rid):
			return
		await inspect(id, i in [1, 3])
		i += 1
		G.st.mins = int(G.st.mins) + 25
		G.hud.refresh()
		G.save_game()
	if not _alive(rid):
		return
	_drop_cursor()
	if not await G.sleep(1.0):
		return
	G.house.move("cop", "out")
	if not await _until(func(): return G.stealth.phase == "", 60.0):
		return
	active = false
	G.add_case(FIELD)
	await G.pix.say_wait(G.L.lines.dayEnd)
	if not _alive(rid):
		return
	await G.menus.day_report(d, copied_today, missed_today)
	if not _alive(rid):
		return
	after_day(d)

## Итог дня: нашли ли Лёву, не пора ли изымать компьютер, не кончилось ли время.
func after_day(d: int) -> void:
	if float(G.st.case) >= 100.0:
		var h := G.hours_at(d, true, int(G.st.mins))
		if G.leva_idx(h) >= 3:
			# следствие дошло до башни — но слишком поздно: никто не успел
			G.st.found_h = h
			G.ending = "pending"
			G.night.show_end("b")
			return
		await police_found(h)
		return
	if G.hours_at(d + 1, false) >= G.DEADLINE:
		G.ending = "pending"
		G.night.show_end("b")
		return
	if float(G.st.pix) >= 100.0:
		G.set_flag("seize")
	G.st.phase = "night"
	G.st.f["goal"] = G.fget("goalNight", "")
	G.st.night = d + 1
	G.st.mins = 0
	G.st.sus = maxf(0.0, float(G.st.sus) - 30.0)
	G.night.start_night(true)

# ---------------------------------------------------------------- следователь смотрит файл
func inspect(id: String, call_first := false) -> void:
	var dd = G.L.day
	var rid := G.run_id
	if id != "cache" and G.file_state(id) != "":
		missed_today.append(id)
		return
	var icon_id := id
	var ic = G.desk.icon_nodes.get(icon_id)
	if ic == null or not is_instance_valid(ic):
		return
	await _move_cursor(ic.global_position + Vector2(21, 9), 1.2)
	if not await G.sleep(1.0):
		return
	# курсор уже на файле — и тут звонок: он отворачивается, можно успеть убрать файл из-под носа
	if call_first:
		await phone()
		if not _alive(rid):
			return
	if id != "cache" and G.file_state(id) != "":
		missed_today.append(id)
		G.add_pix(5.0)
		G.menus.visit_text(dd.missing)
		await G.sleep(2.0)
		G.menus.visit_banner("in", G.L.speakers.cop)
		return
	var title: String = dd.cacheName if id == "cache" else G.docs.file_label(id)
	var w: OSWindow = G.desk.open_win("inv", dd.window % title, "cache" if id == "cache" else String(G.docs.entry(id).ic), 236, 92, Callable(), UI.LIGHT)
	w.position = Vector2(122, 120)
	var v := UI.vbox(3)
	var remark: String = dd.remarks.get(id, dd.remarkAny)
	if id == "cache":
		var names := []
		for f in G.hidden_files():
			names.append(G.docs.file_label(f))
		remark = dd.remarks.cache % ", ".join(names)
	v.add_child(UI.label(dd.who, UI.INK2))
	v.add_child(UI.label(remark, UI.INK, null, 8, 220))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 5)
	bar.add_theme_stylebox_override("background", UI.flat(UI.PAPER, UI.INK, 1, 0, 0))
	bar.add_theme_stylebox_override("fill", UI.flat(UI.BLUE, UI.BLUE, 0, 0, 0))
	v.add_child(bar)
	var st := UI.label(dd.copying, UI.BLUE)
	v.add_child(st)
	w.set_content(UI.panel(v, UI.LIGHT, Color(0, 0, 0, 0), 0, 5))
	Sfx.play("key", -6.0)
	for p in range(0, 101, 5):
		if not await G.sleep(COPY_SEC / 20.0):
			return
		bar.value = p
	if not _alive(rid):
		return
	var c0 := float(G.st.case)
	var p0 := float(G.st.pix)
	var got := apply_copy(id)
	copied_today.append_array(got)
	st.text = dd.copied % [int(float(G.st.case) - c0)]
	Sfx.play("stamp", -6.0)
	G.menus.toast(dd.toast % [int(float(G.st.case) - c0), title])
	if float(G.st.pix) - p0 >= 15.0:
		if G.flag("copyBadSaid"):
			G.pix.say([G.L.lines.copyBad2[int(G.st.copied.size()) % G.L.lines.copyBad2.size()]])
		else:
			G.set_flag("copyBadSaid")
			G.pix.say(G.L.lines.copyBad)
	if id == "cache":
		G.pix.say(G.L.lines.cacheFound)
	if not await G.sleep(1.4):
		return
	if w and is_instance_valid(w):
		w.close()

# ---------------------------------------------------------------- звонок: Орлов отворачивается
func phone() -> void:
	var rid := G.run_id
	if not await G.sleep(0.8):
		return
	Sfx.play("ring")
	G.house.sound(404, G.L.snd.ring, UI.AMBER2)
	if not await G.sleep(1.0):
		return
	away = true
	if cur:
		cur.visible = false
	G.menus.visit_banner("away", G.L.speakers.cop)
	if not G.flag("awayTut"):
		G.set_flag("awayTut")
		G.pix.say(G.L.lines.dayAway)
	# разговор Орлова по телефону — субтитрами, пока игрок торопится
	var d: int = int(G.st.night)
	var all: Array = G.L.day.calls[clampi(d - 1, 0, G.L.day.calls.size() - 1)]
	var talk: Array = all[mini(calls, all.size() - 1)]
	calls += 1
	var per := AWAY_SEC / float(talk.size() + 1)
	var t := 0.0
	var li := 0
	while t < AWAY_SEC:
		if li < talk.size() and t >= li * per:
			G.menus.subtitle(G.L.speakers.cop, String(talk[li]), per + 0.3)
			li += 1
		if not await G.sleep(0.25):
			away = false
			return
		t += 0.25
	away = false
	if not _alive(rid):
		return
	G.desk.close_menu()
	G.menus.visit_banner("in", G.L.speakers.cop)
	# поворачивается обратно — и смотрит на экран
	G.stealth.recheck("cop")
	await _until(func(): return G.stealth.checked, 30.0)
	if cur:
		cur.visible = true

# ---------------------------------------------------------------- курсор следователя
func _make_cursor() -> void:
	_drop_cursor()
	cur = TextureRect.new()
	cur.texture = UI.tex("cursor")
	cur.modulate = Color(0.72, 0.84, 1.0)
	cur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cur.position = Vector2(300, 200)
	G.desk.add_child(cur)

func _drop_cursor() -> void:
	if cur and is_instance_valid(cur):
		cur.queue_free()
	cur = null

func _move_cursor(to: Vector2, sec: float) -> void:
	if not cur:
		return
	var from := cur.position
	var t := 0.0
	while t < sec:
		if not await G.sleep(0.05):
			return
		t += 0.05
		var k := t / sec
		k = k * k * (3.0 - 2.0 * k)
		cur.position = (from.lerp(to, k) + Vector2(sin(t * 9.0), cos(t * 7.0)) * 1.5).round()
	cur.position = to

# ---------------------------------------------------------------- развязки дня
## Следствие нашло Лёву первым.
func police_found(h: int) -> void:
	G.st.found_h = h
	G.ending = "pending"
	G.night.running = false
	Sfx.play("ring")
	G.house.sound(88, G.L.snd.ring, UI.AMBER2)
	await G.pix.say_wait(G.L.lines.policeFound)
	G.night.show_end("p" if float(G.st.pix) >= 50.0 else "s")

## Компьютер изымают на экспертизу: всё, что не стёрто, попадает в дело.
func seized(d: int) -> void:
	G.ending = "pending"
	await G.pix.say_wait(G.L.lines.seized)
	G.house.move("cop", "desk")
	await G.sleep(4.0)
	for id in G.INV_ORDER:
		if G.file_state(id) != "deleted" and exists(id) and not G.st.copied.has(id):
			G.st.copied.append(id)
			G.add_case(float(G.FILES[id][0]))
	G.add_case(FIELD)
	G.st.found_h = G.hours_at(d, true) + 8 if float(G.st.case) >= 100.0 else -1
	Sfx.play("click")
	G.menus.monitor_off(true)
	await G.sleep(1.5)
	G.menus.monitor_off(false)
	G.night.show_end("x")

## Прокрутить будущее без Пикселя (после «промолчать»): найдёт ли следствие Лёву вовремя.
func simulate() -> String:
	var d: int = int(G.st.night)
	while true:
		if float(G.st.pix) >= 100.0:
			for id in G.INV_ORDER:
				if G.file_state(id) != "deleted" and exists(id) and not G.st.copied.has(id):
					G.st.copied.append(id)
					G.add_case(float(G.FILES[id][0]))
		else:
			for id in plan(d):
				apply_copy(id)
		G.add_case(FIELD)
		if float(G.st.case) >= 100.0:
			G.st.found_h = G.hours_at(d, true)
			return "police" if G.leva_idx(int(G.st.found_h)) < 3 else "lost"
		if G.hours_at(d + 1, false) >= G.DEADLINE:
			return "lost"
		d += 1
	return "lost"
