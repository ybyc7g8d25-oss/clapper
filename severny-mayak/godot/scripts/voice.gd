class_name Voice
extends CanvasLayer
## Пиксель: портрет и его мысли внизу справа. Печатается по буквам, клик — дальше.
## [[оговорка]] видна только во втором прохождении.

const SPEED := {"slow": 0.04, "normal": 0.022, "fast": 0.01, "instant": 0.0}
var root: Control
var box: PanelContainer
var text: RichTextLabel
var goal_l: Label
var face: TextureRect
var Q: Array = []
var busy := false
var typing := false
var hold := false
var _full := ""
var _acc := 0.0
var _wait := -1.0
var _talk := false
var _tacc := 0.0
var _idle := 0.0
var _gen := 0

func _ready() -> void:
	layer = 25
	root = Control.new()
	root.size = Vector2(480, 270)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	face = TextureRect.new()
	face.texture = UI.tex("pix_0")
	face.position = Vector2(444, 222)
	face.mouse_filter = Control.MOUSE_FILTER_STOP
	face.gui_input.connect(_click)
	root.add_child(face)
	box = PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.gui_input.connect(_click)
	var v := UI.vbox(2)
	text = UI.rich("")
	text.custom_minimum_size = Vector2(196, 0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(text)
	goal_l = UI.label("", UI.AMBER2, null, 8, 196)
	v.add_child(goal_l)
	box.add_child(v)
	root.add_child(box)
	set_stage(0)
	root.visible = false

func _click(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		advance()

func show_pix(on := true) -> void:
	root.visible = on

func set_stage(n: int) -> void:
	var bg := UI.DARK if n < 3 else Color("#1a0d10")
	var border := UI.GREY if n < 3 else UI.ALARM
	box.add_theme_stylebox_override("panel", UI.flat(bg, border, 1, 4, 3))
	text.add_theme_color_override("default_color", UI.PAPER if n < 3 else UI.RED2)
	_face()

func _face() -> void:
	face.texture = UI.tex("pix_%d%s" % [G.stage(), "_talk" if _talk else ""])

func _layout() -> void:
	box.reset_size()
	var s := box.get_combined_minimum_size()
	box.position = Vector2(440 - s.x, 254 - s.y)

# ---------------------------------------------------------------- очередь
func say(lines: Array, cb := Callable()) -> void:
	for l in lines:
		Q.append(l)
	if cb.is_valid():
		Q.append(cb)
	if not busy:
		_next()

func say_wait(lines: Array) -> void:
	var done := [false]
	var g := _gen
	say(lines, func(): done[0] = true)
	while not done[0] and g == _gen:
		await get_tree().process_frame

func reset() -> void:
	_gen += 1
	Q.clear()
	busy = false
	typing = false
	_wait = -1.0
	text.text = ""
	_talk = false
	_face()

func _next() -> void:
	_wait = -1.0
	if Q.is_empty():
		busy = false
		typing = false
		_talk = false
		_face()
		return
	busy = true
	var it = Q.pop_front()
	if it is Callable:
		it.call()
		_next()
		return
	_start(String(it))

func _start(line: String) -> void:
	var parts := line.split("[[")
	var bb := G.esc(parts[0])
	for i in range(1, parts.size()):
		var cl := parts[i].split("]]", true, 1)
		if G.st.ng:
			bb += "[color=#cf3f4f]%s[/color]" % G.esc(cl[0])
		if cl.size() > 1:
			bb += G.esc(cl[1])
	text.text = bb
	text.visible = true
	_full = text.get_parsed_text()
	text.visible_characters = 0
	typing = true
	_acc = 0.0
	_layout()
	if G.TEST or SPEED[G.settings.text] == 0.0:
		_finish()

func _finish() -> void:
	typing = false
	text.visible_characters = -1
	_talk = false
	_face()
	_wait = 0.2 if G.TEST else maxf(2.0, _full.length() * 0.05)

func advance() -> void:
	if not busy:
		return
	if typing:
		_finish()
	else:
		_next()

func _process(delta: float) -> void:
	if hold:
		root.modulate.a = move_toward(root.modulate.a, 0.15, delta * 3)
		return
	root.modulate.a = move_toward(root.modulate.a, 1.0, delta * 3)
	if typing:
		var sp: float = SPEED[G.settings.text] * (1.5 if G.stage() >= 3 else 1.0)
		_acc += delta
		while typing and _acc >= sp:
			var i := text.visible_characters
			var ch := _full[i] if i < _full.length() else ""
			_acc -= sp * (6.0 if ch in ".!?…" else 1.0)
			text.visible_characters = i + 1
			if i % 2 == 0:
				Sfx.tick()
			if text.visible_characters >= _full.length():
				_finish()
		_tacc += delta
		if _tacc > 0.12:
			_tacc = 0.0
			_talk = not _talk
			_face()
	elif _wait >= 0.0:
		_wait -= delta
		if _wait < 0.0:
			_next()
	# молчит — сворачивается до цели
	_idle = _idle + delta if not busy else 0.0
	var show_text := _idle < 5.0 and text.text != ""
	if text.visible != show_text:
		text.visible = show_text
		_layout()
	box.visible = text.visible or goal_l.text != ""

func goal(key: String) -> void:
	G.st.f["goal"] = key
	goal_l.text = (G.L.ui.goal + String(G.L.goals.get(key, key))) if key != "" else ""
	_layout()

func goal_text(t: String) -> void:
	goal_l.text = t
	_layout()
