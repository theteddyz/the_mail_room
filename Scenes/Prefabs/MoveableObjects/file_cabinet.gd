@tool
extends MeshInstance3D

@export_enum("Grey","Dark Green", "Light Green","Beige","Black") var colour: String = "Grey"
@export_color_no_alpha var color: Color
@export_enum("Grey", "Dark Green", "Light Green", "Beige", "Black") var cabinet_colour: String = "Grey"
@export_color_no_alpha var cabinet_color: Color
@onready var cabinet_1:MeshInstance3D = $"../../Drawer/FileCabinetDrawer_001"


var main_material: Material
var cabinet_material: Material
func _ready():
	main_material = mesh.surface_get_material(0)
	if main_material:
		main_material = main_material.duplicate()
	else:
		main_material = StandardMaterial3D.new()
	
	main_material.resource_local_to_scene = true
	mesh.surface_set_material(0, main_material)
	cabinet_material = cabinet_1.mesh.surface_get_material(0)
	if cabinet_material:
		cabinet_material = cabinet_material.duplicate()
	else:
		cabinet_material = StandardMaterial3D.new()
	cabinet_material.resource_local_to_scene = true
	cabinet_1.mesh.surface_set_material(0, cabinet_material)
	update_colors()
func _process(delta):
	if Engine.is_editor_hint():
		update_colors()


func update_colors():
	if main_material:
		main_material.albedo_color = color
		mesh.surface_set_material(0, main_material)
	if cabinet_material:
		cabinet_material.albedo_color = cabinet_color
		cabinet_1.mesh.surface_set_material(0, cabinet_material)
