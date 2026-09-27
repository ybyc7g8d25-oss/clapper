// Экранный эффект стадий мрачности: выцветание, оттенок, виньетка, скан-линии, пиксельный шум, глитч, вспышка.
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float sat = 1.0;
uniform float bright = 1.0;
uniform float contrast = 1.0;
uniform vec3 tint = vec3(1.0);
uniform float vignette = 0.0;
uniform float scan = 0.0;
uniform float noise_amt = 0.0;
uniform float glitch = 0.0;
uniform float flash = 0.0;
uniform float dim = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = floor(TIME * 12.0);
	if (glitch > 0.0) {
		float band = floor(uv.y * 30.0);
		float off = (hash(vec2(band, t)) - 0.5) * 0.04 * glitch;
		if (hash(vec2(band * 1.7, t)) > 0.6) uv.x += off;
	}
	vec3 c = texture(screen_tex, uv).rgb;
	if (glitch > 0.0) {
		c.r = texture(screen_tex, uv + vec2(0.006 * glitch, 0.0)).r;
		c.b = texture(screen_tex, uv - vec2(0.006 * glitch, 0.0)).b;
	}
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, sat);
	c = (c - 0.5) * contrast + 0.5;
	c *= bright * tint;
	// скан-линии по рядам «пикселей арта» (2 пикселя экрана 960x540)
	float row = mod(floor(uv.y * 270.0), 2.0);
	c *= 1.0 - scan * 0.35 * row;
	// шум размером с пиксель арта
	vec2 cell = floor(uv * vec2(480.0, 270.0));
	c += (hash(cell + t) - 0.5) * noise_amt;
	// виньетка
	vec2 d = uv - 0.5;
	c *= 1.0 - vignette * smoothstep(0.25, 0.75, length(d * vec2(1.2, 1.0)));
	c *= 1.0 - dim;
	c = mix(c, vec3(1.0), flash);
	COLOR = vec4(c, 1.0);
}
