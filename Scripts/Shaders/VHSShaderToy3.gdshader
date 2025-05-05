shader_type canvas_item;

uniform sampler2D video_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec2 iResolution = vec2(512.0, 512.0);
uniform vec2 iMouse;

uniform vec2 maxResLuminance = vec2(335.0, 576.0);
uniform vec2 maxResChroma = vec2(40.0, 240.0);
uniform vec2 blurAmount = vec2(0.2, 0.2);

// === COMMON UTILITIES ===
#define lerp mix

const mat3 rgb2yiq = mat3(vec3(0.299, 0.596, 0.211),
                    vec3(0.587, -0.274, -0.523),
                    vec3(0.114, -0.322, 0.312));

const mat3 yiq2rgb = mat3(vec3(1, 1, 1),
                    vec3(0.956, -0.272, -1.106),
                    vec3(0.621, -0.647, 1.703));

vec4 cubic(float v) {
    vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
    vec4 s = n * n * n;
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return vec4(x, y, z, w) * (1.0/6.0);
}

vec4 textureBicubic(sampler2D sampler, vec2 texCoords) {
    vec2 texSize = vec2(textureSize(sampler, 0));
    vec2 invTexSize = vec2(1.0) / texSize;
    texCoords = texCoords * texSize - 0.5;
    vec2 fxy = fract(texCoords);
    texCoords -= fxy;
    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);
    vec4 c = texCoords.xxyy + vec2(-0.5, +1.5).xyxy;
    vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4(xcubic.yw, ycubic.yw) / s;
    offset *= invTexSize.xxyy;
    vec4 sample0 = texture(sampler, offset.xz);
    vec4 sample1 = texture(sampler, offset.yz);
    vec4 sample2 = texture(sampler, offset.xw);
    vec4 sample3 = texture(sampler, offset.yw);
    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);
    return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

vec3 downsampleVideo(vec2 uv, vec2 pixelSize, ivec2 samples, sampler2D tex) {
    vec2 uvStart = uv - pixelSize / 2.0;
    vec2 uvEnd = uv + pixelSize;
    vec3 result = vec3(0.0);
    for (int i_u = 0; i_u < samples.x; i_u++) {
        float u = lerp(uvStart.x, uvEnd.x, float(i_u) / float(samples.x));
        for (int i_v = 0; i_v < samples.y; i_v++) {
            float v = lerp(uvStart.y, uvEnd.y, float(i_v) / float(samples.y));
            result += texture(tex, vec2(u, v)).rgb;
        }
    }
    return result / float(samples.x * samples.y);
}

void fragment() {
    vec2 uv = FRAGCOORD.xy / iResolution.xy;
    vec2 resLuminance = min(maxResLuminance, iResolution);
    vec2 resChroma = min(maxResChroma, iResolution);
    vec2 uvLuminance = uv * (resLuminance / iResolution);
    vec2 uvChroma = uv * (resChroma / iResolution);
    vec2 mouseNormalized = iMouse / iResolution;

    vec3 result;

    if (uv.x > mouseNormalized.x) {
        vec2 pixelSizeLum = 1.0 / resLuminance * (1.0 + blurAmount);
        vec2 pixelSizeChr = 1.0 / resChroma * (1.0 + blurAmount);
        vec3 yiq;
        yiq.r = downsampleVideo(uvLuminance, pixelSizeLum, ivec2(8, 3), video_texture).r;
        vec3 chroma = downsampleVideo(uvChroma, pixelSizeChr, ivec2(8, 3), video_texture);
        yiq.gb = chroma.gb;
        result = yiq * yiq2rgb;
    } else {
        result = texture(video_texture, uv).rgb;
    }

    COLOR = vec4(result, 1.0);
}