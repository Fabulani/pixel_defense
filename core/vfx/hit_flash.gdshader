shader_type canvas_item;

// Mixes the sprite colour towards white; alpha is preserved.
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// COLOR already holds texture * modulate here; do not sample TEXTURE again.
	COLOR = vec4(mix(COLOR.rgb, vec3(1.0), flash), COLOR.a);
}
