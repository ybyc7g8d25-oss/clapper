class_name Madness
extends Node
## Нарастающая «шиза»: чем дальше, тем чаще Пиксель видит и слышит то, чего нет.
## Уровень растёт с ночами и мрачностью. Только ночью, когда в комнате никого (не мешает настоящим визитам).
## Ни один эффект не штрафует игрока — пугает только то, что игрок не знает, настоящее ли это.

const EVERY := [0.0, 75.0, 48.0, 30.0]   # раз во сколько секунд что-то происходит, по уровню
var _t := 0.0
var _next := 60.0
var busy := false

func level() -> int:
	var n: int = int(G.st.night)
	var lv := 0
	if n >= 2 or G.stage() >= 1: lv = 1
	if n >= 3 or G.stage() >= 2: lv = 2
	if n >= 4 or G.stage() >= 3: lv = 3
	return lv

func _can() -> bool:
	return G.in_game and G.ending == "" and G.night and G.night.running and not G.is_day() \
		and G.stealth.phase == "" and not busy and not get_tree().paused and not G.flag("monitorOffNow") \
		and not G.st.mom_online

func _process(delta: float) -> void:
	if not _can():
		return
	var lv := level()
	if lv == 0:
		return
	_t += delta
	if _t < _next:
		return
	_t = 0.0
	_next = EVERY[lv] * randf_range(0.7, 1.3)
	var pool := ["icon"]
	if lv >= 2:
		pool += ["clock", "whisper", "cursor", "msg", "doc", "thought"]
	if lv >= 3:
		pool += ["whisper", "phantomIn", "gaze", "msg", "thought", "thought"]
	fire(pool[randi() % pool.size()])

func fire(kind: String) -> void:
	busy = true
	match kind:
		"icon": await _icon()
		"clock": await _clock()
		"whisper": await _whisper()
		"cursor": await _cursor()
		"msg": await _msg()
		"doc": await _doc()
		"phantomIn": await _phantom_in()
		"gaze": await _gaze()
		"thought": await _thought()
	busy = false

# ---------------------------------------------------------------- эффекты
## Значок на секунду сам переименовывается.
func _icon() -> void:
	var ids: Array = G.desk.icon_nodes.keys()
	if ids.is_empty():
		return
	var ic: DeskIcon = G.desk.icon_nodes[ids[randi() % ids.size()]]
	var old := ic.lab.text
	ic.lab.text = String(G.L.whispers[randi() % G.L.whispers.size()])
	ic.lab.add_theme_color_override("font_color", UI.RED2)
	Sfx.play("glitch", -18.0)
	await G.sleep(1.1)
	if is_instance_valid(ic):
		ic.lab.text = old
		ic.lab.remove_theme_color_override("font_color")

## Часы на мгновение показывают 23:58.
func _clock() -> void:
	G.hud.clock_l.text = "23:58"
	G.hud.clock_l.add_theme_color_override("font_color", UI.ALARM)
	await G.sleep(1.4)
	G.hud.clock_l.remove_theme_color_override("font_color")
	G.hud.refresh()

## Шёпот у края экрана.
func _whisper() -> void:
	var l := UI.label(String(G.L.whispers[randi() % G.L.whispers.size()]), Color(UI.RED2, 0.85))
	l.modulate.a = 0.0
	var side := randi() % 3
	l.position = [Vector2(randf_range(100, 380), Desk.TOP + 4), Vector2(randf_range(100, 380), 244), Vector2(440, randf_range(40, 200))][side]
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	G.menus.root.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.8)
	tw.tween_interval(1.4)
	tw.tween_property(l, "modulate:a", 0.0, 1.2)
	tw.tween_callback(l.queue_free)
	await G.sleep(3.5)

## Чужой курсор медленно ползёт по столу — хотя в комнате никого.
func _cursor() -> void:
	var c := TextureRect.new()
	c.texture = UI.tex("cursor")
	c.modulate = Color(1, 1, 1, 0.8)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var from := Vector2(470, randf_range(60, 240))
	var target := Vector2(randf_range(20, 90), randf_range(30, 220))
	var bin = G.desk.icon_nodes.get("bin")
	if bin and is_instance_valid(bin):
		target = bin.global_position + Vector2(20, 8)
	c.position = from
	G.desk.add_child(c)
	var t := 0.0
	while t < 4.0:
		if not await G.sleep(0.05):
			break
		t += 0.05
		c.position = from.lerp(target, t / 4.0).round() + Vector2(sin(t * 7.0), 0).round()
	await G.sleep(0.6)
	c.queue_free()

## От «Лёвы» приходит сообщение — и тут же оказывается удалённым.
func _msg() -> void:
	var list: Array = G.L.madness.msgsDark if level() >= 3 and randf() < 0.6 else G.L.madness.msgs
	var m = list[randi() % list.size()]
	Sfx.play("msg")
	G.desk.blink_icon("chat")
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.flat(UI.DARK, UI.GREY, 1, 4, 3))
	var l := UI.label(G.L.madness.from + " " + String(m), UI.LIGHT, null, 8, 150)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.position = Vector2(300, 200)
	G.menus.root.add_child(p)
	await G.sleep(2.2)
	l.text = G.L.madness.from + " " + G.L.madness.deleted
	l.add_theme_color_override("font_color", UI.GREY3)
	Sfx.play("glitch", -16.0)
	await G.sleep(1.8)
	p.queue_free()
	if not G.flag("madMsg"):
		G.set_flag("madMsg")
		G.pix.say(G.L.lines.madMsg)

## В открытом документе на миг проступает «это ты».
func _doc() -> void:
	var wins: Array = G.desk.visible_list()
	if wins.is_empty():
		await _whisper()
		return
	var w: OSWindow = wins[randi() % wins.size()]
	var l := UI.label(G.L.madness.itsYou, UI.ALARM)
	l.position = Vector2(randf_range(8, maxf(10, w.size.x - 60)), randf_range(16, maxf(18, w.size.y - 14)))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = UI.PAPER
	bg.size = Vector2(44, 9)
	bg.position = l.position
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.add_child(bg)
	w.add_child(l)
	Sfx.play("glitch", -14.0)
	await G.sleep(0.35)
	if is_instance_valid(bg):
		bg.queue_free()
		l.queue_free()

## «Мама в комнате» — но в комнате никого.
func _phantom_in() -> void:
	G.hud.set_fast(false)
	Sfx.play("door", -12.0)
	G.menus.visit_banner("in", G.L.speakers[["mom", "dad"][randi() % 2]])
	G.fx.dim(0.35)
	await G.sleep(6.0)
	if G.stealth.phase == "":
		G.menus.visit_banner("", "")
		G.fx.dim(0.0, 0.4)
	G.pix.say(G.L.lines.madRoom if not G.flag("madRoom") else [G.L.lines.madRoom2[randi() % G.L.lines.madRoom2.size()]])
	G.set_flag("madRoom")

## Взгляд проходит по экрану — а смотреть некому.
func _gaze() -> void:
	Sfx.play("heart", -6.0)
	var x := 0.0
	while x <= 480.0:
		if not await G.sleep(0.05):
			break
		x += 480.0 / 60.0
		G.menus.gaze(x)
	G.menus.gaze(-1)
	if not G.flag("madGaze"):
		G.set_flag("madGaze")
		G.pix.say(G.L.lines.madGaze)

## Навязчивая мысль: красная строка у облачка Пикселя — и тут же зачёркнута, будто он этого не думал.
func _thought() -> void:
	var t: String = G.L.madness.thoughts[randi() % G.L.madness.thoughts.size()]
	var r := UI.rich("[color=#d9505e]%s[/color]" % G.esc(t), false)
	r.custom_minimum_size = Vector2(200, 0)
	r.fit_content = true
	r.add_theme_color_override("default_color", UI.RED2)
	r.position = Vector2(236, 196)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	G.menus.root.add_child(r)
	Sfx.play("glitch", -20.0)
	await G.sleep(1.6)
	if is_instance_valid(r):
		r.text = "[color=#948c8e][s]%s[/s][/color]" % G.esc(t)
	await G.sleep(1.2)
	if is_instance_valid(r):
		var tw := r.create_tween()
		tw.tween_property(r, "modulate:a", 0.0, 0.6)
		tw.tween_callback(r.queue_free)
	if not G.flag("madThought"):
		G.set_flag("madThought")
		G.pix.say(G.L.lines.madThought)
