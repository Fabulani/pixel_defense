shader_type canvas_item;

// Mixes the sprite colour towards flash_color (white by default); alpha is preserved.
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// COLOR already holds texture * modulate here; do not sample TEXTURE again.
	COLOR = vec4(mix(COLOR.rgb, flash_color.rgb, flash), COLOR.a);
}
