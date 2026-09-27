extends Node
## Глобальное состояние (автозагрузка «G»): настройки, сохранения, тексты, банк слов, доска, достижения, Steam.

signal lens_changed(on: bool)
signal words_changed
signal board_changed

const SAVE_PATH := "user://save.json"        # текущее состояние
const NIGHT_PATH := "user://night.json"      # контрольная точка: начало ночи
const META_PATH := "user://meta.json"
const SET_PATH := "user://settings.json"
const NIGHT_START := 22 * 60                  # ночь начинается в 22:00
const NIGHT_LEN := 480                        # и длится 8 часов (до 06:00)
const DAY_START := 13 * 60                    # днём следователь приходит в 13:00
const DEADLINE := 119                         # столько часов Лёва продержится наверху башни
const V := 4                                  # версия сохранений
## Файлы-улики: [насколько продвигают дело (поиск Лёвы), насколько выдают Пикселя].
const FILES := {
	"web": [10, 5], "mail": [15, 10], "log": [10, 30], "photos": [10, 5], "parental": [5, 30],
	"diary": [20, 15], "draw": [5, 5], "essay": [5, 10], "tale": [10, 25], "map": [25, 0], "cipher": [25, 15],
}
## В каком порядке следователь смотрит файлы.
const INV_ORDER := ["web", "mail", "log", "photos", "parental", "diary", "essay", "draw", "tale", "map", "cipher"]
## Окна, которые принадлежат файлу (закрываются, когда файл прячут или стирают).
const FILE_WINS := {"draw": ["draw", "dr0", "dr1", "dr2"], "photos": ["photos", "ph0", "ph1", "ph2", "ph3"],
	"tale": ["tale", "ch0", "ch1", "ch2", "ch3"]}

var L: Dictionary = {}
var LANGS := {}
var settings := {"vol": 0.8, "amb": 0.8, "text": "normal", "fx": "full", "scares": true,
	"lang": "", "warned": false, "fullscreen": true, "scale": "fill"}
var meta := {"endings": {}, "ach": {}, "runs": 0}
var st := {}
var in_game := false
var ending := ""
var run_id := 0
var lens := false
var TEST := false
var shots_dir := ""
var steam = null
# узлы текущей сессии (расставляет main.gd)
var main
var screen
var house
var hud
var desk
var docs
var board
var night
var stealth
var day
var madness
var pix
var menus
var fx

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	TEST = args.has("--test")
	for code in ["ru", "en"]:
		var f := FileAccess.open("res://lang/%s.json" % code, FileAccess.READ)
		LANGS[code] = JSON.parse_string(f.get_as_text())
	if TEST:
		for p in [SAVE_PATH, NIGHT_PATH, META_PATH, SET_PATH]:
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
		if a.begins_with("--shots="):
			shots_dir = a.substr(8)
	L = LANGS[settings.lang]
	new_state()
	if Engine.has_singleton("Steam"):
		steam = Engine.get_singleton("Steam")
		steam.steamInitEx() if steam.has_method("steamInitEx") else steam.steamInit()

# ---------------------------------------------------------------- файлы
func _p(path: String) -> String:
	return path.replace("user://", "user://test_") if TEST else path

func _read(path: String) -> Dictionary:
	path = _p(path)
	if not FileAccess.file_exists(path):
		return {}
	var d = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
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
	st = {"v": V, "night": 1, "mins": 0, "stage": 0, "f": {}, "words": [], "blanks": {}, "solved": [], "mem": 0,
		"shards": [], "sus": 0.0, "sus_max": 0.0, "ng": false, "mom_online": false,
		"phase": "night", "case": 0.0, "pix": 0.0, "files": {}, "copied": [], "found_h": -1}

func flag(k: String) -> bool:
	return st.f.has(k) and bool(st.f[k])

func set_flag(k: String, v = 1) -> void:
	st.f[k] = v
	save_game()

func fget(k: String, def = 0):
	return st.f.get(k, def)

func save_game(force := false) -> void:
	if force or (in_game and ending == ""):
		_write(SAVE_PATH, st)

func save_night() -> void:
	_write(NIGHT_PATH, st)
	_write(SAVE_PATH, st)

func load_game() -> Dictionary:
	var d := _read(SAVE_PATH)
	return d if int(d.get("v", 0)) == V else {}

func load_night() -> Dictionary:
	var d := _read(NIGHT_PATH)
	return d if int(d.get("v", 0)) == V else {}

func has_save() -> bool:
	return not load_game().is_empty()

func clear_save() -> void:
	for p in [SAVE_PATH, NIGHT_PATH]:
		if FileAccess.file_exists(_p(p)):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_p(p)))

## Ждать sec секунд игрового времени (встаёт на паузу). false — если за это время начали заново или проиграли.
func sleep(sec: float) -> bool:
	var id := run_id
	await get_tree().create_timer(sec, false).timeout
	return id == run_id and ending != "caught"

func stage() -> int:
	return int(st.stage)

func is_day() -> bool:
	return st.phase == "day"

func clock() -> String:
	var m := ((DAY_START if is_day() else NIGHT_START) + int(st.mins)) % (24 * 60)
	return "%02d:%02d" % [m / 60, m % 60]

## Сколько часов нет Лёвы (ушёл 4 октября в 07:04). Ночь n начинается в 22:00, день после неё — в 13:00.
func hours_at(night: int, day: bool, mins := 0) -> int:
	return 15 + 24 * (night - 1) + (15 if day else 0) + mins / 60

func hours_gone() -> int:
	return hours_at(int(st.night), is_day(), int(st.mins))

## Каким найдут Лёву через h часов: 0 — замёрз, но цел; 1 — больница; 2 — без сознания; 3 — поздно.
func leva_idx(h: int) -> int:
	if h < 47: return 0
	if h < 71: return 1
	if h < 95: return 2
	return 3

## Дата: ночь n — (3+n) октября, день после ночи n — (4+n) октября.
func date_str(n: int, day := false) -> String:
	return L.ui.date % (3 + n + (1 if day else 0))

func night_info(n: int) -> Dictionary:
	return L.nights[clampi(n - 1, 0, L.nights.size() - 1)]

# ---------------------------------------------------------------- файлы-улики
func file_state(id: String) -> String:
	return String(st.files.get(id, ""))

func hidden_files() -> Array:
	var out := []
	for id in INV_ORDER:
		if file_state(id) == "hidden":
			out.append(id)
	return out

func add_case(n: float) -> void:
	st.case = clampf(float(st.case) + n, 0.0, 100.0)
	if hud:
		hud.refresh()

func add_pix(n: float) -> void:
	st.pix = clampf(float(st.pix) + n, 0.0, 100.0)
	if hud:
		hud.refresh()

# ---------------------------------------------------------------- тексты и разметка
func esc(s: String) -> String:
	return s.replace("[", "[lb]")

var _re_word := RegEx.create_from_string("<<(\\w+)\\|(.+?)>>")
var _re_clue := RegEx.create_from_string("\\{\\{(.+?)\\}\\}")

## Текст документа → BBCode. <<id|слово>> — ключевое слово (в режиме лупы — ссылка), {{улика}} — подсветка во 2-м круге.
func doc(s: String) -> String:
	var r := esc(s)
	r = _re_clue.sub(r, "[color=#a8443c]$1[/color]" if st.ng else "$1", true)
	var out := ""
	var pos := 0
	for m in _re_word.search_all(r):
		out += r.substr(pos, m.get_start() - pos)
		var id := m.get_string(1)
		var txt := m.get_string(2)
		if lens:
			var got: bool = st.words.has(id)
			out += "[url=%s][bgcolor=%s]%s[/bgcolor][/url]" % [id, "#948c8e55" if got else "#c49a4580", txt]
		else:
			out += txt
		pos = m.get_end()
	out += r.substr(pos)
	return out

func plain(s: String) -> String:
	return _re_clue.sub(_re_word.sub(s, "$2", true), "$1", true)

func word(id: String) -> String:
	return String(L.words.get(id, id))

func set_lens(on: bool) -> void:
	lens = on
	Sfx.play("click")
	lens_changed.emit(on)

func collect(id: String) -> void:
	if st.words.has(id) or not L.words.has(id):
		return
	st.words.append(id)
	Sfx.play("paper")
	words_changed.emit()
	if menus:
		menus.toast(L.ui.wordAdded % word(id))
	if st.words.size() >= 30:
		achieve("WORDS")
	# обучение: первое слово в банке → открой доску
	if fget("goal", "") == "lens" and pix:
		pix.goal("board")
		pix.say(L.lines.boardTut)
	save_game()

# ---------------------------------------------------------------- доска
func section(id: String) -> Dictionary:
	for s in L.board.sections:
		if s.id == id:
			return s
	return {}

func section_blanks(s: Dictionary) -> Array:
	var re := RegEx.create_from_string("\\{(\\w+)\\}")
	var out := []
	for line in s.lines:
		for m in re.search_all(line):
			out.append(m.get_string(1))
	return out

func section_open(id: String) -> bool:
	match id:
		"s1", "s2": return true
		"s3", "s4": return int(st.night) >= 2
		"s5": return st.solved.has("s3")
		"s6": return st.solved.has("s4") and st.solved.has("s5")
	return false

## Проверить раздел. Возвращает число ошибок (0 — верно), -1 — не заполнен.
func check_section(id: String) -> int:
	var s := section(id)
	var ans := section_blanks(s)
	var filled: Dictionary = st.blanks.get(id, {})
	var wrong := 0
	for i in ans.size():
		var got = filled.get(str(i), "")
		if got == "":
			return -1
		if word(got) != word(ans[i]):
			wrong += 1
	return wrong

# ---------------------------------------------------------------- достижения
func achieve(id: String) -> void:
	if meta.ach.has(id):
		return
	meta.ach[id] = Time.get_unix_time_from_system()
	save_meta()
	if steam:
		steam.setAchievement(id)
		steam.storeStats()
	var a = L.ach.get(id)
	if a and menus:
		menus.toast(L.ui.achTitle + ": " + a[0])
