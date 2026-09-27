extends Node
## Звук (автозагрузка «Sfx»): короткие эффекты и гул по стадиям. Все WAV сгенерированы tools/make_sfx.py.

var streams := {}
var pool: Array[AudioStreamPlayer] = []
var drone: AudioStreamPlayer
var drone_stage := -1
var muted := false
var _next := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in ["SFX", "Amb"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, b)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for n in ["click", "tick0", "tick1", "tick2", "tick3", "key", "err", "msg", "shard", "glitch", "scare",
			"door", "step", "heart", "chime", "sad", "soft", "stamp", "paper", "ring", "type", "drone0", "drone1", "drone2", "drone3"]:
		var s: AudioStreamWAV = load("res://sfx/%s.wav" % n)
		if n.begins_with("drone"):
			s = s.duplicate()
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = s.data.size() / 2
		streams[n] = s
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		pool.append(p)
	drone = AudioStreamPlayer.new()
	drone.bus = "Amb"
	drone.volume_db = -80
	add_child(drone)
	apply_volume()

func apply_volume() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(max(0.0001, G.settings.vol)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Amb"), linear_to_db(max(0.0001, G.settings.amb * G.settings.vol)))
	AudioServer.set_bus_mute(0, muted)

func play(n: String, vol_db := 0.0, pitch := 1.0) -> void:
	if not streams.has(n):
		return
	var p := pool[_next]
	_next = (_next + 1) % pool.size()
	p.stream = streams[n]
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.play()

func tick() -> void:
	var s := G.stage()
	play("tick%d" % s, -6.0, randf_range(0.95, 1.08) if s < 2 else 1.0)

func set_drone(stage: int) -> void:
	if stage == drone_stage and drone.playing:
		return
	drone_stage = stage
	drone.stream = streams["drone%d" % clamp(stage, 0, 3)]
	drone.play()
	var tw := create_tween()
	tw.tween_property(drone, "volume_db", [-18.0, -12.0, -6.0, -2.0][clamp(stage, 0, 3)], 2.5)

func stop_drone() -> void:
	var tw := create_tween()
	tw.tween_property(drone, "volume_db", -80.0, 1.5)

func duck(on: bool) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Amb"),
		-80.0 if on else linear_to_db(max(0.0001, G.settings.amb * G.settings.vol)))

func toggle() -> bool:
	muted = not muted
	apply_volume()
	return not muted
