extends Node
## Корневой узел: собирает слои, запускает прохождение, обрабатывает клавиши и курсор.

var world: Control
var cursor: Sprite2D

func _ready() -> void:
	G.main = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	UI.setup()
	# тема для всех элементов, в том числе внутри CanvasLayer
	var dt := ThemeDB.get_default_theme()
	dt.merge_with(UI.theme)
	dt.default_font = UI.mono
	dt.default_font_size = 16
	ThemeDB.fallback_font = UI.mono
	ThemeDB.fallback_font_size = 16
	get_tree().root.theme = UI.theme
	apply_fullscreen()
	G.fx = FX.new()
	add_child(G.fx)
	G.pix = PixelVoice.new()
	add_child(G.pix)
	G.menus = Menus.new()
	add_child(G.menus)
	G.menus.new_game_requested.connect(func(): start_run(false))
	G.menus.continue_requested.connect(func(): start_run(true))
	var cl := CanvasLayer.new()
	cl.layer = 128
	add_child(cl)
	cursor = Sprite2D.new()
	cursor.texture = UI.tex("cursor")
	cursor.centered = false
	cl.add_child(cursor)
	if not G.TEST:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if G.TEST:
		var t: Node = load("res://scripts/test_runner.gd").new()
		add_child(t)
	elif not G.settings.warned:
		G.menus.show_warn(func(): G.menus.show_title())
	else:
		G.menus.show_title()

func apply_fullscreen() -> void:
	if G.TEST:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if G.settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if not G.settings.fullscreen:
		DisplayServer.window_set_size(Vector2i(1920, 1080) if DisplayServer.screen_get_size().x > 1920 else Vector2i(1280, 720))
		DisplayServer.window_set_position((DisplayServer.screen_get_size() - DisplayServer.window_get_size()) / 2)

func _process(_d: float) -> void:
	cursor.position = get_viewport().get_mouse_position()

## Новое прохождение (или продолжение сохранения).
func start_run(cont: bool) -> void:
	G.run_id += 1
	get_tree().paused = false
	G.menus.hide_overlays()
	if world:
		world.queue_free()
	world = Control.new()
	UI.full(world)
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world)
	move_child(world, 0)
	var desk := Desktop.new()
	G.desk = desk
	desk.visible = false
	world.add_child(desk)
	desk.build()
	G.apps = Apps.new()
	G.story = Story.new()
	G.stealth = Stealth.new()
	for n in [G.apps, G.story, G.stealth]:
		world.add_child(n)
	G.apps._init_refs()
	G.new_state()
	G.pix.reset()
	G.pix.goal("")
	G.pix.set_stage(0)
	G.pix.show_pix(false)
	G.fx.set_stage(0, true)
	G.fx.dim(0.0, 0.01)
	var save := G.load_game() if cont else {}
	if cont and not save.is_empty():
		G.story.continue_game(save)
	else:
		G.story.new_game()

func to_title() -> void:
	G.run_id += 1
	G.in_game = false
	G.ending = ""
	get_tree().paused = false
	if G.stealth:
		G.stealth.reset_visits()
	G.pix.reset()
	G.pix.show_pix(false)
	Sfx.stop_drone()
	if world:
		world.queue_free()
		world = null
	G.fx.set_stage(0, true)
	G.fx.dim(0.0, 0.01)
	G.menus.show_title()

func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	match e.keycode:
		KEY_ESCAPE:
			if G.menus.panel_open():
				G.menus.panel.visible = false
			elif G.menus.pause_open():
				G.menus.close_pause()
			elif G.in_game and G.ending == "":
				if G.desk.start_menu.visible:
					G.desk.start_menu.visible = false
				else:
					G.menus.open_pause()
		KEY_F11:
			G.settings.fullscreen = not G.settings.fullscreen
			G.save_settings()
			apply_fullscreen()
		KEY_SPACE, KEY_ENTER:
			if G.in_game and not get_tree().paused:
				G.pix.advance()
		KEY_D:
			if G.in_game and not get_tree().paused and G.ending == "" and not G.stealth.frozen():
				G.desk.hide_all()
