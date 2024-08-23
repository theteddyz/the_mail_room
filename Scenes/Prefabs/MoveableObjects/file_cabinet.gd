@tool
extends MeshInstance3D

@export_enum("Grey","Dark Green", "Light Green","Beige","Black") var colour: String = "Grey"
@export_color_no_alpha var color: Color

var color2: Array = [
	preload("res://Assets/Materials/file_cabinet_1.tres"),
]
var material
func _ready():
	material = mesh.surface_get_material(0)
	material.albedo_color = color
	mesh.surface_set_material(0, material)

#func _process(delta):
	#material.albedo_color = color
	#material.surface_set_material(0, material)
