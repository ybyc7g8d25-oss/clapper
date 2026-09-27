class_name UI
extends RefCounted
## Шрифты, тема и помощники для сборки интерфейса кодом.

const INK := Color("#1d1a2b")
const WIN := Color("#eef2f7")
const LINE := Color("#b9c2d0")
const GRAPE := Color("#5b3fb5")
const GRAPE_LO := Color("#35217a")
const MINT := Color("#3fbf86")
const ALERT := Color("#c9372f")
const GREY := Color("#667085")
const PAPER := Color("#fbfaf2")

static var mono: FontFile       # Unifont 16 — основной текст
static var head: FontFile       # Tiny5 — заголовки и кнопки меню
static var pixf: FontFile       # Press Start 2P — имя Пикселя, логотип
static var kid: FontFile        # Caveat без сглаживания — детский почерк
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
	mono = _font(["unifont.otf"])
	head = _font(["tiny5-latin-400-normal.woff2", "tiny5-cyrillic-400-normal.woff2", "unifont.otf"])
	pixf = _font(["press-start-2p-latin-400-normal.woff2", "press-start-2p-cyrillic-400-normal.woff2", "unifont.otf"])
	kid = _font(["caveat-latin-600-normal.woff2", "caveat-cyrillic-600-normal.woff2", "unifont.otf"])
	theme = Theme.new()
	theme.default_font = mono
	theme.default_font_size = 16
	for t in ["Label", "Button", "LineEdit", "RichTextLabel", "OptionButton", "CheckBox", "PopupMenu"]:
		theme.set_color("font_color", t, INK)
	theme.set_color("default_color", "RichTextLabel", INK)
	theme.set_constant("line_separation", "RichTextLabel", 2)
	theme.set_constant("line_spacing", "Label", 2)
	# кнопки с фаской
	theme.set_stylebox("normal", "Button", box9("ui_btn"))
	theme.set_stylebox("hover", "Button", box9("ui_btn_hover"))
	theme.set_stylebox("pressed", "Button", box9("ui_btn_press"))
	theme.set_stylebox("disabled", "Button", box9("ui_btn", 0.5))
	theme.set_stylebox("focus", "Button", flat(Color(0, 0, 0, 0), INK, 2, 0))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(c, "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color(INK, 0.4))
	# поле ввода
	theme.set_stylebox("normal", "LineEdit", flat(Color.WHITE, Color("#7f8aa0"), 2, 0, 6))
	theme.set_stylebox("focus", "LineEdit", flat(Color(0, 0, 0, 0), GRAPE, 2, 0))
	theme.set_color("caret_color", "LineEdit", INK)
	theme.set_color("selection_color", "LineEdit", Color(GRAPE, 0.4))
	# полосы прокрутки: пиксельные, узкие
	for sb in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", sb, flat(Color("#dde3ec"), Color(0, 0, 0, 0), 0, 0, 0))
		theme.set_stylebox("grabber", sb, flat(Color("#8b9bb4"), INK, 2, 0))
		theme.set_stylebox("grabber_highlight", sb, flat(Color("#5a6988"), INK, 2, 0))
		theme.set_stylebox("grabber_pressed", sb, flat(GRAPE, INK, 2, 0))
	theme.set_stylebox("panel", "PanelContainer", flat(WIN, Color(0, 0, 0, 0), 0, 0))
	theme.set_stylebox("panel", "Panel", flat(WIN, Color(0, 0, 0, 0), 0, 0))
	# ползунки и галочки в настройках
	theme.set_stylebox("slider", "HSlider", flat(Color("#2b2840"), Color(0, 0, 0, 0), 0, 0, 0, 4))
	theme.set_stylebox("grabber_area", "HSlider", flat(MINT, Color(0, 0, 0, 0), 0, 0, 0, 4))
	theme.set_stylebox("grabber_area_highlight", "HSlider", flat(MINT, Color(0, 0, 0, 0), 0, 0, 0, 4))
	theme.set_icon("grabber", "HSlider", tex("ui_knob"))
	theme.set_icon("grabber_highlight", "HSlider", tex("ui_knob"))

static func tex(n: String) -> Texture2D:
	if not _tex.has(n):
		_tex[n] = load("res://art/%s.png" % n)
	return _tex[n]

static func box9(n: String, alpha := 1.0) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex(n)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		s.set_texture_margin(side, 4)
		s.set_content_margin(side, 6)
	s.set_content_margin(SIDE_LEFT, 10)
	s.set_content_margin(SIDE_RIGHT, 10)
	s.modulate_color = Color(1, 1, 1, alpha)
	return s

static func flat(bg: Color, border: Color, bw := 2, shadow := 0, pad := 4, pad_v := -1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.anti_aliasing = false
	s.set_content_margin_all(pad)
	if pad_v >= 0:
		s.content_margin_top = pad_v
		s.content_margin_bottom = pad_v
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = 0
		s.shadow_offset = Vector2(shadow, shadow)
		s.shadow_size = 1
	return s

static func label(text: String, font: Font = null, size := 16, color := INK, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	if font:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func shadowed(l: Label, c := Color(0, 0, 0, 1)) -> Label:
	l.add_theme_color_override("font_shadow_color", c)
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

static func rich(bb: String, fit := false) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.text = bb
	r.fit_content = fit
	r.scroll_active = not fit
	r.selection_enabled = false
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r

static func button(text: String, cb: Callable, kind := "") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	if kind != "":
		b.add_theme_stylebox_override("normal", box9("ui_btn_" + kind))
		b.add_theme_stylebox_override("hover", box9("ui_btn_" + kind))
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	return b

## Кнопка меню: пиксельная рамка мятного цвета (титульный экран, пауза, финал).
static func menu_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 40)
	b.add_theme_font_override("font", head)
	b.add_theme_font_size_override("font_size", 16)
	var n := flat(Color(0, 0, 0, 0), MINT, 2, 0, 8)
	var h := flat(MINT, MINT, 2, 0, 8)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("focus", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("disabled", flat(Color(0, 0, 0, 0), Color(MINT, 0.3), 2, 0, 8))
	b.add_theme_color_override("font_color", MINT)
	b.add_theme_color_override("font_hover_color", Color("#05040a"))
	b.add_theme_color_override("font_focus_color", Color("#05040a"))
	b.add_theme_color_override("font_pressed_color", Color("#05040a"))
	b.add_theme_color_override("font_disabled_color", Color(MINT, 0.3))
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	b.mouse_entered.connect(func(): if not b.disabled: b.grab_focus())
	return b

static func vbox(sep := 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep := 6) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func margin(child: Control, m := 8) -> MarginContainer:
	var c := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		c.add_theme_constant_override("margin_" + s, m)
	c.add_child(child)
	return c

static func panel(child: Control, bg: Color, border := Color(0, 0, 0, 0), bw := 0, pad := 8) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", flat(bg, border, bw, 0, pad))
	p.add_child(child)
	p.size_flags_vertical = child.size_flags_vertical
	p.size_flags_horizontal = child.size_flags_horizontal
	return p

static func icon_rect(n: String, size := 32) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex("icon_" + n)
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func full(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c
