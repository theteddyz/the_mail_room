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

//VIGNETTE
group_uniforms vignette;
uniform float inner_radius = 0.2;
uniform float outer_radius = 1;
uniform float vignette_strength = 2.0;
uniform float dither_strength = 0.03;
uniform vec4 vignette_color: source_color;

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
	vec3 xorgaussian = gaussianblur(SCREEN_TEXTURE, uvs, SCREEN_PIXEL_SIZE, blur_amount, int(round(3.0 * blur_amount)));
	vec4 fin = vec4(1.0); 
	fin.rgb = xorgaussian;
	vec4 vinetteColor = vignetteColor(SCREEN_UV);
	vec4 finalColor = multiply(fin,vinetteColor);

	COLOR = finalColor;
}