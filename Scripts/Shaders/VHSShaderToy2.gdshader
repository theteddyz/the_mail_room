shader_type canvas_item;

// ===== UNIFORMS (ShaderToy equivalents) =====
uniform sampler2D channel0 : hint_screen_texture, filter_linear_mipmap;
uniform vec2 iResolution = vec2(512.0, 512.0);
uniform float stretch_strength = 1.0;
uniform float crease_strength = 1.0;
uniform float chromatic_distance = 1.0;

// ===== CONSTANTS =====
//const float PI = 3.14159265;

// ===== FUNCTIONS =====
float hash(vec2 v) {
    return fract(sin(dot(v, vec2(89.44, 19.36))) * 22189.22);
}

float iHash(vec2 v, vec2 r) {
    vec2 base = floor(v * r) / r;
    float h00 = hash(base + vec2(0.0, 0.0));
    float h10 = hash(base + vec2(1.0, 0.0));
    float h01 = hash(base + vec2(0.0, 1.0));
    float h11 = hash(base + vec2(1.0, 1.0));

    vec2 ip = smoothstep(vec2(0.0), vec2(1.0), fract(v * r));
    return mix(mix(h00, h10, ip.x), mix(h01, h11, ip.x), ip.y);
}

float noise(vec2 v) {
    float sum = 0.0;
    for (int i = 1; i < 9; i++) {
        float fi = float(i);
        sum += iHash(v + vec2(fi), vec2(2.0 * pow(2.0, fi))) / pow(2.0, fi);
    }
    return sum;
}

vec3 tex2D(sampler2D tex, vec2 p) {
    vec3 col = texture(tex, p).rgb;
    if (abs(p.x - 0.5) > 0.5) {
        col = vec3(0.1);
    }
    return col;
}

// ===== MAIN FRAGMENT =====
void fragment() {
    vec2 uv = FRAGCOORD.xy / iResolution.xy;
    vec2 uvn = uv;
    vec3 col = vec3(0.0);

    // Tape wave
    uvn.x += (noise(vec2(uvn.y, TIME)) - 0.5) * 0.005*stretch_strength;
    uvn.x += (noise(vec2(uvn.y * 100.0, TIME * 10.0)) - 0.5) * 0.01*stretch_strength;

    // Tape crease
    float tcPhase = clamp((sin(uvn.y * 8.0 - TIME* PI * 1.2) - 0.92) * noise(vec2(TIME)), 0.0, 0.01) * 10.0;
    float tcNoise = max(noise(vec2(uvn.y * 100.0, TIME * 10.0)) - 0.5, 0.0);
    uvn.x -= tcNoise * tcPhase*crease_strength;

    // Switching noise
    float snPhase = smoothstep(0.97, 1.0, uvn.y);
    uvn.y += snPhase * 0.3;
    uvn.x += snPhase * ((noise(vec2(uv.y * 100.0, TIME * 10.0)) - 0.5) * 0.2);

    // Base color
    //col = tex2D(channel0, uvn);
    //col *= 1.0 - tcPhase;

    // Mix YZX based on switching noise
    col = mix(col, col.yzx, snPhase);

    // Bloom effect
    for (float x = -4.0; x < 2.5; x += 1.0) {
        col += vec3(
            tex2D(channel0, uvn + vec2(x - 0.0, 0.0) * 0.007*chromatic_distance).r,
            tex2D(channel0, uvn + vec2(x - 2.0, 0.0) * 0.007*chromatic_distance).g,
            tex2D(channel0, uvn + vec2(x - 4.0, 0.0) * 0.007*chromatic_distance).b
        ) * 0.1;
    }
    //col *= 0.6;

    // AC beat noise
    //col *= 1.0 + clamp(noise(vec2(0.0, uv.y + TIME * 0.2)) * 0.6 - 0.25, 0.0, 0.1);

    COLOR = vec4(col, 1.0);
}