shader_type canvas_item;

uniform float SHARPEN_FACTOR : hint_range(0., 32.) = 1.5;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
vec4 sharpenMask(sampler2D tex, vec2 frag_coord, vec2 texel_size)
{
    // Colors
    vec4 up = texture(tex, (frag_coord + vec2(0.0, 1.0))/texel_size);
    vec4 left = texture(tex, (frag_coord + vec2(-1.0, 0.0))/texel_size);
    vec4 center = texture(tex, frag_coord/texel_size);
    vec4 right = texture(tex, (frag_coord + vec2(1.0, 0.0))/texel_size);
    vec4 down = texture(tex, (frag_coord + vec2(0.0, -1.0))/texel_size);
    
    // Return sharpened mask
    return (1.0 + 4.0 * SHARPEN_FACTOR) * center - SHARPEN_FACTOR * (up + left + right + down);
}

void fragment()
{
    // Calculate texel size using SCREEN_PIXEL_SIZE inside the fragment function
    vec2 texel_size = 1.0 / SCREEN_PIXEL_SIZE;

    // Apply sharpen mask using the screen texture and frag coordinates
    COLOR = sharpenMask(SCREEN_TEXTURE, FRAGCOORD.xy, texel_size);
}