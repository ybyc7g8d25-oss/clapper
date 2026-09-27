class_name FX
extends CanvasLayer
## Экранные эффекты поверх рабочего стола: стадии мрачности, глитч, вспышка, затемнение при визите.

const STAGES := [
	{"sat": 1.0, "bright": 1.0, "contrast": 1.0, "tint": Vector3(1, 1, 1), "vignette": 0.0, "scan": 0.0, "noise_amt": 0.0},
	{"sat": 0.72, "bright": 0.97, "contrast": 1.0, "tint": Vector3(1, 1, 1), "vignette": 0.35, "scan": 0.0, "noise_amt": 0.0},
	{"sat": 0.35, "bright": 0.84, "contrast": 1.08, "tint": Vector3(0.96, 0.98, 1.04), "vignette": 0.65, "scan": 0.45, "noise_amt": 0.05},
	{"sat": 0.25, "bright": 0.72, "contrast": 1.2, "tint": Vector3(1.18, 0.8, 0.76), "vignette": 1.0, "scan": 0.75, "noise_amt": 0.12},
]
var rect: ColorRect
var mat: ShaderMaterial
var stage := 0

func _ready() -> void:
	layer = 20
	rect = ColorRect.new()
	UI.full(rect)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/screen.gdshader")
	rect.material = mat
	for k in ["glitch", "flash", "dim"]:
		mat.set_shader_parameter(k, 0.0)
	add_child(rect)
	set_stage(0, true)

func low() -> bool:
	return G.settings.fx == "low"

func set_stage(n: int, instant := false) -> void:
	stage = n
	var s: Dictionary = STAGES[clamp(n, 0, 3)]
	var tw := create_tween().set_parallel()
	for k in s:
		var v = s[k]
		if low() and k == "noise_amt":
			v = 0.0
		if low() and k == "scan":
			v = v * 0.3
		if instant:
			mat.set_shader_parameter(k, v)
		else:
			tw.tween_property(mat, "shader_parameter/" + k, v, 3.0)
	if instant:
		tw.kill()

func glitch(power := 1.0) -> void:
	Sfx.play("glitch", -4.0, randf_range(0.8, 1.3))
	if low():
		return
	mat.set_shader_parameter("glitch", power)
	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_callback(func(): mat.set_shader_parameter("glitch", 0.0))
	flash(0.15, 0.07)

func flash(a: float, sec: float) -> void:
	if low():
		return
	mat.set_shader_parameter("flash", a)
	var tw := create_tween()
	tw.tween_property(mat, "shader_parameter/flash", 0.0, sec)

func dim(v: float, sec := 0.6) -> void:
	create_tween().tween_property(mat, "shader_parameter/dim", v, sec)
