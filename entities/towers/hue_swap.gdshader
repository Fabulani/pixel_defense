shader_type canvas_item;

// Replaces the hue of coloured pixels with the hue of target_color.
// Greys and the dark outline (saturation <= 0.30) stay untouched; the sprite
// palette's coloured pixels all have saturation >= 0.71, so 0.5 separates them.
// A non-white modulate feeds the saturation test, since COLOR includes it.
uniform vec4 target_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float saturation_threshold = 0.5;
// Mixes the result towards flash_color (white by default; hit/build flash); 0.0 keeps the look unchanged.
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

vec3 rgb_to_hsv(vec3 c) {
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float d = mx - mn;
	float h = 0.0;
	if (d > 0.00001) {
		if (mx == c.r) {
			h = mod((c.g - c.b) / d, 6.0);
		} else if (mx == c.g) {
			h = (c.b - c.r) / d + 2.0;
		} else {
			h = (c.r - c.g) / d + 4.0;
		}
		h /= 6.0;
	}
	float s = (mx > 0.00001) ? d / mx : 0.0;
	return vec3(h, s, mx);
}

vec3 hsv_to_rgb(vec3 c) {
	vec3 p = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return c.z * mix(vec3(1.0), p, c.y);
}

void fragment() {
	// COLOR already holds texture * modulate here; do not sample TEXTURE again.
	vec4 c = COLOR;
	vec3 hsv = rgb_to_hsv(c.rgb);
	vec3 rgb = c.rgb;
	if (hsv.y > saturation_threshold) {
		float hue = rgb_to_hsv(target_color.rgb).x;
		rgb = hsv_to_rgb(vec3(hue, hsv.y, hsv.z));
	}
	COLOR = vec4(mix(rgb, flash_color.rgb, flash), c.a);
}
