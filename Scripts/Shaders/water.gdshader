shader_type spatial;
uniform vec4 primary_color:source_color;
uniform vec4 secondary_color:source_color;
uniform float roughness = 0.2;

uniform float normalmap_a_strength : hint_range(0.0,1.0,0.01) = 0.5;
uniform float normalmap_b_strength : hint_range(0.0,1.0,0.01) = 0.25;
uniform vec2 movement_direction = vec2(0.2,0.1);
uniform float movement_strength = 0.12;
uniform float uv_scale = 1.0;
// Depth Value
uniform float depth_distance:hint_range(0.0,20.0,0.1) = 4.0;
//How clear to dirty the water is
uniform float beers_law : hint_range (0.0,20.0,0.1) = 12.0;
uniform float water_transparency : hint_range(0.0,1.0,0.01) = 0;
uniform float refraction_strength: hint_range(0.0,8.0,0.001) = 5.0;
uniform sampler2D normalmap_a : hint_normal;
uniform sampler2D normalmap_b :hint_normal;
uniform sampler2D screen_texture: hint_screen_texture,repeat_disable,filter_nearest;
uniform sampler2D depth_texture: hint_depth_texture,repeat_disable,filter_nearest;
void vertex() {
	
	// Called for every vertex the material is visible on.
}

float fresnel(float amount , vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal),normalize(view)), 0.1, 1.0)),amount);
}

void fragment() {
	vec2 uv_movement = movement_direction * TIME * movement_strength;
	vec2 uv = UV * uv_scale;
	vec3 normalmap = texture(normalmap_a,uv + uv_movement).rgb * normalmap_a_strength;
	normalmap += texture(normalmap_b,uv - uv_movement).rgb * normalmap_b_strength;
	vec3 ref_normal_map = normalmap * 2.0 - (normalmap_a_strength + normalmap_b_strength);
	vec3 ref_normal = mix(NORMAL,TANGENT * ref_normal_map + BINORMAL * ref_normal_map + NORMAL * ref_normal_map, 1.0);
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction_strength;
	float depth_clean = textureLod(depth_texture,SCREEN_UV,0.0).r;
	float depth = textureLod(depth_texture, ref_ofs, 0.0).r;
	vec3 screen = textureLod(screen_texture, ref_ofs, 0.0).rgb;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec3 ndc_clean = vec3(SCREEN_UV * 2.0 -1.0,depth_clean);
	vec4 view = INV_VIEW_MATRIX * vec4(ndc,1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z + VERTEX.z;
	vec4 world;
	if(linear_depth < 0.00001){
		world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc_clean,1.0);
	}else{
		world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc,1.0);
	}
	float depth_texture_y = world.y / world.w;
	float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX,1.0)).y;
	float depth_blend = clamp((vertex_y - depth_texture_y)/ depth_distance,0.0,1.0);
	depth_blend = exp(-depth_blend * beers_law);
	float basic_fresnel = fresnel(3.0,NORMAL,VIEW);
	
	
	vec3 depth_color = mix(secondary_color,primary_color,depth_blend).rgb;
	vec3 refraction_texture = textureLod(screen_texture,ref_ofs,ROUGHNESS * 2.0).rgb;
	vec3 final_color = mix(depth_color,refraction_texture,water_transparency * depth_blend);
	ALBEDO = final_color;
	ROUGHNESS = roughness  * (1.0 - basic_fresnel);
	NORMAL_MAP = normalmap;
}



//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
