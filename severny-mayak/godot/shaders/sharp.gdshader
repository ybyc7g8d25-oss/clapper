// Чёткое масштабирование пиксель-арта на любой размер экрана (sharp bilinear):
// внутри пикселя — ровный цвет, на границах — сглаживание шириной в 1 экранный пиксель.
shader_type canvas_item;
uniform vec2 src_size = vec2(480.0, 270.0);
uniform float scale = 4.0;
void fragment() {
	vec2 texel = UV * src_size;
	vec2 fl = floor(texel);
	vec2 s = fract(texel);
	float r = 0.5 - 0.5 / max(scale, 1.0);
	vec2 cd = s - 0.5;
	vec2 f = (cd - clamp(cd, -r, r)) * scale + 0.5;
	COLOR = texture(TEXTURE, (fl + f) / src_size);
}
