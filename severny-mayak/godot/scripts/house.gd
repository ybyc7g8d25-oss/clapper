class_name House
extends Control
## Полоска «дом» (480x72): разрез квартиры. Так Пиксель «слышит» дом через микрофон и видит через камеру.
## Родители — силуэты, ходят по комнатам по расписанию ночи. Над ними всплывают звуки.

signal arrived(who: String, room: String)

const FLOOR := 66
const SPOTS := {        # где человек стоит/сидит/лежит в комнате
	"kitchen": [88, "sit"], "bed": [196, "lie"], "hall": [282, "stand"], "lev": [404, "stand"],
	"levbed": [340, "lie"], "out": [250, "out"], "door": [250, "stand"], "desk": [434, "sit"],
}
const ROOM_X := {"kitchen": [0, 116], "bed": [118, 236], "hall": [238, 326], "lev": [328, 480]}
var actors := {}          # who → {node, x, target, room, pose, walking}
var lights := {}
var glow: TextureRect
var sounds: Control
var base: TextureRect

func build() -> void:
	position = Vector2.ZERO
	size = Vector2(480, 72)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	base = TextureRect.new()
	base.texture = UI.tex("house")
	add_child(base)
	for r in ROOM_X:
		var l := TextureRect.new()
		l.texture = UI.tex("light_" + r)
		l.modulate.a = 0.0
		add_child(l)
		lights[r] = l
	glow = TextureRect.new()
	glow.texture = UI.tex("glow_mon")
	add_child(glow)
	for who in ["mom", "dad", "cop"]:
		var s := Sprite2D.new()
		s.centered = false
		s.texture = UI.tex("p_%s_0" % who)
		s.visible = false
		add_child(s)
		actors[who] = {"node": s, "x": -100.0, "target": -100.0, "room": "", "pose": "stand", "walking": false, "t": 0.0}
	sounds = Control.new()
	sounds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sounds)

## Днём дом серый, пасмурный; ночью — тёмный.
func set_day(on: bool) -> void:
	base.texture = UI.tex("house_day" if on else "house")

func set_stage(n: int) -> void:
	glow.texture = UI.tex("glow_mon_red" if n >= 3 else "glow_mon")

## Поставить человека в комнату сразу (начало ночи, загрузка).
func place(who: String, room: String) -> void:
	var a: Dictionary = actors[who]
	var spot: Array = SPOTS[room]
	a.x = float(spot[0])
	a.target = a.x
	a.room = room
	a.pose = spot[1]
	a.walking = false
	_apply(who)
	_update_lights()

## Отправить человека в комнату пешком.
var pending := {}              # кто хочет уйти, но ещё смотрит на экран

func move(who: String, room: String) -> void:
	var a: Dictionary = actors[who]
	if a.room == room:
		return
	if a.room in ["lev", "desk"] and G.stealth and G.stealth.checking:
		pending[who] = room
		return
	if a.room == "out" or a.room == "":
		a.x = 250.0
	a.target = float(SPOTS[room][0])
	a.room = room
	a.walking = true
	a.pose = "walk"
	_apply(who)
	if room != "out":
		sound(a.x, G.L.snd.steps)

## Проверка закончилась — отпустить тех, кто ждал.
func release() -> void:
	var p := pending.duplicate()
	pending.clear()
	for who in p:
		move(who, p[who])

func room_of(who: String) -> String:
	var a: Dictionary = actors[who]
	if a.walking:
		return _room_at(a.x)
	return a.room

func _room_at(x: float) -> String:
	for r in ROOM_X:
		if x >= ROOM_X[r][0] and x < ROOM_X[r][1]:
			return r
	return ""

## Кто сейчас в комнате Лёвы и бодрствует.
func awake_in_lev() -> Array:
	var out := []
	for who in actors:
		var a: Dictionary = actors[who]
		if a.room != "out" and a.node.visible and a.x >= 328 and a.pose != "lie":
			out.append(who)
	return out

func asleep_in_lev() -> bool:
	for who in actors:
		var a: Dictionary = actors[who]
		if a.room == "levbed" and not a.walking:
			return true
	return false

## Кто-то идёт к комнате Лёвы (уже в коридоре).
func approaching() -> String:
	for who in actors:
		var a: Dictionary = actors[who]
		if a.walking and a.target >= 328 and a.x >= 230 and a.x < 328:
			return who
	return ""

func _process(delta: float) -> void:
	for who in actors:
		var a: Dictionary = actors[who]
		if not a.walking:
			continue
		var dir := signf(a.target - a.x)
		a.x += dir * 26.0 * delta
		a.t += delta
		if (dir > 0 and a.x >= a.target) or (dir < 0 and a.x <= a.target) or dir == 0:
			a.x = a.target
			a.walking = false
			a.pose = SPOTS[a.room][1]
			arrived.emit(who, a.room)
		_apply(who)
	_update_lights()
	glow.modulate.a = 0.85 + 0.15 * sin(Time.get_ticks_msec() / 300.0)

func _apply(who: String) -> void:
	var a: Dictionary = actors[who]
	var s: Sprite2D = a.node
	s.visible = a.room != "out" or a.walking
	if a.room == "out" and not a.walking:
		s.visible = false
	var frame := "0"
	match a.pose:
		"walk": frame = str(1 + int(a.t * 5.0) % 2)
		"sit": frame = "sit"
		"lie": frame = "lie"
	s.texture = UI.tex("p_%s_%s" % [who, frame])
	s.flip_h = a.walking and a.target < a.x
	var h: float = s.texture.get_height()
	s.position = Vector2(floorf(a.x) - s.texture.get_width() / 2.0, FLOOR - h + (2 if frame == "lie" else 0))
	if a.room == "out" and a.walking and absf(a.x - a.target) < 1:
		s.visible = false

func _update_lights() -> void:
	for r in lights:
		var on := false
		for who in actors:
			var a: Dictionary = actors[who]
			if a.room == "out" or not a.node.visible:
				continue
			if _room_at(a.x) == r and a.pose != "lie" and r != "lev":
				on = true
		var l: TextureRect = lights[r]
		l.modulate.a = move_toward(l.modulate.a, 1.0 if on else 0.0, 0.05)

## Звук над домом: «*шаги*», «*голоса*», «*звонок*».
func sound(x: float, text: String, color := UI.GREY3) -> void:
	var l := UI.label(text, color)
	l.position = Vector2(clampf(x - 12, 2, 440), 10)
	sounds.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", 4.0, 1.6)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.6)
	tw.tween_callback(l.queue_free)
