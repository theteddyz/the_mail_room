@tool
extends MeshInstance3D

@export_enum("Grey", "Dark Green", "Light Green", "Beige", "Black")
var colorPreset: String = "Grey"

# Define a mapping from string values to integer enums
const COLOR_MAPPING = {
	"Grey": 1,
	"Dark Green": 2,
	"Light Green": 3,
	"Beige": 4,
	"Black": 5
}

var colorPrefabs: String
@export_color_no_alpha var color: Color
@onready var cabinet_1:MeshInstance3D = $"../Drawer/FileCabinetDrawer_001"


var main_material: Material
var cabinet_material: Material
func _ready():
	if cabinet_1:
		main_material = mesh.surface_get_material(0)
		if main_material:
			main_material = main_material.duplicate()
		else:
			main_material = StandardMaterial3D.new()
		
		main_material.resource_local_to_scene = true
		mesh.surface_set_material(0, main_material)
		cabinet_material = cabinet_1.mesh.surface_get_material(0)
		cabinet_material.resource_local_to_scene = true
		cabinet_1.mesh.surface_set_material(0, cabinet_material)
		update_colors()
func _process(delta):
	if Engine.is_editor_hint():
		update_colors()


func update_colors():
	
	# Debugging output to check what colorPrefab holds

	# Check if the colorPrefab is valid and mapped correctly
	if COLOR_MAPPING.has(colorPreset):
		var color_int = COLOR_MAPPING[colorPreset]
		# Use the integer value in a match statement
		match color_int:
			1:
				colorPrefabs = "#808080"  # Grey
			2:
				colorPrefabs = "#31541e"  # Dark Green
			3:
				colorPrefabs = "#f4ffde"  # Light Green
			4:
				colorPrefabs = "#fffac4"  # Beige
			5:
				colorPrefabs = "#000016"  # Black
			_:
				colorPrefabs = "Unknown color"

	var finalColor = null
	if color != Color(0,0,0):
		finalColor = color
	else:
		finalColor = colorPrefabs
	
	if main_material:
		main_material.albedo_color = finalColor
		mesh.surface_set_material(0, main_material)
	if cabinet_material:
		cabinet_material.albedo_color = finalColor
		cabinet_1.mesh.surface_set_material(0, cabinet_material)
