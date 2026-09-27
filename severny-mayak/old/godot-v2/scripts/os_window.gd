class_name OSWindow
extends Control
## Окно оболочки Nimbus Kids: заголовок с иконкой, перетаскивание, свернуть/закрыть.

signal closed
signal focused

const TITLE_H := 28
var id := ""
var body: Control
var title_bar: NinePatchRect
var title_label: Label
var task_button: Button
var on_close: Callable
var _drag := false
var _drag_off := Vector2.ZERO

func setup(win_id: String, title: String, icon: String, w: int, h: int) -> void:
	id = win_id
	name = "win_" + win_id
	size = Vector2(w, h)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# рамка и тень
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", _frame_style())
	UI.full(frame)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	# заголовок
	title_bar = NinePatchRect.new()
	title_bar.texture = UI.tex("ui_title")
	title_bar.patch_margin_left = 2
	title_bar.patch_margin_right = 2
	title_bar.position = Vector2(0, 0)
	title_bar.size = Vector2(w, TITLE_H)
	title_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(title_bar)
	var ic := UI.icon_rect(icon, 16)
	ic.position = Vector2(6, 6)
	title_bar.add_child(ic)
	title_label = UI.shadowed(UI.label(title, null, 16, Color.WHITE), Color("#25145c"))
	title_label.position = Vector2(28, 5)
	title_label.size = Vector2(w - 84, 20)
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_bar.add_child(title_label)
	var bx := _tb_button("ui_x", func(): close())
	bx.position = Vector2(w - 26, 5)
	title_bar.add_child(bx)
	var bm := _tb_button("ui_min", func(): minimize())
	bm.position = Vector2(w - 50, 5)
	title_bar.add_child(bm)
	title_bar.gui_input.connect(_on_title_input)
	# тело
	body = Control.new()
	body.position = Vector2(4, TITLE_H)
	body.size = Vector2(w - 8, h - TITLE_H - 4)
	body.clip_contents = true
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(body)
	# поп-анимация
	pivot_offset = size / 2
	scale = Vector2(0.96, 0.96)
	modulate.a = 0.5
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "scale", Vector2.ONE, 0.12)
	tw.tween_property(self, "modulate:a", 1.0, 0.12)

func _frame_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = UI.WIN
	s.border_color = UI.GRAPE
	s.set_border_width_all(4)
	s.border_width_top = 0
	s.anti_aliasing = false
	s.shadow_color = Color(0, 0, 0, 0.3)
	s.shadow_offset = Vector2(6, 6)
	s.shadow_size = 1
	return s

func _tb_button(tex: String, cb: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = UI.tex(tex)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	return b

## Положить содержимое (растягивается на всё тело окна).
func set_content(c: Control) -> Control:
	for ch in body.get_children():
		ch.queue_free()
	UI.full(c)
	body.add_child(c)
	return c

func set_active(on: bool) -> void:
	title_bar.texture = UI.tex("ui_title" if on else "ui_title_inactive")

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		focused.emit()

func _on_title_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		focused.emit()
		_drag = e.pressed
		_drag_off = get_global_mouse_position() - position
	elif e is InputEventMouseMotion and _drag:
		var p := get_global_mouse_position() - _drag_off
		var area: Vector2 = (get_parent() as Control).size
		p.x = clamp(p.x, 80 - size.x, area.x - 80)
		p.y = clamp(p.y, 0, area.y - 40)
		position = p.round()

func minimize() -> void:
	visible = false
	if task_button:
		task_button.button_pressed = false

func close() -> void:
	if on_close.is_valid():
		on_close.call()
	closed.emit()
	queue_free()
