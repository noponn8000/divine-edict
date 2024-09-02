shader_type canvas_item;

uniform bool fill_background = false;
uniform vec4 background_fill_color : source_color = vec4(0.071,0.071,0.071,1.0);

uniform bool blinking = false;
uniform bool blink_smoother = true;
uniform float blink_speed : hint_range(0.001, 100.0, 0.001) = 1.0;

uniform float minimum_visibility : hint_range(0.0,1.0,0.001) = 0.0;

void fragment() {
	if (blinking == true){
		COLOR.a *= float(!blink_smoother)*(minimum_visibility + (1.0 - minimum_visibility) * float(int(floor(TIME*blink_speed)) % 2)) + float(blink_smoother) * (minimum_visibility + (1.0 - minimum_visibility) * sin(((TIME*blink_speed)-floor(TIME*blink_speed))*PI));
		//COLOR.a = floor(COLOR.a*1000.0) * 0.001 * (COLOR.a*minimum_visibility + (1.0-minimum_visibility));
	}

	if (fill_background == true){
		vec4 temp_color = COLOR;
		temp_color.a = 1.0;
		COLOR.rgba = (1.0-COLOR.a)*background_fill_color+(COLOR.a)*temp_color;
	}
}