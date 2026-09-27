class_name PixelVoice
extends CanvasLayer
## Пиксель: аватар и облачко с репликами. Реплики печатаются по буквам, листаются кликом.
## Разметка: [[оговорка]] — видна только во втором прохождении (красным).

const SPEED := {"slow": 0.042, "normal": 0.024, "fast": 0.011, "instant": 0.0}
var root: Control
var bubble: PanelContainer
var text: RichTextLabel
var who: Label
var hint: Label
var goal_l: Label
var avatar: TextureRect
var Q: Array = []
var busy := false
var typing := false
var hold := false              # во время визита Пиксель молчит
var _full := ""
var _acc := 0.0
var _wait := -1.0
var _talk_acc := 0.0
var _talk_frame := false
var _gen := 0

func _ready() -> void:
	layer = 25
	root = Control.new()
	UI.full(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var box := UI.hbox(8)
	box.alignment = BoxContainer.ALIGNMENT_END
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.position = Vector2(960 - 12, 540 - 48)
	bubble = PanelContainer.new()
	bubble.custom_minimum_size = Vector2(220, 0)
	bubble.size_flags_vertical = Control.SIZE_SHRINK_END
	bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	bubble.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			advance())
	var v := UI.vbox(6)
	var h := UI.hbox(10)
	who = UI.label(G.L.log.pix.to_upper(), UI.pixf, 8, UI.GRAPE)
	h.add_child(who)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(sp)
	hint = UI.label(G.L.ui.click, UI.pixf, 8, Color("#9aa0ad"))
	h.add_child(hint)
	v.add_child(h)
	text = RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(380, 0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(text)
	goal_l = UI.label("", null, 16, Color("#556"), true)
	goal_l.custom_minimum_size = Vector2(380, 0)
	v.add_child(goal_l)
	bubble.add_child(v)
	box.add_child(bubble)
	avatar = TextureRect.new()
	avatar.texture = UI.tex("pix_0")
	avatar.custom_minimum_size = Vector2(64, 64)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_END
	avatar.mouse_filter = Control.MOUSE_FILTER_STOP
	avatar.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			advance())
	box.add_child(avatar)
	set_stage(0)
	root.modulate.a = 0
	root.visible = false

func show_pix(on := true) -> void:
	root.visible = true
	create_tween().tween_property(root, "modulate:a", 1.0 if on else 0.0, 0.6)
	if not on:
		get_tree().create_timer(0.6).timeout.connect(func(): if root.modulate.a < 0.1: root.visible = false)

func set_stage(n: int) -> void:
	var bg := Color.WHITE
	var border := UI.INK
	var fg := UI.INK
	if n == 2:
		bg = Color("#e6e6e6")
		fg = Color("#2a2a2a")
	elif n >= 3:
		bg = Color("#0d0b10")
		border = Color("#ff5a4d")
		fg = Color("#ff5a4d")
	var s := UI.flat(bg, border, 2, 0, 10)
	s.shadow_color = Color("#7a1510") if n >= 3 else UI.INK
	s.shadow_offset = Vector2(4, 4)
	s.shadow_size = 1
	bubble.add_theme_stylebox_override("panel", s)
	text.add_theme_color_override("default_color", fg)
	who.add_theme_color_override("font_color", Color("#ff5a4d") if n >= 3 else UI.GRAPE)
	goal_l.add_theme_color_override("font_color", Color("#b8544b") if n >= 3 else Color("#556070"))
	_update_avatar()

func _update_avatar() -> void:
	avatar.texture = UI.tex("pix_%d%s" % [G.stage(), "_talk" if _talk_frame else ""])

# ---------------------------------------------------------------- очередь реплик
func say(lines: Array, cb := Callable()) -> void:
	for l in lines:
		Q.append(l)
	if cb.is_valid():
		Q.append(cb)
	if not busy:
		_next()

## Сказать и дождаться, пока всё будет сказано.
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
	_talk_frame = false
	_update_avatar()

func _next() -> void:
	_wait = -1.0
	if Q.is_empty():
		busy = false
		typing = false
		_talk_frame = false
		_update_avatar()
		return
	busy = true
	var it = Q.pop_front()
	if it is Callable:
		it.call()
		_next()
		return
	_start_line(String(it))

func _start_line(line: String) -> void:
	var parts := line.split("[[")
	var bb := ""
	for i in parts.size():
		var p := parts[i]
		if i == 0:
			bb += G.esc(p)
			continue
		var cl := p.split("]]", true, 1)
		if G.st.ng:
			var col := "#ffffff" if G.stage() >= 3 else "#c9372f"
			bb += "[color=%s]%s[/color]" % [col, G.esc(cl[0])]
		if cl.size() > 1:
			bb += G.esc(cl[1])
	text.text = bb
	_full = text.get_parsed_text()
	text.visible_characters = 0
	typing = true
	_acc = 0.0
	if G.TEST or SPEED[G.settings.text] == 0.0:
		_finish()

func _finish() -> void:
	typing = false
	text.visible_characters = -1
	_talk_frame = false
	_update_avatar()
	if G.settings.auto or G.TEST:
		_wait = 0.3 if G.TEST else maxf(1.8, _full.length() * 0.048)

func advance() -> void:
	if not busy:
		return
	if typing:
		_finish()
	else:
		_next()

func _process(delta: float) -> void:
	if hold:
		return
	if typing:
		var sp: float = SPEED[G.settings.text] * (1.6 if G.stage() >= 3 else 1.0)
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
		_talk_acc += delta
		if _talk_acc > 0.12:
			_talk_acc = 0.0
			_talk_frame = not _talk_frame
			_update_avatar()
	elif _wait >= 0.0:
		_wait -= delta
		if _wait < 0.0:
			_next()

# ---------------------------------------------------------------- цель
func goal(key: String) -> void:
	G.st.goal = key
	G.save_game()
	goal_l.text = (G.L.ui.goal + G.L.goals.get(key, key)) if key != "" else ""
	goal_l.visible = key != ""

func goal_text(t: String) -> void:
	goal_l.text = t
	goal_l.visible = t != ""

func set_hold(on: bool) -> void:
	hold = on
	create_tween().tween_property(root, "modulate:a", 0.12 if on else 1.0, 0.3)
