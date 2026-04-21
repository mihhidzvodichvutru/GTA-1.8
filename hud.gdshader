shader_type canvas_item;

// Bí quyết làm mờ nằm ở chữ filter_linear_mipmap này:
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 10;

void fragment() {
    COLOR = textureLod(screen_texture, SCREEN_UV, blur_amount);
}