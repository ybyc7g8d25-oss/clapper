extends Node
## Глобальное состояние игры (автозагрузка «G»): настройки, сохранения, тексты, достижения, Steam.

signal stage_changed(n: int)
signal sus_changed(v: float)
signal shards_changed

const SAVE_PATH := "user://save.json"
const META_PATH := "user://meta.json"
const SET_PATH := "user://settings.json"

var L: Dictionary = {}            # тексты текущего языка (lang/ru.json, lang/en.json)
var LANGS := {}
var settings := {"vol": 0.8, "amb": 0.8, "text": "normal", "auto": true, "fx": "full", "scares": true,
	"lang": "", "warned": false, "fullscreen": true}
var meta := {"endings": {}, "ach": {}, "runs": 0}
var st := {}                      # состояние прохождения
var in_game := false
var ending := ""                  # "", "pending", "a", "b", "c", "t", "caught"
var run_id := 0                   # растёт при каждом сбросе — отменяет «повисшие» await-цепочки
var TEST := false
var shots_dir := ""
var steam = null
# ссылки на узлы текущей сессии (их расставляет main.gd)
var main
var desk
var pix
var apps
var story
var stealth
var menus
var fx

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	TEST = args.has("--test")
	for a in args:
		if a.begins_with("--shots="):
			shots_dir = a.substr(8)
		if a.begins_with("--lang="):
			settings.lang = a.substr(7)
	for code in ["ru", "en"]:
		var f := FileAccess.open("res://lang/%s.json" % code, FileAccess.READ)
		LANGS[code] = JSON.parse_string(f.get_as_text())
	if TEST:
		for p in [SAVE_PATH, META_PATH, SET_PATH]:
			if FileAccess.file_exists(_p(p)):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(_p(p)))
		settings.warned = true
	_merge(settings, _read(SET_PATH))
	_merge(meta, _read(META_PATH))
	if settings.lang == "" or not LANGS.has(settings.lang):
		settings.lang = "ru" if OS.get_locale_language() in ["ru", "uk", "be", "kk"] else "en"
	for a in args:
		if a.begins_with("--lang="):
			settings.lang = a.substr(7)
	L = LANGS[settings.lang]
	new_state()
	_init_steam()

# ---------------------------------------------------------------- файлы
## В автотесте сохранения пишутся в отдельные файлы test_*.json.
func _p(path: String) -> String:
	return path.replace("user://", "user://test_") if TEST else path

func _read(path: String) -> Dictionary:
	path = _p(path)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}

func _write(path: String, d: Dictionary) -> void:
	var f := FileAccess.open(_p(path), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

func _merge(dst: Dictionary, src: Dictionary) -> void:
	for k in src:
		dst[k] = src[k]

func save_settings() -> void:
	_write(SET_PATH, settings)

func save_meta() -> void:
	_write(META_PATH, meta)

func set_lang(code: String) -> void:
	settings.lang = code
	L = LANGS[code]
	save_settings()

# ---------------------------------------------------------------- прохождение
func new_state() -> void:
	st = {"stage": 0, "f": {}, "shards": [], "goal": "", "mins": 21 * 60 + 40, "ng": false,
		"mom_online": false, "sus": 0.0, "sus_max": 0.0, "part": 1}

func flag(k: String) -> bool:
	return st.f.has(k) and bool(st.f[k])

func set_flag(k: String, v = 1) -> void:
	st.f[k] = v
	save_game()

func fget(k: String, def = 0):
	return st.f.get(k, def)

func save_game(force := false) -> void:
	if not force and (not in_game or ending != ""):
		return
	var d := st.duplicate(true)
	d["v"] = 1
	_write(SAVE_PATH, d)

func load_game() -> Dictionary:
	var d := _read(SAVE_PATH)
	return d if d.get("v", 0) == 1 else {}

func has_save() -> bool:
	return not load_game().is_empty()

func clear_save() -> void:
	if FileAccess.file_exists(_p(SAVE_PATH)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_p(SAVE_PATH)))

## Ждать sec секунд игрового времени (встаёт на паузу). false — если за это время начали новую игру.
func sleep(sec: float) -> bool:
	var id := run_id
	await get_tree().create_timer(sec, false).timeout
	return id == run_id and ending != "caught"

func stage() -> int:
	return int(st.stage)

# ---------------------------------------------------------------- тексты
## Значение по пути "a.b.c" из текущего языка.
func t(path: String):
	var cur = L
	for part in path.split("."):
		if cur is Dictionary and cur.has(part):
			cur = cur[part]
		elif cur is Array and part.is_valid_int():
			cur = cur[int(part)]
		else:
			return path
	return cur

func esc(s: String) -> String:
	return s.replace("[", "[lb]")

var _re_clue := RegEx.create_from_string("\\{\\{(.+?)\\}\\}")
## {{улика}} → во втором прохождении подчёркнута красным.
func clue(s: String) -> String:
	var tag := "[color=#c9372f][u]$1[/u][/color]" if st.ng else "$1"
	return _re_clue.sub(esc(s), tag, true)

func plain(s: String) -> String:
	return _re_clue.sub(s, "$1", true)

func clock_str(m: int) -> String:
	return "%d:%02d" % [int(m / 60) % 24, m % 60]

# ---------------------------------------------------------------- достижения и Steam
func _init_steam() -> void:
	if Engine.has_singleton("Steam"):
		steam = Engine.get_singleton("Steam")
		var r = steam.steamInitEx() if steam.has_method("steamInitEx") else steam.steamInit()
		print("Steam: ", r)

func achieve(id: String) -> void:
	if meta.ach.has(id):
		return
	meta.ach[id] = Time.get_unix_time_from_system()
	save_meta()
	if steam:
		steam.setAchievement(id)
		steam.storeStats()
	var a = L.ach.get(id)
	if a:
		get_tree().call_group("toast", "show_toast", L.ui.achTitle, a[0])
