vec3 ApplyThreshold(vec3 CLR, float Threshold){
	return max(CLR - vec3(Threshold), vec3(0.0));
}

vec3 Saturation(vec3 InputCLR, float Saturation){
	return mix(vec3(dot(InputCLR.rgb, vec3(0.299, 0.587, 0.114))), InputCLR.rgb, Saturation);
}

vec4 add(vec4 color1, vec4 color2) {
    return color1 + color2;
}

vec4 multiply(vec4 color1, vec4 color2) {
    return color1 * color2;
}

vec4 overlay(vec4 base, vec4 blend) {
    vec3 result = mix(2.0 * base.rgb * blend.rgb, 1.0 - 2.0 * (1.0 - base.rgb) * (1.0 - blend.rgb), step(0.5, base.rgb));
    return vec4(result, base.a);
}

vec4 screen(vec4 color1, vec4 color2) {
    vec3 result = 1.0 - (1.0 - color1.rgb) * (1.0 - color2.rgb);
    return vec4(result, color1.a);
}