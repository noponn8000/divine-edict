shader_type canvas_item;

uniform float desaturation = 0.0;
uniform float greyscale =  0.0;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;

void fragment() {
	COLOR.rgb = texture(SCREEN_TEXTURE, UV).rgb - desaturation;

	if (greyscale > 0.0) {
		float average = (texture(SCREEN_TEXTURE, UV).r + texture(SCREEN_TEXTURE, UV).b + texture(SCREEN_TEXTURE, UV).g) / 3.0f;
		COLOR.rgb = vec3(average) + (1.0f - greyscale) * COLOR.rgb;
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
