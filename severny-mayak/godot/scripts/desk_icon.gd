class_name DeskIcon
extends Control
## Значок на рабочем столе: одиночный клик выделяет, двойной — открывает.

signal open_requested(id: String)

var id := ""
var label: Label
var sel_box: Panel
var icon: TextureRect

func setup(icon_id: String, icon_name: String, text: String) -> void:
	id = icon_id
	custom_minimum_size = Vector2(108, 76)
	size = custom_minimum_size
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	sel_box = Panel.new()
	sel_box.add_theme_stylebox_override("panel", UI.flat(Color(0, 0, 0, 0), Color(1, 1, 1, 0.7), 2, 0))
	UI.full(sel_box)
	sel_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sel_box.visible = false
	add_child(sel_box)
	icon = UI.icon_rect(icon_name, 32)
	icon.position = Vector2(38, 4)
	add_child(icon)
	label = UI.shadowed(UI.label(text, null, 16, Color.WHITE))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.position = Vector2(0, 40)
	label.size = Vector2(108, 36)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func set_text(t: String) -> void:
	label.text = t

func set_selected(on: bool) -> void:
	sel_box.visible = on
	label.add_theme_color_override("font_color", Color.WHITE)
	if on:
		label.add_theme_stylebox_override("normal", UI.flat(UI.GRAPE, Color(0, 0, 0, 0), 0, 0, 0))
	else:
		label.remove_theme_stylebox_override("normal")

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		get_tree().call_group("desk_icons", "set_selected", false)
		set_selected(true)
		grab_focus()
		if e.double_click:
			open_requested.emit(id)
		accept_event()
	elif e is InputEventKey and e.pressed and e.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		open_requested.emit(id)
		accept_event()
