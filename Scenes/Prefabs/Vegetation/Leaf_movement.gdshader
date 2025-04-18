shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap,depth_prepass_alpha, specular_disabled;
//uniform float sway_strength = 0.05;
//uniform float sway_speed = 2.0;
uniform sampler2D albedo_texture:source_color,filter_nearest;
uniform float sway_strength = 0.05;
uniform float sway_speed = 2.0;
void vertex() {

    float sway = (sin(TIME * 5.0*sway_speed + VERTEX.x + VERTEX.z)) * sway_strength;
    VERTEX.y += sway * (1.0 - UV.y); // Only sway tops
	sway = (sin(TIME * 3.3*sway_speed + VERTEX.y + VERTEX.z)) * sway_strength;
    VERTEX.z += sway * (1.0 - UV.y); // Only sway tops
	sway = (sin(TIME * 4.45*sway_speed + VERTEX.y + VERTEX.z)) * sway_strength;
    VERTEX.x += sway * (1.0 - UV.y); // Only sway tops
}

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV);
    ALBEDO = tex_color.rgb;
    ALPHA = tex_color.a;
}