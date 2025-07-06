shader_type spatial;

render_mode skip_vertex_transform, cull_disabled, blend_mix;

/* ------------------------------------------------------------------ */
/* Public controls                                                    */
/* ------------------------------------------------------------------ */
uniform vec2  wind_direction    = vec2(1.0, 1.0);   // XY in XZ-plane
uniform float sway_strength     = 0.35;             // keeps compat w/ old flutter
uniform float sway_speed        = 2.0;              // legacy (still used for colour jitter)

/* Noise-driven wind parameters ------------------------------------- */
uniform sampler2D wind_noise_tex;      // tileable greyscale noise
uniform float noise_scale       = 0.15;             // world-to-UV scale
uniform float gust_amplitude    = 1.0;              // low-freq gust strength
uniform float gust_speed        = 0.6;              // scroll rate through noise field
uniform float flutter_scale     = 3.5;              // frequency multiplier for high-freq flutter
uniform float flutter_strength  = 0.5;              // high-freq strength

uniform float bend_exponent     = 2.5;              // 1 = linear, >1 = exponential

varying vec4 data;  // .rg = per-instance tint, .b = tip factor, .a = force

/* ================================================================== */
/* VERTEX                                                             */
/* ================================================================== */
void vertex()
{
    /* 1. model-space pinch towards the tip --------------------------- */
    data.b = (VERTEX.y + 0.55);
    data.b *= data.b;                    // quadratic fall-off
    VERTEX.xz *= (1.0 - data.b);         // pinch blade

    /* colour tweaks (unchanged) ------------------------------------- */
    COLOR  = mix(COLOR, vec4(1.0), smoothstep(0.9, 1.0, data.b));
    COLOR *= INSTANCE_CUSTOM[3] < 0.35 ? 1.0
                                       : mix(1.0, 0.75, smoothstep(0.35, 0.0, data.b));
    data.rg = INSTANCE_CUSTOM.rg;

    /* 2. world-space position & large-scale bend -------------------- */
    vec3 w_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    float scale  = pow(INSTANCE_CUSTOM[3] * INSTANCE_CUSTOM[3], 0.707);
    float force  = INSTANCE_CUSTOM[2] * data.b * scale;
    force       -= fract(force * 256.0) * force * 0.05;  // cheap jitter
    force        = pow(force, 0.707);

    float lateral = sin(TIME * 2.0 * (1.0 + data.r + data.g)) *
                    0.25 * (1.0 - INSTANCE_CUSTOM[2]);

    vec2 dir = normalize(wind_direction);
    w_vertex.xz -= (vec2(-dir.y, dir.x) * lateral + dir) * force;
    w_vertex.y  -= INSTANCE_CUSTOM[2] * force * data.b;

    data.a = force;   // pass to fragment

    /* 3. noise-driven gust + flutter (still world space) ------------ */
    vec2 patch_offset = INSTANCE_CUSTOM.rg * 1.3;  // decorrelate neighbours
    vec2 noise_uv = (w_vertex.xz +patch_offset) * noise_scale
                  + TIME * gust_speed * dir;

    float gust    = texture(wind_noise_tex, noise_uv).r * 2.0 - 1.0;
    float flutter = texture(wind_noise_tex,
                            noise_uv * flutter_scale + vec2(42.0)).r * 2.0 - 1.0;
    /* -------------------------------------------------------------- */
    /* 3. noise-driven gust + flutter                                 */
    /* -------------------------------------------------------------- */
    /* --------   exponential taper mask (tip = 1, base = 0) -------- */
    float bend_mask = pow(clamp(1.0 - UV.y, 0.0, 1.0), bend_exponent);
    float bend = (gust * gust_amplitude * sway_strength +
                  flutter * sway_strength * flutter_strength) *
                 //(1.0 - UV.y) *                 // taper toward base
                 (1.0 + force)                 // let gusts amplify big bend
				* -bend_mask;         // exponential fade toward root
				
    w_vertex.xz += dir * bend;                  // push along wind dir
    w_vertex.y  += bend * 0.35;                 // slight lift / drop

    /* optional curl noise swirl ------------------------------------- */
    vec2 n0 = texture(wind_noise_tex, noise_uv).rg;
    vec2 n1 = texture(wind_noise_tex, noise_uv + vec2(0.02)).rg;
    float curl = n1.g - n0.r;
    w_vertex.xz += vec2(-curl, curl) * bend * 0.4;

    /* 4. finally convert to view space ------------------------------ */
    VERTEX = (VIEW_MATRIX * vec4(w_vertex, 1.0)).xyz;

    NORMAL   = MODELVIEW_NORMAL_MATRIX * NORMAL;
    BINORMAL = MODELVIEW_NORMAL_MATRIX * BINORMAL;
    TANGENT  = MODELVIEW_NORMAL_MATRIX * TANGENT;
}

/* ================================================================== */
/* FRAGMENT (unchanged from original)                                 */
/* ================================================================== */
void fragment()
{
    ALBEDO      = vec3(0.20, 0.22, 0.05) * (data.b * 0.5 + 0.5);
    ALBEDO.rg  *= (data.rg * 0.3 + 0.9);
    ALBEDO     *= pow(COLOR.rgb, vec3(2.2));

    float spec_rough = clamp(max(data.b, data.a), 0.0, 1.0);
    ROUGHNESS = 1.0;
    SPECULAR  = clamp(spec_rough * 0.25, 0.0, 0.15);
    BACKLIGHT = vec3(0.33);

    #if CURRENT_RENDERER == RENDERER_COMPATIBILITY
    ALBEDO = pow(ALBEDO, vec3(0.4));
    #endif
}
