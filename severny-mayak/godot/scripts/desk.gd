class_name Desk
extends Control

signal changed          # окна открыты/закрыты/свёрнуты — для значков на нижней панели
## Рабочий стол (y 84..258): обои-фото, значки программ, окна и доска улик поверх.

const TOP := 84
const BOTTOM := 258
var wall: TextureRect
var icons_box: Control
var win_layer: Control
var board_holder: Control
var W := {}
var icon_nodes := {}
var LIST: Array = []
var _casc := 0
var _active := ""

func build() -> void:
	position = Vector2.ZERO
	size = Vector2(480, 270)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	wall = TextureRect.new()
	wall.texture = UI.tex("wall")
	wall.position = Vector2(0, TOP)
	wall.mouse_filter = Control.MOUSE_FILTER_STOP
	wall.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			get_tree().call_group("icons", "set_sel", false))
	add_child(wall)
	icons_box = Control.new()
	icons_box.position = Vector2(0, TOP)
	icons_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icons_box)
	board_holder = Control.new()
	board_holder.position = Vector2(0, TOP)
	board_holder.size = Vector2(480, BOTTOM - TOP)
	board_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board_holder)
	win_layer = Control.new()
	win_layer.size = Vector2(480, 270)
	win_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(win_layer)
	G.lens_changed.connect(func(_on): refresh_all())
	G.words_changed.connect(refresh_all)

func add_board(b: Control) -> void:
	board_holder.add_child(b)

func set_stage_visual(n: int) -> void:
	wall.texture = UI.tex("wall" if n < 2 else ("wall_alone" if n == 2 else "wall_dark"))
	if icon_nodes.has("log"):
		icon_nodes.log.set_icon("pixelDark" if n >= 3 else "pixel")

# ---------------------------------------------------------------- значки
func build_icons(list: Array) -> void:
	LIST = list
	for c in icons_box.get_children():
		c.queue_free()
	icon_nodes.clear()
	var i := 0
	for d in list:
		if d.has("show") and not d.show.call():
			continue
		var ic := DeskIcon.new()
		ic.setup(d.id, d.ic, d.label.call())
		ic.position = Vector2(3 + int(i / 6) * 44, 3 + (i % 6) * 28)
		ic.open_requested.connect(func(_id):
			if G.ending == "" and not G.stealth.frozen():
				d.open.call())
		icons_box.add_child(ic)
		icon_nodes[d.id] = ic
		i += 1

func refresh_icons() -> void:
	build_icons(LIST)

func blink_icon(id: String) -> void:
	if icon_nodes.has(id):
		icon_nodes[id].blink()

# ---------------------------------------------------------------- окна
func win(id: String) -> OSWindow:
	var w = W.get(id)
	return w if w and is_instance_valid(w) else null

## Открыть окно; builder(win) строит содержимое и вызывается снова при включении лупы/новых словах.
func open_win(id: String, title: String, icon: String, w: int, h: int, builder := Callable(), bg := UI.PAPER) -> OSWindow:
	Sfx.play("click")
	var ex := win(id)
	if ex:
		ex.visible = true
		focus(id)
		return ex
	var nw := OSWindow.new()
	nw.setup(id, title, icon, mini(w, 476), mini(h, 250), bg)
	nw.position = Vector2(clampi(132 + _casc * 12, 2, 478 - nw.size.x), clampi(TOP + 2 + _casc * 8, 0, BOTTOM - nw.size.y))
	_casc = (_casc + 1) % 6
	win_layer.add_child(nw)
	W[id] = nw
	nw.focused.connect(func(): focus(id))
	nw.closed.connect(func():
		W.erase(id)
		if _active == id:
			_active = ""
		changed.emit())
	nw.visibility_changed.connect(func(): changed.emit())
	if builder.is_valid():
		nw.builder = builder
		builder.call(nw)
	focus(id)
	changed.emit()
	return nw

func focus(id: String) -> void:
	var w := win(id)
	if not w:
		return
	w.move_to_front()
	_active = id
	for k in W:
		var o := win(k)
		if o:
			o.set_active(k == id)

func close_win(id: String) -> void:
	var w := win(id)
	if w:
		w.close()

func close_all() -> void:
	for k in W.keys():
		close_win(k)
	_casc = 0

func hide_all() -> void:
	for k in W:
		var w := win(k)
		if w:
			w.visible = false
	if G.board and G.board.visible:
		G.board.toggle(false)
	Sfx.play("click")

func hidden_windows() -> Array:
	var out := []
	for k in W:
		var w := win(k)
		if w and not w.visible:
			out.append(w)
	return out

func visible_list() -> Array:
	var out := []
	for k in W:
		var w := win(k)
		if w and w.visible:
			out.append(w)
	return out

func visible_windows() -> int:
	var n := 0
	for k in W:
		var w := win(k)
		if w and w.visible:
			n += 1
	if G.board and G.board.visible:
		n += 1
	return n

func refresh_all() -> void:
	for k in W:
		var w := win(k)
		if w:
			w.rebuild()

func alert(title: String, bb: String, icon := "warn") -> OSWindow:
	Sfx.play("err")
	var id := "alert%d" % Time.get_ticks_msec()
	var w := open_win(id, title, icon, 220, 70, Callable(), UI.LIGHT)
	var h := UI.hbox(6)
	h.add_child(UI.icon(icon))
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.rich(bb))
	var ok := UI.button(G.L.os.ok, func(): close_win(id))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_child(ok)
	h.add_child(v)
	w.set_content(UI.panel(h, UI.LIGHT, Color(0, 0, 0, 0), 0, 5))
	w.position = Vector2(130, 130)
	return w
