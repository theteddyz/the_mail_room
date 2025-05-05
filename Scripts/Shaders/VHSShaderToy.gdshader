shader_type canvas_item;

// Uniforms to mimic ShaderToy inputs
uniform sampler2D channel0 : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D channel1 : hint_screen_texture, filter_linear_mipmap;
uniform vec2 iResolution = vec2(512.0, 512.0);
uniform vec4 iMouse = vec4(0.0); // z is used for the button press
uniform float vignette_strength = 2.2;
uniform float final_blur_bias = 1.0;

vec4 Televisionfy(vec4 pixel, vec2 uv) {
    float vignette = pow(uv.x * (1.0 - uv.x) * uv.y * (1.0 - uv.y), 0.25) * vignette_strength;
    return pixel * vignette;
}

void fragment() {
    // Normalized coordinates
    vec2 uv = FRAGCOORD.xy / iResolution.xy;

    vec4 fragColor;

    // Emulating the iMouse.z > 0 condition
    if (iMouse.z <= 0.0) {
        fragColor = texture(channel0, uv, final_blur_bias);
        fragColor = Televisionfy(fragColor, uv);
    } else {
        fragColor = texture(channel1, uv);
    }

    COLOR = fragColor;
}