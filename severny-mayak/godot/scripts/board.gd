class_name Board
extends Control
## Доска улик: разделы с предложениями-пропусками. Пропуск заполняется словом из банка.
## Раздел заполнен целиком — проверка: печать «ВЕРНО» или «НЕ СХОДИТСЯ» (если ошибок ≤ 2 — «ПОЧТИ»).

var sel_section := "s1"
var sel_blank := -1
var tabs: VBoxContainer
var card: VBoxContainer
var bank: HFlowContainer
var status: Label
var stamp: Control

func _ready() -> void:
	size = Vector2(480, 246)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var cork := TextureRect.new()
	cork.texture = UI.tex("tex_cork")
	cork.stretch_mode = TextureRect.STRETCH_TILE
	cork.size = size
	cork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cork)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.25)
	shade.size = size
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var title := UI.label(G.L.board.title, UI.PAPER)
	title.position = Vector2(5, 2)
	add_child(title)
	tabs = UI.vbox(2)
	tabs.position = Vector2(4, 13)
	tabs.custom_minimum_size = Vector2(96, 0)
	tabs.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(tabs)
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel", _paper_style())
	paper.position = Vector2(104, 4)
	paper.custom_minimum_size = Vector2(372, 150)
	paper.size = paper.custom_minimum_size
	add_child(paper)
	card = UI.vbox(3)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	paper.add_child(card)
	var pin := TextureRect.new()
	pin.texture = UI.tex("pin")
	pin.position = Vector2(288, 2)
	add_child(pin)
	stamp = Control.new()
	stamp.position = Vector2(390, 130)
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stamp)
	var bl := UI.label(G.L.board.bank, UI.PAPER)
	bl.position = Vector2(104, 158)
	add_child(bl)
	status = UI.label("", UI.AMBER2)
	status.position = Vector2(180, 158)
	add_child(status)
	var bank_bg := ColorRect.new()
	bank_bg.color = Color(0, 0, 0, 0.35)
	bank_bg.position = Vector2(104, 168)
	bank_bg.size = Vector2(372, 74)
	bank_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bank_bg)
	var sc := ScrollContainer.new()
	sc.position = Vector2(106, 170)
	sc.size = Vector2(368, 70)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	bank = HFlowContainer.new()
	bank.add_theme_constant_override("h_separation", 2)
	bank.add_theme_constant_override("v_separation", 2)
	bank.custom_minimum_size = Vector2(360, 0)
	sc.add_child(bank)
	var hint := UI.label(G.L.board.hint, Color(UI.PAPER, 0.7), null, 8, 92)
	hint.position = Vector2(5, 190)
	add_child(hint)
	G.words_changed.connect(render)
	render()

func _paper_style() -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = UI.tex("tex_paper")
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	s.set_content_margin_all(6)
	return s

func toggle(force = null) -> void:
	var on: bool = (not visible) if force == null else bool(force)
	if on == visible:
		return
	visible = on
	Sfx.play("paper")
	if on:
		render()
		# обучение: доска открыта впервые → объяснить и отправить за словами в файлы
		if G.fget("goal", "") == "board":
			G.pix.goal("clues")
			G.pix.say(G.L.lines.boardFirst)
	G.desk.changed.emit()

# ---------------------------------------------------------------- отрисовка
func render() -> void:
	if not is_inside_tree():
		return
	for c in tabs.get_children():
		c.queue_free()
	for s in G.L.board.sections:
		var open := G.section_open(s.id)
		var solved: bool = G.st.solved.has(s.id)
		var t: String = ("✓ " if solved else "") + (s.title if open else G.L.ui.endLocked)
		var b := Button.new()
		b.text = t
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size = Vector2(96, 12)
		var active: bool = s.id == sel_section
		var bg := UI.PAPER if active else (UI.PAPER3 if open else UI.DARK3)
		b.add_theme_stylebox_override("normal", UI.flat(bg, UI.INK, 1, 3, 1))
		b.add_theme_stylebox_override("hover", UI.flat(UI.PAPER, UI.INK, 1, 3, 1))
		b.add_theme_stylebox_override("pressed", UI.flat(UI.PAPER, UI.INK, 1, 3, 1))
		b.add_theme_color_override("font_color", UI.GREEN if solved else (UI.INK if open else UI.GREY3))
		b.disabled = not open
		var sid: String = s.id
		b.pressed.connect(func():
			Sfx.play("paper")
			sel_section = sid
			sel_blank = -1
			render())
		tabs.add_child(b)
	_render_card()
	_render_bank()

func _render_card() -> void:
	for c in card.get_children():
		c.queue_free()
	for c in stamp.get_children():
		c.queue_free()
	var s := G.section(sel_section)
	if s.is_empty() or not G.section_open(sel_section):
		card.add_child(UI.label(G.L.board.locked, UI.INK2))
		return
	var solved: bool = G.st.solved.has(sel_section)
	var head := UI.label(String(s.title).to_upper(), UI.RED)
	card.add_child(head)
	var filled: Dictionary = G.st.blanks.get(sel_section, {})
	var bi := 0
	var re := RegEx.create_from_string("\\{(\\w+)\\}")
	for line in s.lines:
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 3)
		flow.add_theme_constant_override("v_separation", 1)
		flow.mouse_filter = Control.MOUSE_FILTER_PASS
		var pos := 0
		for m in re.search_all(line):
			_words_to(flow, String(line).substr(pos, m.get_start() - pos))
			flow.add_child(_blank(bi, String(filled.get(str(bi), "")), solved))
			bi += 1
			pos = m.get_end()
		_words_to(flow, String(line).substr(pos))
		card.add_child(flow)
	if solved:
		var st := TextureRect.new()
		st.texture = UI.tex("stamp")
		stamp.add_child(st)
		var l := UI.label(G.L.board.right, UI.RED)
		l.position = Vector2(8, 5)
		l.size = Vector2(48, 10)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stamp.add_child(l)
		stamp.rotation = -0.12

func _words_to(flow: HFlowContainer, t: String) -> void:
	for w in t.split(" ", false):
		flow.add_child(UI.label(w, UI.INK))

func _blank(i: int, wid: String, solved: bool) -> Button:
	var b := Button.new()
	b.text = G.word(wid) if wid != "" else "______"
	b.custom_minimum_size = Vector2(26, 9)
	var active := i == sel_blank and not solved
	var bg := UI.AMBER2 if active else (Color(0, 0, 0, 0) if wid != "" else Color(UI.PAPER3, 0.5))
	var st := UI.flat(bg, UI.INK2 if not solved else Color(0, 0, 0, 0), 0 if solved else 1, 2, 0)
	st.border_width_top = 0
	st.border_width_left = 0
	st.border_width_right = 0
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", UI.flat(UI.AMBER2, UI.INK, 1, 2, 0))
	b.add_theme_stylebox_override("pressed", st)
	b.add_theme_stylebox_override("disabled", st)
	b.add_theme_color_override("font_color", UI.BLUE if wid != "" else UI.INK2)
	b.add_theme_color_override("font_disabled_color", UI.BLUE)
	b.disabled = solved
	b.pressed.connect(func():
		Sfx.play("click")
		if sel_blank == i and wid != "":
			G.st.blanks[sel_section].erase(str(i))
			sel_blank = i
		else:
			sel_blank = i
		render())
	return b

func _render_bank() -> void:
	for c in bank.get_children():
		c.queue_free()
	if G.st.words.is_empty():
		bank.add_child(UI.label(G.L.board.empty, UI.PAPER2, null, 8, 360))
		return
	for wid in G.st.words:
		var b := Button.new()
		b.text = G.word(wid)
		b.add_theme_stylebox_override("normal", UI.flat(UI.PAPER2, UI.INK, 1, 2, 0))
		b.add_theme_stylebox_override("hover", UI.flat(UI.PAPER, UI.INK, 1, 2, 0))
		b.add_theme_stylebox_override("pressed", UI.flat(UI.AMBER2, UI.INK, 1, 2, 0))
		b.pressed.connect(place.bind(String(wid)))
		bank.add_child(b)

# ---------------------------------------------------------------- логика
## Положить слово в выбранный пропуск (или первый пустой).
func place(wid: String) -> void:
	if G.st.solved.has(sel_section) or not G.section_open(sel_section):
		return
	var left := locked_left()
	if left > 0:
		G.menus.toast(G.L.board.hot % left)
		Sfx.play("err", -10.0)
		return
	var n := G.section_blanks(G.section(sel_section)).size()
	if not G.st.blanks.has(sel_section):
		G.st.blanks[sel_section] = {}
	var filled: Dictionary = G.st.blanks[sel_section]
	if sel_blank < 0 or sel_blank >= n:
		sel_blank = -1
		for i in n:
			if not filled.has(str(i)):
				sel_blank = i
				break
		if sel_blank < 0:
			return
	filled[str(sel_blank)] = wid
	Sfx.play("type")
	# следующий пустой пропуск
	var nxt := -1
	for i in n:
		if not filled.has(str(i)):
			nxt = i
			break
	sel_blank = nxt
	G.save_game()
	render()
	if nxt == -1:
		_check()

func _check() -> void:
	var wrong := G.check_section(sel_section)
	if wrong < 0:
		return
	if wrong == 0:
		solve(sel_section)
		return
	Sfx.play("err")
	status.text = G.L.board.almost if wrong <= 2 else G.L.board.wrong
	status.add_theme_color_override("font_color", UI.AMBER2 if wrong <= 2 else UI.RED2)
	G.pix.say(G.L.lines.almost if wrong <= 2 else G.L.lines.wrong)
	if wrong > 2:
		# грубая ошибка: память «перегревается» — писк (палево) и доска заблокирована на 20 игровых минут
		G.stealth.add_sus(4.0, "beep")
		G.st.f["lock"] = _now() + LOCK_MIN
		G.fx.glitch(0.4)
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func(): status.text = "")

const LOCK_MIN := 20

func _now() -> int:
	return int(G.st.night) * 1000 + int(G.st.mins)

## Сколько игровых минут доска ещё «остывает» после грубой ошибки.
func locked_left() -> int:
	return maxi(0, int(G.fget("lock", 0)) - _now())

## Раздел решён: печать, память, последствия.
func solve(sid: String) -> void:
	if G.st.solved.has(sid):
		return
	G.st.solved.append(sid)
	var s := G.section(sid)
	G.st.mem = mini(100, int(G.st.mem) + int(s.mem))
	Sfx.play("stamp")
	status.text = ""
	render()
	stamp.scale = Vector2(1.6, 1.6)
	create_tween().tween_property(stamp, "scale", Vector2.ONE, 0.12)
	G.save_game()
	G.hud.refresh()
	if G.st.solved.size() == G.L.board.sections.size():
		G.achieve("BOARD")
	G.night.on_solved(sid)
