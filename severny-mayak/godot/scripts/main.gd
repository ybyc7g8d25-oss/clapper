extends Node
## Корневой узел. Вся игра рисуется во внутреннем экране 480x270 (SubViewport) и растягивается на весь экран:
## «на весь экран» — дробный масштаб с чётким сглаживанием краёв пикселей, «пиксель в пиксель» — только целый масштаб.

const W := 480
const H := 270
var screen: SubViewport
var display: TextureRect
var mat: ShaderMaterial
var world: Control
var cursor: Sprite2D
var mouse := Vector2(240, 135)
var _scale := 1.0
var _offset := Vector2.ZERO

func _ready() -> void:
	G.main = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	UI.setup()
	var dt := ThemeDB.get_default_theme()
	dt.merge_with(UI.theme)
	dt.default_font = UI.tiny
	dt.default_font_size = 8
	ThemeDB.fallback_font = UI.tiny
	ThemeDB.fallback_font_size = 8
	# внутренний экран
	screen = SubViewport.new()
	screen.size = Vector2i(W, H)
	screen.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	screen.handle_input_locally = true
	screen.gui_embed_subwindows = true
	screen.transparent_bg = false
	add_child(screen)
	G.screen = screen
	var bg := ColorRect.new()
	bg.color = UI.BLACK
	bg.size = Vector2(W, H)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(bg)
	# картинка на реальном экране
	display = TextureRect.new()
	display.texture = screen.get_texture()
	display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/sharp.gdshader")
	display.material = mat
	add_child(display)
	get_tree().root.size_changed.connect(_layout)
	# слои внутри экрана
	G.fx = FX.new()
	screen.add_child(G.fx)
	G.pix = Voice.new()
	screen.add_child(G.pix)
	G.menus = Menus.new()
	screen.add_child(G.menus)
	G.menus.new_game_requested.connect(func(): start_run("new"))
	G.menus.continue_requested.connect(func(): start_run("continue"))
	G.menus.retry_requested.connect(func(): start_run("night"))
	var cl := CanvasLayer.new()
	cl.layer = 128
	screen.add_child(cl)
	cursor = Sprite2D.new()
	cursor.texture = UI.tex("cursor")
	cursor.centered = false
	cl.add_child(cursor)
	G.lens_changed.connect(func(on): cursor.texture = UI.tex("cursor_lens" if on else "cursor"))
	apply_fullscreen()
	_layout()
	if not G.TEST:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		if not G.settings.warned:
			G.menus.show_warn(func(): G.menus.show_title())
		else:
			G.menus.show_title()
	else:
		add_child(load("res://scripts/test_runner.gd").new())

func apply_fullscreen() -> void:
	if G.TEST:
		return
	if G.settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var scr := DisplayServer.screen_get_size()
		var k := maxi(1, mini(scr.x * 3 / 4 / W, scr.y * 3 / 4 / H))
		DisplayServer.window_set_size(Vector2i(W * k, H * k))
		DisplayServer.window_set_position((scr - DisplayServer.window_get_size()) / 2)
	_layout.call_deferred()

func _layout() -> void:
	var win := get_viewport().get_visible_rect().size
	var sc := minf(win.x / W, win.y / H)
	if G.settings.scale == "pixel":
		sc = maxf(1.0, floorf(sc))
	_scale = sc
	display.size = Vector2(W, H) * sc
	_offset = ((win - display.size) / 2).floor()
	display.position = _offset
	mat.set_shader_parameter("scale", sc)

## Пересылка ввода во внутренний экран с пересчётом координат.
func _input(e: InputEvent) -> void:
	var ev := e.duplicate()
	if ev is InputEventMouse:
		var p: Vector2 = ((e.position - _offset) / _scale)
		p = p.clamp(Vector2.ZERO, Vector2(W - 1, H - 1))
		ev.position = p
		ev.global_position = p
		mouse = p
		if ev is InputEventMouseMotion:
			ev.relative = e.relative / _scale
			ev.velocity = e.velocity / _scale
	screen.push_input(ev, true)
	get_viewport().set_input_as_handled()

func _process(_d: float) -> void:
	cursor.position = mouse.floor() - (Vector2(4, 4) if G.lens else Vector2.ZERO)

# ---------------------------------------------------------------- прохождение
## mode: "new" — новая игра, "continue" — продолжить, "night" — переиграть ночь с начала
func start_run(mode: String) -> void:
	G.run_id += 1
	get_tree().paused = false
	G.menus.hide_overlays()
	if world:
		world.queue_free()
	world = Control.new()
	world.size = Vector2(W, H)
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(world)
	screen.move_child(world, 1)
	G.house = House.new()
	world.add_child(G.house)
	G.desk = Desk.new()
	world.add_child(G.desk)
	G.hud = Hud.new()
	world.add_child(G.hud)
	G.desk.build()
	G.house.build()
	G.hud.build()
	G.docs = Docs.new()
	G.board = Board.new()
	G.night = Night.new()
	G.stealth = Stealth.new()
	G.day = Day.new()
	for n in [G.docs, G.night, G.stealth, G.day]:
		world.add_child(n)
	G.desk.add_board(G.board)
	G.new_state()
	G.pix.reset()
	G.pix.goal("")
	G.pix.show_pix(false)
	G.fx.set_stage(0, true)
	G.lens = false
	match mode:
		"continue":
			var s := G.load_game()
			if s.is_empty():
				G.night.new_game()
			else:
				G.night.resume(s)
		"night":
			G.night.resume(G.load_night(), true)
		_:
			G.night.new_game()

func to_title() -> void:
	G.run_id += 1
	G.in_game = false
	G.ending = ""
	get_tree().paused = false
	G.pix.reset()
	G.pix.show_pix(false)
	Sfx.stop_drone()
	if world:
		world.queue_free()
		world = null
	G.fx.set_stage(0, true)
	G.fx.dim(0.0, 0.01)
	G.menus.show_title()

func _unhandled_input(_e: InputEvent) -> void:
	pass
