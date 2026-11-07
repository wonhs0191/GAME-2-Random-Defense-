shader_type canvas_item;

// 집어 든 유닛의 외곽선. 투명한 픽셀 중 불투명한 픽셀 옆에 있는 것을 칠한다.

uniform vec4 outline_color : source_color = vec4(1.0);
uniform float width = 4.0; // 텍스처 픽셀 단위

const vec2 DIRECTIONS[8] = {
	vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
	vec2(0.7, 0.7), vec2(-0.7, 0.7), vec2(0.7, -0.7), vec2(-0.7, -0.7)
};

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (color.a < 0.5) {
		for (int i = 0; i < 8; i++) {
			if (texture(TEXTURE, UV + DIRECTIONS[i] * TEXTURE_PIXEL_SIZE * width).a >= 0.5) {
				color = outline_color;
				break;
			}
		}
	}
	COLOR = color;
}
