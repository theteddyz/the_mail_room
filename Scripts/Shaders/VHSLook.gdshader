shader_type canvas_item;
#include "res://Assets/Textures/CLREDIT.gdshaderinc"

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform lowp sampler2D Screen_Sample : hint_screen_texture, filter_linear_mipmap_anisotropic;

//SHARPENING
group_uniforms sharpening;
uniform float SHARPENING : hint_range(0., 32.) = 1.5;

//CHROMATIC ABERRATION
group_uniforms chromatic_aberration;
uniform float CHROMATIC_DISTANCE : hint_range(0., 32.) = 3;

//FISH EYE LENS
group_uniforms fisheye_lens;
uniform float FISHEYE_AMOUNT : hint_range(-2.5, 2.5) = 1.0;

//LENS FLARE
group_uniforms lens_flare;
uniform lowp sampler2D FlareMult;
uniform lowp sampler2D FlareMult2;

uniform float Blur = 2.5;
uniform float FlareThreshold;
uniform int Flares;
uniform float FlareSpacing;

uniform float Intensity;
uniform float Saturation_;

//VHS SHADER
group_uniforms vhs_shader;
uniform vec2 vhs_resolution = vec2(320.0, 240.0);

uniform int samples = 2;
uniform float crease_noise: hint_range(0.0, 2.0, 0.1) = 1.0;
uniform float crease_opacity: hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float filter_intensity: hint_range(0.0, 1.0, 0.1) = 0.1;

uniform float tape_crease_smear: hint_range(0.0, 2.0, 0.1) = 0.2;
uniform float tape_crease_intensity: hint_range(0.0, 1.0, 0.1) = 0.2;
uniform float tape_crease_jitter: hint_range(0.0, 1.0, 0.01) = 0.10;
uniform float tape_crease_speed: hint_range(-2.0, 2.0, 0.1) = 0.5;
uniform float tape_crease_discoloration: hint_range(0.0, 2.0, 0.1) = 1.0;

uniform float bottom_border_thickness: hint_range(0.0,32.0, 0.1) = 6.0;
uniform float bottom_border_jitter: hint_range(0.0, 24.0, 0.5) = 6.0;

uniform float noise_intensity: hint_range(0.0, 1.0, 0.1) = 0.1;
uniform sampler2D noise_texture: filter_linear_mipmap, repeat_enable;

//VIGNETTE
group_uniforms vignette;
uniform float inner_radius = 0.2;
uniform float outer_radius = 1;
uniform float vignette_strength = 2.0;
uniform float dither_strength = 0.03;
uniform vec4 vignette_color: source_color;

vec4 sharpenMask(vec2 frag_coord, vec2 screen_pixel_size)
{
	// Calculate texel size using SCREEN_PIXEL_SIZE inside the fragment function
    //vec2 texel_size = 1.0 / screen_pixel_size;
	
    // Colors
    vec4 up = texture(SCREEN_TEXTURE, (frag_coord + vec2(0.0, 1.0)*0.0025));///texel_size);
    vec4 left = texture(SCREEN_TEXTURE, (frag_coord + vec2(-1.0, 0.0)*0.0025));///texel_size);
    vec4 center = texture(SCREEN_TEXTURE, frag_coord);///texel_size);
    vec4 right = texture(SCREEN_TEXTURE, (frag_coord + vec2(1.0, 0.0)*0.0025));///texel_size);
    vec4 down = texture(SCREEN_TEXTURE, (frag_coord + vec2(0.0, -1.0)*0.0025));///texel_size);
    
    // Return sharpened mask
    return (1.0 + 4.0 * SHARPENING) * center - SHARPENING * (up + left + right + down);
}

vec4 cromaticColor(vec2 uv, vec2 screen_pixel_size)
{
	vec2 r_displacement = vec2(CHROMATIC_DISTANCE, 0.0);
	vec2 g_displacement = vec2(0.0, 0.0);
	vec2 b_displacement = vec2(-CHROMATIC_DISTANCE, 0.0);
	
	float r = texture(SCREEN_TEXTURE, uv + vec2(screen_pixel_size*r_displacement), 0.0).r;
	float g = texture(SCREEN_TEXTURE, uv + vec2(screen_pixel_size*g_displacement), 0.0).g;
	float b = texture(SCREEN_TEXTURE, uv + vec2(screen_pixel_size*b_displacement), 0.0).b;
	
	return vec4(r, g, b, 1.0);
}

vec2 fisheyeColor(vec4 fragcoord,vec2 screen_pixel_size)
{
	vec2 iResolution = 1.0 / screen_pixel_size;
	vec4 fragCoord = fragcoord;

	//normalized coords 
	vec2 p = fragCoord.xy / iResolution.x;

	//screen proroption
	float prop = iResolution.x / iResolution.y;

	//center coords
	vec2 m = vec2(0.5, 0.5 / prop);

	//vector from center to current fragment
	vec2 d = p - m;

	// distance of pixel from center
	float r = sqrt(dot(d, d)); 

	float power = FISHEYE_AMOUNT;

	//radius of 1:1 effect
	float bind;
	
	//stick to borders
	if (power > 0.0) 
		bind = sqrt(dot(m, m));
	else {
		if (prop < 1.0) 
    		bind = m.x; 
    	else 
        	bind = m.y;
	}

	vec2 uv;
	//fisheye
	if (power > 0.0)
		uv = m + normalize(d) * tan(r * power) * bind / tan( bind * power);
	//antifisheye
	else if (power < 0.0)
		uv = m + normalize(d) * atan(r * -power * 10.0) * bind / atan(-power * bind * 10.0);
	//no effect for power = 1.0
	else
		uv = p;
    uv.y *= prop;

	vec3 col = texture(SCREEN_TEXTURE, uv).rgb;
    
	return uv;
}

vec4 lensflare(vec2 screen_uv){
	vec2 FlippedUV = vec2(1.0) - screen_uv;
	vec2 FlareVector = (vec2(0.5) - screen_uv) * FlareSpacing;
	vec3 FinalFlare = vec3(0.0);
	
	for (int i = 0; i < Flares; ++i){
		vec2 SUV = fract(screen_uv + FlareVector * vec2(float(i)));
		float Dist = distance(SUV, vec2(0.05));
		float Weight = 1.0 - smoothstep(0.0, 0.75, Dist);
		vec3 BlurredScreen = texture(SCREEN_TEXTURE, SUV, Blur).rgb;
		BlurredScreen = ApplyThreshold(BlurredScreen, FlareThreshold);
		FinalFlare += BlurredScreen * Weight;
		//FinalFlare = min(FinalFlare, vec3(0.01,0.01,0.01));
	}
	FinalFlare *= texture(FlareMult, screen_uv).rgb;
	FinalFlare *= texture(FlareMult2, screen_uv).rgb;
	vec3 finalColor = FinalFlare * Intensity;
	finalColor = Saturation(finalColor, Saturation_).rbg;
	return vec4(finalColor,1);
}

//VHS SHADER

float v2random(vec2 uv) {
	return texture(noise_texture, mod(uv, vec2(1.0))).x;
}

mat2 rotate2D(float t) {
	return mat2(vec2(cos(t), sin(t)), vec2(-sin(t), cos(t)));
}

vec3 rgb2yiq(vec3 rgb) {
	return mat3(vec3(0.299, 0.596, 0.211), vec3(0.587, -0.274, -0.523), vec3(0.114, -0.322, 0.312)) * rgb;
}

vec3 yiq2rgb(vec3 yiq) {
	return mat3(vec3(1.0, 1.0, 1.0), vec3(0.956, -0.272, -1.106), vec3(0.621, -0.647, 1.703)) * yiq;
}

vec3 vhx_tex_2D(sampler2D tex, vec2 uv, float rot) {
	vec3 yiq = vec3(0.0);
	for (int i = 0; i < samples; i++) {
		yiq += rgb2yiq(texture(tex, uv - vec2(float(i), 0.0) / vhs_resolution).xyz) *
				vec2(float(i), float(samples - 1 - i)).yxx / float(samples - 1)
				/ float(samples) * 2.0;
	}
	if (rot != 0.0) {
		yiq.yz *= rotate2D(rot * tape_crease_discoloration);
	}
	return yiq2rgb(yiq);
}

vec4 vhsShader(vec2 uv) {
	vec2 uvn = uv;
	vec3 col = vec3(0.0, 0.0, 0.0);

	// Tape wave.
	uvn.x += (v2random(vec2(uvn.y / 10.0, TIME / 10.0) / 1.0) - 0.5) / vhs_resolution.x * 1.0;
	uvn.x += (v2random(vec2(uvn.y, TIME * 10.0)) - 0.5) / vhs_resolution.x * 1.0;

	// tape crease
	float tc_phase = smoothstep(0.9, 0.96, sin(uvn.y * 8.0 - (TIME * tape_crease_speed + tape_crease_jitter * v2random(TIME * vec2(0.67, 0.59))) * PI * 1.2));
	float tc_noise = smoothstep(0.3, 1.0, v2random(vec2(uvn.y * 4.77, TIME)));
	float tc = tc_phase * tc_noise;
	uvn.x = uvn.x - tc / vhs_resolution.x * 8.0 * tape_crease_smear;

	// switching noise
	float sn_phase = smoothstep(1.0 - bottom_border_thickness / vhs_resolution.y, 1.0, uvn.y);
	uvn.x += sn_phase * (v2random(vec2(uv.y * 100.0, TIME * 10.0)) - 0.5) / vhs_resolution.x * bottom_border_jitter;

	// fetch
	col = vhx_tex_2D(SCREEN_TEXTURE, uvn, tc_phase * 0.2 + sn_phase * 2.0);

	// crease noise
	float cn = tc_noise * crease_noise * (0.7 * tc_phase * tape_crease_intensity + 0.3);
	if (0.29 < cn) {
		vec2 V = vec2(0.0, crease_opacity);
		vec2 uvt = (uvn + V.yx * v2random(vec2(uvn.y, TIME))) * vec2(0.1, 1.0);
		float n0 = v2random(uvt);
		float n1 = v2random(uvt + V.yx / vhs_resolution.x);
		if (n1 < n0) {
			col = mix(col, 2.0 * V.yyy, pow(n0, 10.0));
		}
	}

	// ac beat
	col *= 1.0 + 0.1 * smoothstep(0.4, 0.6, v2random(vec2(0.0, 0.1 * (uv.y + TIME * 0.2)) / 10.0));

	// color noise
	col *= 1.0 - noise_intensity * 0.5 + noise_intensity * texture(noise_texture, mod(uvn * vec2(1.0, 1.0) + TIME * vec2(5.97, 4.45), vec2(1.0))).xyz;
	col = clamp(col, 0.0, 1.0);

	// yiq
	col = rgb2yiq(col);
	col = vec3(0.9, 1.1, 1.5) * col + vec3(0.1, -0.1, 0.0) * filter_intensity;
	col = yiq2rgb(col);

	return vec4(col, 1.0);
}

//VIGNETTE
vec4 vignetteColor(vec2 uv) {
    float dist = distance(uv, vec2(0.5));
	
	float vignette = smoothstep(inner_radius, outer_radius, dist) * vignette_strength;
	float dither = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123) * dither_strength;
	
	float finalColor = 1.0 - (vignette + dither);
	
	return vec4(finalColor,finalColor,finalColor, 1);
}

void fragment()
{

	vec2 uvs = fisheyeColor(FRAGCOORD, SCREEN_PIXEL_SIZE);
	
    vec4 sharpenColor = sharpenMask(uvs, SCREEN_PIXEL_SIZE);
	
	vec4 chromaticColor = cromaticColor(uvs, SCREEN_PIXEL_SIZE);
	
	vec4 mixColor = lensflare(uvs);
	
	mixColor += mix(chromaticColor, sharpenColor,0.5);
	
	vec4 vhsColor = vhsShader(uvs);
	
	vec4 vhsMixColor = screen(mixColor,vhsColor);

	vec4 vinetteColor = vignetteColor(uvs);
	
	vec4 finalColor = multiply(vhsMixColor,vinetteColor);

	COLOR = finalColor;
}