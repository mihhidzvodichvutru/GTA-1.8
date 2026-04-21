shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float do_xam : hint_range(0.0, 1.0) = 0.0; // 0 là có màu, 1 là đen trắng

void fragment() {
    vec4 mau_goc = texture(screen_texture, SCREEN_UV);
    // Tính độ sáng (Luminance)
    float do_sang = dot(mau_goc.rgb, vec3(0.299, 0.587, 0.114));
    // Trộn giữa màu gốc và màu xám dựa trên tham số do_xam
    COLOR.rgb = mix(mau_goc.rgb, vec3(do_sang), do_xam);
    COLOR.a = mau_goc.a;
}