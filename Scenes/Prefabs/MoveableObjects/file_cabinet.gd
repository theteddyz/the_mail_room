@tool
extends MeshInstance3D

@export_enum("Grey","Dark Green", "Light Green","Beige","Black") var colour: String = "Grey"
@export_color_no_alpha var color: Color
@onready var cabinet_1:MeshInstance3D = $"../../Drawer/FileCabinetDrawer_001"


var material
var material_2
func _ready():
	material = mesh.surface_get_material(0)
	material_2 = cabinet_1.mesh.surface_get_material(0)
	material.albedo_color = color
	material_2.albedo_color = color
	cabinet_1.mesh.surface_set_material(0, material_2)
	mesh.surface_set_material(0, material)
func _process(delta):
	if Engine.is_editor_hint():
		#material.albedo_color = color
		#material.surface_set_material(0, material)
		material.albedo_color = color
		material_2.albedo_color = color
		mesh.surface_set_material(0,material)
		cabinet_1.mesh.surface_set_material(0,material_2)
