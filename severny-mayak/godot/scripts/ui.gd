class_name UI
extends RefCounted
## Палитра, шрифты и помощники. Вся игра — на сетке 480x270, 1 пиксель = 1 пиксель арта.

# ---- палитра (приглушённая, в духе Papers Please) ----
const BLACK := Color("#121115")
const DARK := Color("#1d1b21")
const DARK2 := Color("#27242c")
const DARK3 := Color("#35313b")
const GREY := Color("#4d4852")
const GREY2 := Color("#6b6570")
const GREY3 := Color("#948c8e")
const LIGHT := Color("#c2b8ac")
const PAPER := Color("#ddd2ba")
const PAPER2 := Color("#c9bb9c")
const PAPER3 := Color("#a8997c")
const INK := Color("#2b2624")
const INK2 := Color("#554b45")
const RED := Color("#a8443c")
const RED2 := Color("#d0695c")
const GREEN := Color("#5f7a55")
const GREEN2 := Color("#9aae7c")
const BLUE := Color("#3f5068")
const BLUE2 := Color("#6c86a0")
const AMBER := Color("#c49a45")
const AMBER2 := Color("#e3c983")
const PURPLE := Color("#5a4b75")
const PURPLE2 := Color("#8574a4")
const ALARM := Color("#cf3f4f")

static var tiny: FontFile      # Tiny5 8 — основной текст
static var big: FontFile       # Tiny5 16 — заголовки
static var logo: FontFile      # Press Start 2P — логотип, номера ночей
static var hand: FontFile      # Pixelify Sans 11 — почерк
static var theme: Theme
static var _tex := {}

static func _font(files: Array) -> FontFile:
	var main: FontFile = null
	var fb: Array[Font] = []
	for f in files:
		var ff: FontFile = (load("res://fonts/" + f) as FontFile).duplicate()
		ff.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		ff.hinting = TextServer.HINTING_NONE
		ff.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		ff.generate_mipmaps = false
		if main == null:
			main = ff
		else:
			fb.append(ff)
	main.fallbacks = fb
	return main

static func setup() -> void:
	tiny = _font(["tiny5-latin-400-normal.woff2", "tiny5-cyrillic-400-normal.woff2"])
	big = tiny
	logo = _font(["press-start-2p-latin-400-normal.woff2", "press-start-2p-cyrillic-400-normal.woff2"])
	hand = _font(["pixelify-sans-latin-400-normal.woff2", "pixelify-sans-cyrillic-400-normal.woff2"])
	theme = Theme.new()
	theme.default_font = tiny
	theme.default_font_size = 8
	for t in ["Label", "Button", "LineEdit", "RichTextLabel", "OptionButton", "CheckBox"]:
		theme.set_color("font_color", t, INK)
	theme.set_color("default_color", "RichTextLabel", INK)
	theme.set_constant("line_separation", "RichTextLabel", 1)
	theme.set_constant("line_spacing", "Label", 1)
	theme.set_stylebox("normal", "Button", flat(PAPER2, INK, 1, 3, 1))
	theme.set_stylebox("hover", "Button", flat(PAPER, INK, 1, 3, 1))
	theme.set_stylebox("pressed", "Button", flat(PAPER3, INK, 1, 3, 1))
	theme.set_stylebox("disabled", "Button", flat(Color(PAPER2, 0.5), Color(INK, 0.4), 1, 3, 1))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(c, "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color(INK, 0.4))
	theme.set_stylebox("normal", "LineEdit", flat(Color("#efe7d4"), INK, 1, 3, 1))
	theme.set_stylebox("focus", "LineEdit", flat(Color(0, 0, 0, 0), RED, 1, 3, 1))
	theme.set_color("caret_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", Color(INK, 0.4))
	for sb in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", sb, flat(Color(0, 0, 0, 0.12), Color(0, 0, 0, 0), 0, 0, 0))
		theme.set_stylebox("grabber", sb, flat(GREY2, GREY2, 0, 1, 1))
		theme.set_stylebox("grabber_highlight", sb, flat(GREY, GREY, 0, 1, 1))
		theme.set_stylebox("grabber_pressed", sb, flat(INK, INK, 0, 1, 1))
		theme.set_constant("scroll_size" if sb == "VScrollBar" else "scroll_size", sb, 3)
	theme.set_stylebox("panel", "PanelContainer", StyleBoxEmpty.new())
	theme.set_stylebox("slider", "HSlider", flat(DARK3, DARK3, 0, 0, 0, 2))
	theme.set_stylebox("grabber_area", "HSlider", flat(AMBER, AMBER, 0, 0, 0, 2))
	theme.set_stylebox("grabber_area_highlight", "HSlider", flat(AMBER2, AMBER2, 0, 0, 0, 2))
	theme.set_icon("grabber", "HSlider", tex("ui_knob"))
	theme.set_icon("grabber_highlight", "HSlider", tex("ui_knob"))
	theme.set_icon("checked", "CheckBox", tex("ui_check_on"))
	theme.set_icon("unchecked", "CheckBox", tex("ui_check_off"))
	theme.set_stylebox("normal", "CheckBox", StyleBoxEmpty.new())
	theme.set_stylebox("hover", "CheckBox", StyleBoxEmpty.new())
	theme.set_stylebox("pressed", "CheckBox", StyleBoxEmpty.new())
	theme.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())

static func tex(n: String) -> Texture2D:
	if not _tex.has(n):
		_tex[n] = load("res://art/%s.png" % n)
	return _tex[n]

static func flat(bg: Color, border: Color, bw := 1, pad_h := 3, pad_v := 2, pad_all := -1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.anti_aliasing = false
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v
	s.content_margin_bottom = pad_v
	if pad_all >= 0:
		s.set_content_margin_all(pad_all)
	return s

static func label(text: String, color := INK, font: Font = null, size := 8, wrap_w := 0) -> Label:
	var l := Label.new()
	l.text = text
	if font:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap_w > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = wrap_w
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func rich(bb := "", fit := true) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.text = bb
	r.fit_content = fit
	r.scroll_active = not fit
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.meta_underlined = false
	r.add_theme_constant_override("line_separation", 1)
	return r

static func button(text: String, cb: Callable, style := "") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	match style:
		"dark":
			b.add_theme_stylebox_override("normal", flat(DARK3, GREY, 1, 3, 1))
			b.add_theme_stylebox_override("hover", flat(GREY, GREY3, 1, 3, 1))
			b.add_theme_stylebox_override("pressed", flat(DARK, GREY3, 1, 3, 1))
			for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				b.add_theme_color_override(c, LIGHT)
		"red":
			b.add_theme_stylebox_override("normal", flat(RED, INK, 1, 3, 1))
			b.add_theme_stylebox_override("hover", flat(RED2, INK, 1, 3, 1))
			b.add_theme_stylebox_override("pressed", flat(Color("#7d312b"), INK, 1, 3, 1))
			for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				b.add_theme_color_override(c, PAPER)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	return b

static func vbox(sep := 2) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v

static func hbox(sep := 2) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h

static func panel(child: Control, bg: Color, border := Color(0, 0, 0, 0), bw := 0, pad := 3) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", flat(bg, border, bw, pad, pad))
	p.add_child(child)
	p.size_flags_vertical = child.size_flags_vertical
	p.size_flags_horizontal = child.size_flags_horizontal
	return p

static func icon(n: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex("icon_" + n)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	return t

static func scroll(child: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(child)
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s

static func full(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c

static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
