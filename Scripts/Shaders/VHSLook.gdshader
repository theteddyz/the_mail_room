shader_type canvas_item;
#include "res://Assets/Textures/CLREDIT.gdshaderinc"

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform lowp sampler2D Screen_Sample : hint_screen_texture, filter_linear_mipmap_anisotropic;

//SHARPENING
group_uniforms sharpening;
uniform float SHARPENING : hint_range(0., 32.) = 1.5;
uniform float SHARPEN_DISTANCE : hint_range(0., 0.01) = 0.0025;

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

uniform float Blur = 5.0;
uniform float FlareThreshold = 0.6;
uniform int Flares = 4;
uniform float FlareSpacing = 0.5;

uniform float Intensity = 8.0;
uniform float FALLOFF_STARTING_POINT : hint_range(0, 0.1) = 0.05;
uniform float Saturation_ = 0.48;

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
    vec4 up = texture(SCREEN_TEXTURE, (frag_coord + vec2(0.0, 1.0)*SHARPEN_DISTANCE));///texel_size);
    vec4 left = texture(SCREEN_TEXTURE, (frag_coord + vec2(-1.0, 0.0)*SHARPEN_DISTANCE));///texel_size);
    vec4 center = texture(SCREEN_TEXTURE, frag_coord);///texel_size);
    vec4 right = texture(SCREEN_TEXTURE, (frag_coord + vec2(1.0, 0.0)*SHARPEN_DISTANCE));///texel_size);
    vec4 down = texture(SCREEN_TEXTURE, (frag_coord + vec2(0.0, -1.0)*SHARPEN_DISTANCE));///texel_size);

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
		float Dist = distance(SUV, vec2(FALLOFF_STARTING_POINT));
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

//VIGNETTE
vec4 vignetteColor(vec2 uv) {
    float dist = distance(uv, vec2(0.5));

	float vignette = smoothstep(inner_radius, outer_radius, dist) * vignette_strength;
	float dither = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123) * dither_strength;

	float finalColor = 1.0 - (vignette + dither);

	return vec4(finalColor,finalColor,finalColor, 1);
}

vec4 lighten(vec4 base, vec4 blend){
	return max(base, blend);
}

vec4 BlendMode_Difference(vec4 base, vec4 blend){
	return abs(base-blend);
}

void fragment()
{

	vec2 uvs = fisheyeColor(FRAGCOORD, SCREEN_PIXEL_SIZE);

    vec4 sharpenColor = sharpenMask(uvs, SCREEN_PIXEL_SIZE);

	vec4 chromaticColor = cromaticColor(uvs, SCREEN_PIXEL_SIZE);

	vec4 mixColor = lensflare(uvs);

	vec4 originalColor = texture(SCREEN_TEXTURE, uvs, 0.0);

	mixColor += sharpenColor + BlendMode_Difference(originalColor,chromaticColor); //overlay(chromaticColor, sharpenColor);

	vec4 vhsMixColor = mixColor;

	vec4 vinetteColor = vignetteColor(uvs);

	vec4 finalColor = multiply(vhsMixColor,vinetteColor);

	COLOR = finalColor;
}

