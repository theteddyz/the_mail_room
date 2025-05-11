@tool
extends Node3D

@export_enum("Grey", "Dark Green", "Light Green", "Beige", "Black")
var colorPreset: String = "Grey" : set = _on_color_preset_changed

@export_color_no_alpha var color: Color : set = _on_manual_color_changed

@export var main_mesh: MeshInstance3D
@export var cabinet: MeshInstance3D
@export var drawer_1: MeshInstance3D
@export var drawer_2: MeshInstance3D
@export var drawer_3: MeshInstance3D
@export var drawer_4: MeshInstance3D

const COLOR_MAPPING = {
	"Grey": Color("#808080"),
	"Dark Green": Color("#31541e"),
	"Light Green": Color("#f4ffde"),
	"Beige": Color("#fffac4"),
	"Black": Color("#000016")
}

var main_material: StandardMaterial3D
var cabinet_material: StandardMaterial3D
var drawer_materials: Array[StandardMaterial3D] = []

func _ready():
	# Main mesh
	if main_mesh and main_mesh.mesh:
		main_material = main_mesh.mesh.surface_get_material(0)
		if main_material:
			main_material = main_material.duplicate()
			main_material.resource_local_to_scene = true
			main_mesh.mesh.surface_set_material(0, main_material)

	# Cabinet mesh
	if cabinet and cabinet.mesh:
		cabinet_material = cabinet.mesh.surface_get_material(0)
		if cabinet_material:
			cabinet_material = cabinet_material.duplicate()
			cabinet_material.resource_local_to_scene = true
			cabinet.mesh.surface_set_material(0, cabinet_material)

	# Drawers
	for drawer in [drawer_1, drawer_2, drawer_3, drawer_4]:
		if drawer and drawer.mesh:
			var mat = drawer.mesh.surface_get_material(0)
			if mat:
				mat = mat.duplicate()
				mat.resource_local_to_scene = true
				drawer.mesh.surface_set_material(0, mat)
				drawer_materials.append(mat)

	update_colors()

func _process(_delta):
	if Engine.is_editor_hint():
		update_colors()

func _on_color_preset_changed(value):
	colorPreset = value
	update_colors()

func _on_manual_color_changed(value):
	color = value
	update_colors()

func update_colors():
	var final_color: Color = color
	if color == Color(0, 0, 0) and COLOR_MAPPING.has(colorPreset):
		final_color = COLOR_MAPPING[colorPreset]

	if main_material:
		main_material.albedo_color = final_color
	if cabinet_material:
		cabinet_material.albedo_color = final_color
	for mat in drawer_materials:
		mat.albedo_color = final_color
