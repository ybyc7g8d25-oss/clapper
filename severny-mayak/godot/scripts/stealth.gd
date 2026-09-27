class_name Stealth
extends Node
## «Палево» и прятки. Люди в доме не должны заметить, что компьютер живёт сам.
## Шаги → свернуть окна (D) → замереть. Движение, клики и открытые окна поднимают шкалу. 100% — шнур выдернут.

const MAX := 100.0
var phase := ""                # "", "warn", "in"
var who := ""
var moved := 0
var open_at_arrive := 0
var _last_hit := 0.0
var _visit_gen := 0
var _cool := 0.0
var _cam_acc := 0.0

func active() -> bool:
	return G.in_game and G.ending == "" and not G.st.mom_online

func frozen() -> bool:
	return phase == "in"

func render() -> void:
	G.desk.set_sus(float(G.st.sus), active())

func add_sus(n: float, why := "") -> void:
	if not active():
		return
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
			caught(why)
	G.save_game()

func _process(delta: float) -> void:
	if not active():
		return
	# остывает, если вести себя тихо
	_cool += delta
	if _cool >= 4.0:
		_cool = 0.0
		if not cam_watching() and phase == "" and float(G.st.sus) > 0:
			add_sus(-1)
	# камера с горящим индикатором, пока мама в комнате
	if cam_watching():
		_cam_acc += delta
		if _cam_acc >= 1.0:
			_cam_acc = 0.0
			if not G.flag("camLed"):
				G.set_flag("camLed")
				G.pix.say(G.L.lines.camLed)
			add_sus(2, "cam")

func cam_watching() -> bool:
	var w: OSWindow = G.desk.win("cam")
	return G.stage() == 2 and w != null and w.visible

func caught(why: String) -> void:
	reset_visits()
	G.ending = "caught"
	G.save_game(true)
	G.in_game = false
	G.pix.reset()
	G.achieve("CAUGHT")
	Sfx.stop_drone()
	Sfx.play("door")
	G.fx.flash(1.0, 0.15)
	await get_tree().create_timer(0.3).timeout
	G.menus.show_caught(why)

# ---------------------------------------------------------------- визиты
func schedule_visit(sec := -1.0) -> void:
	_visit_gen += 1
	var g := _visit_gen
	if G.TEST and not G.has_meta("visits"):
		return
	if sec < 0:
		sec = randf_range(45, 90) if G.stage() == 2 else randf_range(80, 150)
	await get_tree().create_timer(sec, false).timeout
	if g == _visit_gen:
		start_visit()

func reset_visits() -> void:
	_visit_gen += 1
	if phase != "":
		phase = ""
		G.menus.visit_banner("", "")
		G.fx.dim(0.0, 0.3)
		G.pix.set_hold(false)

func _allowed() -> bool:
	return active() and G.flag("note") and phase == "" and G.stage() < 3 \
		and not G.desk.win("dead") and not G.desk.win("un") and not G.desk.win("dontw") and not G.desk.win("curfew")

func start_visit() -> void:
	if not _allowed():
		schedule_visit(15.0)
		return
	var visitors: Array = [G.L.visit.mom] if G.stage() == 2 else [G.L.visit.mom, G.L.visit.dad]
	if int(G.st.part) == 2:
		visitors = [G.L.visit.dad]
	await _run_visit(visitors[randi() % visitors.size()], -1.0)
	schedule_visit()

## Сценарный визит (например, папа в конце части 2).
func scripted_visit(person: String, stay: float) -> void:
	await _run_visit(person, stay)

func _run_visit(person: String, stay: float) -> void:
	var g := _visit_gen
	var first := not G.flag("visitTut")
	who = person
	phase = "warn"
	moved = 0
	G.pix.set_hold(true)
	G.menus.visit_banner("warn", G.L.visit.tut if first else G.L.visit.warnLines[randi() % G.L.visit.warnLines.size()])
	var warn := 7.5 if first else (3.2 if G.stage() == 2 else 4.5)
	var steps := 0
	var t := 0.0
	while t < warn:
		Sfx.play("step", linear_to_db(0.35 + minf(0.65, steps * 0.09)))
		steps += 1
		var d := 0.42 if G.stage() == 2 else 0.56
		await get_tree().create_timer(d, false).timeout
		t += d
		if g != _visit_gen:
			return
	# человек в комнате
	phase = "in"
	Sfx.play("door")
	open_at_arrive = G.desk.visible_windows()
	G.fx.dim(0.45)
	G.menus.visit_banner("in", G.L.visit.inTitle % who.to_upper())
	if open_at_arrive > 0:
		await get_tree().create_timer(0.6, false).timeout
		if phase == "in":
			add_sus(minf(30.0, open_at_arrive * 10.0), "visit")
			G.menus.visit_flash(G.L.visit.sawWin)
	var dur := stay if stay > 0 else (8.0 if G.stage() == 2 else 6.5) + randf() * 3.5
	var el := 0.0
	while el < dur:
		Sfx.play("heart", -6.0)
		await get_tree().create_timer(0.9, false).timeout
		el += 0.9
		if g != _visit_gen or phase != "in":
			return
	# ушёл
	var clean := moved == 0 and open_at_arrive == 0
	phase = ""
	Sfx.play("door", -8.0)
	G.fx.dim(0.0)
	G.menus.visit_banner("", "")
	G.pix.set_hold(false)
	if clean:
		add_sus(-8)
	if not G.flag("visitTut"):
		G.set_flag("visitTut")
		G.pix.say(G.L.visit.tutGood if clean else G.L.visit.tutBad)
	else:
		var pool: Array = G.L.visit.goodLines if clean else G.L.visit.badLines
		G.pix.say([pool[randi() % pool.size()]])

## Любое действие, пока человек в комнате, заметно. Клики не проходят.
func _input(e: InputEvent) -> void:
	if phase != "in" or get_tree().paused:
		return
	if e is InputEventKey and e.keycode == KEY_ESCAPE:
		return
	var is_move := e is InputEventMouseMotion
	if not is_move and not (e is InputEventMouseButton or e is InputEventKey):
		return
	if not is_move:
		get_viewport().set_input_as_handled()
		if not e.is_pressed():
			return
	var now := Time.get_ticks_msec() / 1000.0 * Engine.time_scale
	if now - _last_hit < 0.35:
		return
	_last_hit = now
	moved += 1
	add_sus(4.0 if is_move else 7.0, "visit")
	G.menus.visit_flash(G.L.visit.moveLines[randi() % G.L.visit.moveLines.size()])
