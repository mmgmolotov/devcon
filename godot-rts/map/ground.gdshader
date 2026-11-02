shader_type canvas_item;
// Procedural ground. TEXTURE is a 64x64 terrain map sampled with linear
// filtering: R = dirt amount, G = water amount. Detail comes from a tiling
// noise texture sampled at several scales (cheap on mobile GPUs).

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec2 map_px = vec2(2048.0, 2048.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 wp = UV * map_px;
	vec4 t = texture(TEXTURE, UV);
	float n_big = texture(noise_tex, wp / 700.0).r;
	float n_mid = texture(noise_tex, wp / 210.0).r;
	float n_small = texture(noise_tex, wp / 55.0).r;
	float n_fine = texture(noise_tex, wp / 13.0).r;

	// Grass with large colour patches and fine blade texture.
	vec3 col = mix(vec3(0.27, 0.46, 0.17), vec3(0.44, 0.61, 0.25), smoothstep(0.3, 0.7, n_big * 0.6 + n_mid * 0.4));
	col *= 0.92 + 0.14 * n_fine;
	col = mix(col, col * vec3(0.9, 1.06, 0.82), smoothstep(0.55, 0.72, n_small));

	// Scattered flowers and tufts.
	vec2 cell = floor(wp / 12.0);
	float h = hash(cell);
	if (h > 0.955 && t.r < 0.25 && t.g < 0.1) {
		vec2 f = fract(wp / 12.0) - 0.5 - (vec2(hash(cell + 3.1), hash(cell + 7.7)) - 0.5) * 0.6;
		float d = length(f);
		vec3 fc = h > 0.985 ? vec3(0.98, 0.88, 0.3) : (h > 0.97 ? vec3(0.95, 0.95, 0.95) : vec3(0.22, 0.38, 0.13));
		col = mix(col, fc, smoothstep(0.13, 0.07, d));
	}

	// Dirt (base yards and road) with pebbles.
	float dirt = smoothstep(0.35, 0.6, t.r + (n_mid - 0.5) * 0.35);
	vec3 dirt_col = mix(vec3(0.5, 0.4, 0.26), vec3(0.64, 0.54, 0.37), n_small) * (0.9 + 0.2 * n_fine);
	float peb = step(0.975, hash(floor(wp / 5.0)));
	dirt_col = mix(dirt_col, vec3(0.42, 0.36, 0.28), peb * 0.6);
	col = mix(col, dirt_col, dirt);

	// Shore sand, then animated water.
	float wv = t.g + (n_mid - 0.5) * 0.2;
	col = mix(col, vec3(0.78, 0.7, 0.5) * (0.94 + 0.12 * n_fine), smoothstep(0.2, 0.32, wv));
	float water = smoothstep(0.4, 0.47, wv);
	vec3 wc = mix(vec3(0.22, 0.5, 0.6), vec3(0.09, 0.27, 0.44), smoothstep(0.5, 0.9, wv));
	float w1 = texture(noise_tex, wp / 110.0 + vec2(TIME * 0.02, TIME * 0.012)).r;
	float w2 = texture(noise_tex, wp / 65.0 - vec2(TIME * 0.014, -TIME * 0.019)).r;
	wc += vec3(0.1, 0.12, 0.12) * smoothstep(0.6, 0.72, (w1 + w2) * 0.5);
	float foam = smoothstep(0.4, 0.44, wv) - smoothstep(0.45, 0.52, wv);
	wc = mix(wc, vec3(0.88, 0.94, 0.96), clamp(foam, 0.0, 1.0) * 0.7);
	col = mix(col, wc, water);

	COLOR = vec4(col, 1.0);
}
