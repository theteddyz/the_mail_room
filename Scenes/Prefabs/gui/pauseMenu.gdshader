shader_type canvas_item;

uniform float blur_size = 4.0;
uniform int blur_steps = 8;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec4 color = vec4(0.0);
    vec2 tex_size = vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 pixel_size = blur_size / tex_size;

    for (int x = -blur_steps; x <= blur_steps; x++) {
        for (int y = -blur_steps; y <= blur_steps; y++) {
            vec2 offset = vec2(float(x), float(y)) * pixel_size;
            color += texture(SCREEN_TEXTURE, SCREEN_UV + offset);
        }
    }

    color /= pow(float(blur_steps) * 2.0 + 1.0, 2.0);
    COLOR = color;
}
