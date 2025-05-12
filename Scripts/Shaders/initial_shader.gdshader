shader_type canvas_item;
#include "res://Assets/Textures/CLREDIT.gdshaderinc"

//BLUR
group_uniforms gaussian_blur;
uniform float blur_amount : hint_range(0.0, 10.0) = 3.0;
uniform float mix_amount : hint_range(0.0, 1.0);
uniform vec4 color_over : source_color;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_radius = 1;
uniform vec2 blur_direction = vec2(1, 1);

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

//LENS DUST
group_uniforms lens_dust;
uniform float dust_multiplier : hint_range(0, 2.0) = 1.0;
uniform float dust_threshold : hint_range(0, 2.0) = 0.6;
uniform float dust_distance : hint_range(0, 1.0) = 0.05;
uniform float dust_blur : hint_range(0, 10.0) = 5.0;
uniform float dust_falloff : hint_range(0, 0.1) = 0.05;


//VIGNETTE
group_uniforms vignette;
uniform float inner_radius = 0.2;
uniform float outer_radius = 1;
uniform float vignette_strength = 2.0;
uniform float dither_strength = 0.03;
uniform vec4 vignette_color: source_color;
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

	return uv;
}

//VIGNETTE
vec4 vignetteColor(vec2 uv) {
	
    float dist = distance(uv, vec2(0.5));

	float vignette = smoothstep(inner_radius, outer_radius, dist) * vignette_strength;
	
	float dither = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123) * dither_strength;
	
	float finalColor = 1.0 - (vignette + dither);

	return vec4(finalColor,finalColor,finalColor, 1);
}

//void fragment() {
	//vec2 uvs = fisheyeColor(FRAGCOORD, SCREEN_PIXEL_SIZE);
	//
   //vec4 blurred = textureLod(SCREEN_TEXTURE, uvs, blur_amount);
   //blurred.a = 255.0;
   //vec4 fin = mix(blurred, color_over, mix_amount);
//
	//vec4 vinetteColor = vignetteColor(uvs);
//
	//vec4 finalColor = multiply(fin,vinetteColor);
//
   //COLOR = finalColor;
//}


float gaussianDistribution(float x, float STD){ // STD stands for standard deviation
	return exp(-(x*x)/(2.*STD*STD))/(sqrt(2.*PI)*STD);
}

vec3 gaussianblur(sampler2D sampler, vec2 pos, vec2 pixel_size, float sigmaUsed, int radius){
    vec3 blurredPixel = vec3(0.0);
    float total_weight = 0.0;
	// Loop over the radius (tecnically its a square)
    for(int i = -radius ; i <= radius; i++){ 
        for(int j = -radius; j <= radius; j++){
			// Calculate the offset from the current pixel
			vec2 offset = vec2(float(i), float(j))*pixel_size;
			vec2 changedPos = pos + offset;        
			
			// Calculate the weight based on the Gaussian distribution multiplying both dimentions (how far are X and Y form the center (pos))
			float weight = gaussianDistribution(float(i), sigmaUsed)*gaussianDistribution(float(j), sigmaUsed);
			// Add the weighted color value to the blurred pixel
			blurredPixel += texture(SCREEN_TEXTURE, changedPos).rgb * weight;
			total_weight += weight;
        }
    }
	// Normalize the blurred pixel color by the total weight
	blurredPixel/=total_weight;
    return blurredPixel;
}


//  -- EXAMPLE CODE -- //



void fragment(){
	vec2 uvs = fisheyeColor(FRAGCOORD, SCREEN_PIXEL_SIZE);
	vec4 lensFlareColor = lensflare(uvs);
	vec3 xorgaussian = gaussianblur(SCREEN_TEXTURE, uvs, SCREEN_PIXEL_SIZE, blur_amount, int(round(3.0 * blur_amount)));
	vec4 fin = vec4(1.0); 
	fin.rgb = xorgaussian + lensFlareColor.rgb;
	
	vec4 vinetteColor = vignetteColor(SCREEN_UV) ;
	vec4 finalColor = multiply(fin,vinetteColor);

	COLOR = finalColor;
}