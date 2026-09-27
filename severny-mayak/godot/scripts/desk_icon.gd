class_name DeskIcon
extends Control
## Значок на столе: тёмная подложка, картинка 16x16, подпись. Двойной щелчок — открыть.

signal open_requested(id: String)
signal menu_requested(id: String)

var id := ""
var plate: ColorRect
var pic: TextureRect
var lab: Label

func setup(icon_id: String, icon_name: String, text: String) -> void:
	id = icon_id
	add_to_group("icons")
	size = Vector2(42, 26)
	mouse_filter = Control.MOUSE_FILTER_STOP
	plate = ColorRect.new()
	plate.color = Color(UI.BLACK, 0.55)
	plate.size = size
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)
	pic = TextureRect.new()
	pic.texture = UI.tex("icon_" + icon_name)
	pic.position = Vector2(13, 1)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pic)
	lab = UI.label(text, UI.LIGHT)
	lab.position = Vector2(0, 16)
	lab.size = Vector2(42, 9)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.clip_text = true
	add_child(lab)

func set_icon(n: String) -> void:
	pic.texture = UI.tex("icon_" + n)

func set_sel(on: bool) -> void:
	plate.color = Color(UI.PURPLE, 0.9) if on else Color(UI.BLACK, 0.55)

func blink() -> void:
	var tw := create_tween().set_loops(6)
	tw.tween_property(plate, "color", Color(UI.AMBER, 0.9), 0.3)
	tw.tween_property(plate, "color", Color(UI.BLACK, 0.55), 0.3)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		get_tree().call_group("icons", "set_sel", false)
		set_sel(true)
		if e.double_click:
			open_requested.emit(id)
		accept_event()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
		get_tree().call_group("icons", "set_sel", false)
		set_sel(true)
		menu_requested.emit(id)
		accept_event()
