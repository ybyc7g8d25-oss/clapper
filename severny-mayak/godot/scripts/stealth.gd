class_name Stealth
extends Node
## Палево и прятки. Кто-то идёт к комнате Лёвы (видно на полоске дома) → свернуть окна (D) → замереть.
## Пока человек в комнате — движение мыши, клики, клавиши и открытые окна заметны. 100% — шнур выдернут.

const MAX := 100.0
var phase := ""            # "", "warn", "in"
var moved := 0
var open_at := 0
var _last := 0.0
var _cool := 0.0
var _cam := 0.0
var _gen := 0
var found := 0
var checking := false
var checked := false        # проверка экрана при входе уже прошла

## Палево считается только пока идёт ночь или пока днём в квартире следователь (не во время заставок и отчётов).
func active() -> bool:
	return G.in_game and G.ending == "" and not G.st.mom_online \
		and ((G.night and G.night.running) or (G.day and G.day.active))

func frozen() -> bool:
	return phase == "in" and not (G.day and G.day.away)

func render() -> void:
	if G.hud:
		G.hud.refresh()

func add_sus(n: float, why := "") -> void:
	if not active():
		return
	if why == "beep" and G.house.asleep_in_lev():
		n *= 2.0
	var was := float(G.st.sus)
	G.st.sus = clampf(was + n, 0.0, MAX)
	G.st.sus_max = maxf(float(G.st.sus_max), float(G.st.sus))
	render()
	if n > 0:
		if not G.flag("susIntro"):
			G.set_flag("susIntro")
			G.pix.say(G.L.lines.susIntro)
		if was < 50 and G.st.sus >= 50:
			G.pix.say(G.L.lines.sus50)
		if was < 80 and G.st.sus >= 80:
			G.fx.glitch()
			G.pix.say(G.L.lines.sus80)
		if G.st.sus >= MAX:
			caught()

func _process(delta: float) -> void:
	if not active() or not G.house:
		return
	var inside: Array = G.house.awake_in_lev()
	var coming: String = G.house.approaching()
	# предупреждение: кто-то идёт по коридору к комнате
	if phase == "" and coming != "":
		phase = "warn"
		G.hud.set_fast(false)
		# дом закрыт — слышны только шаги, кто идёт — неизвестно
		G.menus.visit_banner("warn", G.L.speakers[coming] if G.house.visible else "")
		if not G.flag("visitTut"):
			G.pix.say(G.L.lines.visitWarn)
		Sfx.play("step")
	# вошёл
	if phase != "in" and inside.size() > 0:
		phase = "in"
		moved = 0
		open_at = G.desk.visible_windows()
		G.fx.dim(0.35)
		G.pix.hold = true
		G.menus.visit_banner("in", G.L.speakers[inside[0]])
		Sfx.play("door", -6.0)
		found = 0
		checked = false
		_check(String(inside[0]))
	# вышел
	if phase == "in" and inside.is_empty():
		var clean := moved == 0 and found == 0
		reset_visits()
		if clean and float(G.st.sus) > 0:
			add_sus(-8)
		if not G.flag("visitTut"):
			G.set_flag("visitTut")
		G.pix.say(G.L.lines.visitGood if clean else G.L.lines.visitBad)
	if phase == "warn" and coming == "" and inside.is_empty():
		reset_visits()
	# камера с огоньком
	var cam: OSWindow = G.desk.win("cam")
	if cam and cam.visible and inside.size() > 0:
		_cam += delta
		if _cam >= 1.0:
			_cam = 0.0
			if not G.flag("camRisk"):
				G.set_flag("camRisk")
				G.pix.say(G.L.lines.camRisk)
			add_sus(2.0, "cam")
	# остывание
	_cool += delta
	if _cool >= 4.0:
		_cool = 0.0
		if phase == "" and float(G.st.sus) > 0:
			add_sus(-1)

## Проверка компьютера: взгляд человека проходит по экрану слева направо и находит следы:
## открытые окна, доску, свёрнутые окна на панели, включённую лупу.
func _check(who: String) -> void:
	_gen += 1
	var g := _gen
	await get_tree().create_timer(1.0, false).timeout
	if g != _gen or phase != "in":
		return
	checking = true
	checked = false
	var ck = G.L.check
	G.menus.visit_text(ck.look % G.L.speakers[who])
	var traces: Array = []
	for w in G.desk.visible_list():
		traces.append({"x": w.position.x + w.size.x / 2.0, "rect": Rect2(w.position, w.size), "text": ck.win, "pen": 12.0})
	if G.board.visible:
		traces.append({"x": 240.0, "rect": Rect2(0, Desk.TOP, 480, Desk.BOTTOM - Desk.TOP), "text": ck.board, "pen": 15.0})
	if G.house.visible:
		traces.append({"x": 200.0, "rect": Rect2(G.house.position, G.house.size), "text": ck.house, "pen": 8.0})
	for b in G.hud.tray.get_children():
		traces.append({"x": b.global_position.x, "rect": Rect2(b.global_position, Vector2(10, 10)), "text": ck.tray, "pen": 5.0})
	if G.lens:
		traces.append({"x": 70.0, "rect": Rect2(G.hud.btn_lens.global_position, G.hud.btn_lens.size), "text": ck.lens, "pen": 5.0})
	var x := 0.0
	Sfx.play("heart", -4.0)
	while x <= 480.0:
		await get_tree().create_timer(0.05, false).timeout
		if g != _gen or phase != "in":
			G.menus.gaze(-1)
			checking = false
			return
		x += 480.0 / 70.0
		G.menus.gaze(x)
		for t in traces:
			if not t.has("hit") and float(t.x) <= x:
				t["hit"] = true
				found += 1
				G.menus.callout(t.rect, t.text)
				Sfx.play("err", -10.0)
				add_sus(float(t.pen), "visit")
		if int(x) % 96 < 7:
			Sfx.play("heart", -8.0)
	G.menus.gaze(-1)
	G.menus.visit_text(ck.seen if found > 0 else ck.clean)
	await get_tree().create_timer(1.6, false).timeout
	if g != _gen:
		return
	checking = false
	checked = true
	G.house.release()
	if phase == "in":
		G.menus.visit_banner("in", G.L.speakers[who])

## Человек снова смотрит на экран (следователь повернулся после звонка).
func recheck(who: String) -> void:
	found = 0
	checked = false
	_check(who)

## Шаги, которых нет. Закрыт дом — тревога как при настоящем визите, только никто не приходит.
func phantom() -> void:
	if phase != "" or not active():
		return
	Sfx.play("step", -4.0)
	G.house.sound(300, G.L.snd.steps)
	if G.house.visible:
		G.pix.say(G.L.lines.phantomSeen)
		return
	G.menus.visit_banner("warn", "")
	G.hud.set_fast(false)
	await get_tree().create_timer(5.0, false).timeout
	if phase == "":
		G.menus.visit_banner("", "")
		if not G.flag("phantom1"):
			G.set_flag("phantom1")
			G.pix.say(G.L.lines.phantom1)
		else:
			var pn: Array = G.L.lines.phantomN
			G.pix.say(pn[randi() % pn.size()])

func reset_visits() -> void:
	_gen += 1
	checking = false
	if G.house:
		G.house.release()
	if G.menus:
		G.menus.gaze(-1)
	if phase != "":
		phase = ""
		G.fx.dim(0.0, 0.3)
		G.pix.hold = false
		G.menus.visit_banner("", "")

func _input(e: InputEvent) -> void:
	if phase != "in" or get_tree().paused or not frozen():
		return
	if e is InputEventKey and e.keycode == KEY_ESCAPE:
		return
	var move := e is InputEventMouseMotion
	if not move and not (e is InputEventMouseButton or e is InputEventKey):
		return
	if not move:
		get_viewport().set_input_as_handled()
		if not e.is_pressed():
			return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last < 0.35:
		return
	_last = now
	moved += 1
	add_sus(3.0 if move else 6.0, "visit")
	G.menus.visit_flash()

func caught() -> void:
	reset_visits()
	G.night.running = false
	G.ending = "caught"
	G.in_game = false
	G.pix.reset()
	G.achieve("CAUGHT")
	Sfx.stop_drone()
	Sfx.play("door")
	G.fx.flash(1.0, 0.2)
	await get_tree().create_timer(0.4).timeout
	G.menus.show_caught()
