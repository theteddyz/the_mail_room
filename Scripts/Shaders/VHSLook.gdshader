shader_type canvas_item;
#include "res://Assets/Textures/CLREDIT.gdshaderinc"

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform lowp sampler2D Screen_Sample : hint_screen_texture, filter_linear_mipmap_anisotropic;

//NOISE
group_uniforms noise;
uniform float stretch_noise : hint_range(0., 0.5) = 0.05;
uniform float crease_noise : hint_range(0., 0.5) = 0.0;
uniform float crease_speed : hint_range(0., 1.0) = 0.3;

//SWITCHING NOISE
group_uniforms switching_noise;
uniform float switching_noise : hint_range(0., 5.0) = 2.0;
uniform float switching_height : hint_range(0., 100.0) = 30.0;
uniform float switching_offset : hint_range(0., 0.1) = 0.03;

//SHARPENING
group_uniforms sharpening;
uniform float SHARPENING : hint_range(0., 32.) = 1.5;
uniform float SHARPEN_DISTANCE : hint_range(0., 0.01) = 0.0025;

//CHROMATIC ABERRATION
group_uniforms chromatic_aberration;
uniform float CHROMATIC_DISTANCE : hint_range(0., 32.) = 3;

//CHROMATIC ABERRATION RBG
group_uniforms chromatic_aberration_rbg;
uniform float CHROMATIC_RGB_DISTANCE : hint_range(0., 1.) = 0.1;



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



//COLOR BLEED
group_uniforms color_bleed;
uniform float color_bleed_seperation : hint_range(0.0, 0.1, 0.001) = 0.02;
uniform float color_bleed_intensity : hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float anti_bleed_intensity : hint_range(0.0, 3.0, 0.01) = 1.8;
uniform float color_bleed_blur_strength : hint_range(0.0, 4.0, 1.0) = 1.0;
uniform int color_bleed_quality : hint_range(1, 16, 1) = 5;



vec4 sharpenMask(vec2 frag_coord, vec2 screen_pixel_size)
{
	// Calculate texel size using SCREEN_PIXEL_SIZE inside the fragment function
    //vec2 texel_size = 1.0 / screen_pixel_size;
	vec3 BlurredScreen = texture(SCREEN_TEXTURE, frag_coord, Blur).rgb;
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

vec4 cromaticColorRGB(vec2 uvn, vec2 screen_pixel_size)
{
	vec4 col = vec4(0,0,0,0);
	 // Bloom effect
    for (float x = -4.0; x < 2.5; x += 1.0) {
        col += vec4(
            texture(SCREEN_TEXTURE, uvn + vec2(x - 0.0, 0.0) * 0.007*CHROMATIC_RGB_DISTANCE).r,
            texture(SCREEN_TEXTURE, uvn + vec2(x - 2.0, 0.0) * 0.007*CHROMATIC_RGB_DISTANCE).g,
            texture(SCREEN_TEXTURE, uvn + vec2(x - 4.0, 0.0) * 0.007*CHROMATIC_RGB_DISTANCE).b,
			1.0
        ) * 0.1;
    }
	return col;
}


//LENS DUST
group_uniforms lens_dust;
uniform float dust_multiplier : hint_range(0, 2.0) = 1.0;
uniform float dust_threshold : hint_range(0, 2.0) = 0.6;
uniform float dust_distance : hint_range(0, 1.0) = 0.05;
uniform float dust_blur : hint_range(0, 10.0) = 5.0;
uniform float dust_falloff : hint_range(0, 0.1) = 0.05;
vec4 lensflare(vec2 screen_uv){
	vec2 FlippedUV = vec2(1.0) - screen_uv;
	vec2 FlareVector = (vec2(0.5) - screen_uv) * FlareSpacing;
	vec3 FinalFlare = vec3(0.0);

	//vec2 SUV = screen_uv;
	//vec3 BlurredScreen = texture(SCREEN_TEXTURE, SUV, dust_blur).rgb;
//
	//float max_channel = max(max(BlurredScreen.r, BlurredScreen.g), BlurredScreen.b);
//
	//// Only include if luminance exceeds threshold
	//if (max_channel > dust_threshold) {
	    //FinalFlare += BlurredScreen * dust_multiplier;
	//}
	vec3 FinalDust = vec3(0.0);
	for (int i = -2; i < 2; ++i){
		for (int j = -2; j < 2; ++j){
			vec2 SUV =  fract(screen_uv + vec2(float(i),float(j))*dust_distance);
			float Dist = distance(SUV, vec2(dust_falloff));
			float Weight = 1.0;//- smoothstep(0.0, 0.75, Dist);
			vec3 BlurredScreen = texture(SCREEN_TEXTURE, SUV, dust_blur).rgb;
			BlurredScreen = ApplyThreshold(BlurredScreen, FlareThreshold);
			FinalDust += BlurredScreen * Weight*2.0;
		}
	}
	FinalDust *= texture(FlareMult, screen_uv).rgb;
	
	for (int i = 0; i < Flares; ++i){
		vec2 SUV = fract(screen_uv + FlareVector * vec2(float(i)));
		float Dist = distance(SUV, vec2(FALLOFF_STARTING_POINT));
		float Weight = 1.0 - smoothstep(0.0, 0.75, Dist);
		vec3 BlurredScreen = texture(SCREEN_TEXTURE, SUV, Blur).rgb;
		BlurredScreen = ApplyThreshold(BlurredScreen, FlareThreshold);
		FinalFlare += BlurredScreen * Weight;
	}
	FinalFlare *= texture(FlareMult, screen_uv).rgb;
	FinalFlare *= texture(FlareMult2, screen_uv).rgb;
	vec3 finalColor = FinalFlare * Intensity + FinalDust * dust_multiplier;
	finalColor = Saturation(finalColor, Saturation_).rbg;
	

	
	return vec4(finalColor,1);
}



vec4 lighten(vec4 base, vec4 blend){
	return max(base, blend);
}

vec4 BlendMode_Difference(vec4 base, vec4 blend){
	return abs(base-blend);
}

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
uniform int dust_strength : hint_range(1, 64) = 4;

vec4 get_brightness_mask(sampler2D tex, vec2 uv) {
    vec4 color = texture(tex, uv);
    float brightness = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    if (brightness > dust_threshold) {
        return color;
    } else {
        return vec4(0.0, 0.0, 0.0, 0.0); // Make it fully transparent black
    }
}

vec4 blur_brightness_mask(sampler2D tex, vec2 fragCoord, vec2 pixelSize) {
    vec4 sum = vec4(0.0);
    float total = 0.0;
    float radius = float(dust_strength);

    for (int x = -dust_strength; x <= dust_strength; x++) {
        for (int y = -dust_strength; y <= dust_strength; y++) {
            vec2 offset = vec2(float(x), float(y)) * pixelSize;
            vec4 col = get_brightness_mask(tex, fragCoord + offset);
            float weight = 1.0; // You can use a Gaussian weight here for better quality
            sum += col * weight;
            total += weight;
        }
    }

    return sum / total;
}
void fragment()
{


	vec2 uvs = SCREEN_UV;

	// Tape wave
    uvs.x += (noise(vec2(uvs.y, TIME)) - 0.5) * 0.005*stretch_noise;
    uvs.x += (noise(vec2(uvs.y * 100.0, TIME * 10.0)) - 0.5) * 0.01*stretch_noise;
	
	// Tape crease
    float tcPhase = clamp((sin(uvs.y * 8.0 - TIME*crease_speed* PI * 1.2) - 0.92) * noise(vec2(TIME)), 0.0, 0.01) * 10.0;
    float tcNoise = max(noise(vec2(uvs.y * 100.0, TIME*crease_speed * 10.0)) - 0.5, 0.0);
    uvs.x -= tcNoise * tcPhase*crease_noise;

		// Get screen coordinates
	vec2 screen_coords = FRAGCOORD.xy;
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	float screen_height = screen_size.y;
	float squish_height = switching_height;

	//Switching Noise
	// Check if we're in the bottom 10 pixels
	if (screen_coords.y > (screen_height - squish_height)) {
		float distance_into_squish = screen_coords.y - (screen_height - squish_height);
		float factor = 1.0 - clamp(distance_into_squish / squish_height, 0.0, 1.0);
		uvs.x += factor*switching_offset;
		uvs.x += (noise(vec2(uvs.y, TIME)) - 0.5) * 0.005 * switching_noise * (1.0+factor);
		uvs.x += (noise(vec2(uvs.y * 100.0, TIME * 10.0)) - 0.5) * 0.01 * switching_noise* (1.0+factor);
	}


    vec4 sharpenColor = sharpenMask(uvs, SCREEN_PIXEL_SIZE);

	vec4 chromaticColor = cromaticColor(uvs, SCREEN_PIXEL_SIZE);
	
	vec4 cromaticColorRGB = cromaticColorRGB(uvs, SCREEN_PIXEL_SIZE);

	vec4 mixColor = lensflare(uvs);
	
	//COLOR BLEED
	//float strength = color_bleed_seperation;
	//float intensity = color_bleed_intensity;
	//vec4 bloom = vec4(0.0);
	//int amount = color_bleed_quality;
	//for (int i = 0; i < amount; i++){
		//float mul = float(i + 1)/float(amount);
		//float blurShift = float(i*2)/float(amount);
//
		//vec2 UVLeftShift = vec2(SCREEN_UV.x - mul * strength, SCREEN_UV.y);
		//vec2 UVRightShift = vec2(SCREEN_UV.x + mul * strength, SCREEN_UV.y);
		//vec4 leftBleedCol1 = textureLod(SCREEN_TEXTURE, UVLeftShift, color_bleed_blur_strength + blurShift)/float(amount * 2);
		//vec4 rightBleedCol1 = textureLod(SCREEN_TEXTURE, UVRightShift, color_bleed_blur_strength + blurShift)/float(amount * 2);
		//bloom += leftBleedCol1 + rightBleedCol1;
	//}
	//bloom -= texture(SCREEN_TEXTURE, SCREEN_UV) * (anti_bleed_intensity);
	//bloom = clamp(bloom, vec4(0.0), vec4(1.0));
	//mixColor += bloom * intensity;

	vec4 originalColor = texture(SCREEN_TEXTURE, uvs, 0.0);

	mixColor += sharpenColor + BlendMode_Difference(originalColor,chromaticColor); //overlay(chromaticColor, sharpenColor);

	mixColor +=  BlendMode_Difference(originalColor,cromaticColorRGB);

	vec4 vhsMixColor = mixColor;


	//LENS DIRT
    //vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
//
    //// Convert color to brightness using luminance formula
    //float brightness = dot(color.rgb, vec3(0.299, 0.587, 0.114)); // standard luminance weights
//
    //// Set a threshold value (e.g., 0.8 for near-white)
//
    //if (brightness > dust_threshold) {
        //COLOR = color;
    //} else {
        //COLOR = vec4(0.0, 0.0, 0.0, color.a); // black with same alpha
    //}

	vec4 finalColor = vhsMixColor;
	
	COLOR = finalColor;
}

