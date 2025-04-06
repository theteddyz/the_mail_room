extends MeshInstance3D
var material:ShaderMaterial
var noise:Image
var noise_scale:float
var wave_speed:float
var heigh_scale:float



func _ready():
	material = mesh.surface_get_material(0)
	noise = material.get_shader_parameter("wave").noise.get_seamless_image(512,512)
	#noise_scale = material.
