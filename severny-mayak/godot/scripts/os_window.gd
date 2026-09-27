class_name OSWindow
extends Control
## Окно внутри компьютера Лёвы: тёмный заголовок, тело-«бумага», перетаскивание, закрытие.

signal closed
signal focused

const TITLE_H := 11
var id := ""
var icon_name := ""
var body: Control
var title_bg: ColorRect
var builder: Callable          # пересобирает содержимое (например, при включении лупы)
var on_close: Callable
var _drag := false
var _off := Vector2.ZERO

func setup(win_id: String, title: String, icon: String, w: int, h: int, bg := UI.PAPER) -> void:
	id = win_id
	icon_name = icon
	size = Vector2(w, h)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shadow := ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.45)
	shadow.position = Vector2(3, 3)
	shadow.size = size
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)
	var frame := ColorRect.new()
	frame.color = UI.BLACK
	frame.size = size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var inner := ColorRect.new()
	inner.color = bg
	inner.position = Vector2(1, TITLE_H)
	inner.size = Vector2(w - 2, h - TITLE_H - 1)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(inner)
	title_bg = ColorRect.new()
	title_bg.color = UI.DARK3
	title_bg.position = Vector2(1, 1)
	title_bg.size = Vector2(w - 2, TITLE_H - 2)
	title_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	title_bg.gui_input.connect(_title_input)
	add_child(title_bg)
	var t := UI.label(title, UI.LIGHT)
	t.position = Vector2(4, 0)
	t.size = Vector2(w - 20, 9)
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_bg.add_child(t)
	var x := TextureButton.new()
	x.texture_normal = UI.tex("ui_x")
	x.position = Vector2(w - 10, 1)
	x.pressed.connect(func():
		Sfx.play("click")
		close())
	title_bg.add_child(x)
	body = Control.new()
	body.position = Vector2(1, TITLE_H)
	body.size = Vector2(w - 2, h - TITLE_H - 1)
	body.clip_contents = true
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(body)

func set_content(c: Control) -> Control:
	for ch in body.get_children():
		ch.queue_free()
	UI.full(c)
	body.add_child(c)
	return c

func rebuild() -> void:
	if builder.is_valid():
		builder.call(self)

func set_active(on: bool) -> void:
	title_bg.color = UI.GREY if on else UI.DARK3

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		focused.emit()

func _title_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		focused.emit()
		_drag = e.pressed
		_off = get_global_mouse_position() - position
	elif e is InputEventMouseMotion and _drag:
		var p := (get_global_mouse_position() - _off).round()
		p.x = clampf(p.x, 40 - size.x, 440)
		p.y = clampf(p.y, Desk.TOP, 246)
		position = p

func close() -> void:
	if on_close.is_valid():
		on_close.call()
	closed.emit()
	queue_free()
