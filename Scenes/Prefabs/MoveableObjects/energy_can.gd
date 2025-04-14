@tool
extends MeshInstance3D

@export_enum("Global Energy", "Corp Cola Cherry", "Apple Vinegar", "Life", "Bebsi")
var texturePreset: String = "Global Energy"
var current_texturePreset = null
# Define a mapping from string values to integer enums
const TEXTURE_MAPPING = {
	"Global Energy": "res://Assets/Textures/BlenderTextures/EnergyCan.png",
	"Corp Cola Cherry": "res://Assets/Textures/BlenderTextures/EnergyCan2.png",
	"Apple Vinegar": "res://Assets/Textures/BlenderTextures/EnergyCan3.png",
	"Life": "res://Assets/Textures/BlenderTextures/EnergyCan4.png",
	"Bebsi": "res://Assets/Textures/BlenderTextures/EnergyCan5.png"
}

@onready var cabinet_1:MeshInstance3D = $"."

var main_material: Material

func _ready():
	#if cabinet_1:
	main_material = mesh.surface_get_material(0)
	if main_material:
		main_material = main_material.duplicate()
	else:
		main_material = StandardMaterial3D.new()
		
	main_material.resource_local_to_scene = true
	mesh.surface_set_material(0, main_material)

	update_textures()

func _process(delta):
	if Engine.is_editor_hint():
		update_textures()

func update_textures():
	if(current_texturePreset != texturePreset):
		current_texturePreset = texturePreset
		if TEXTURE_MAPPING.has(texturePreset):
			var texture_path = TEXTURE_MAPPING[texturePreset]
			var tex = load(texture_path)

			if tex:
				if main_material:
					print("Updated Texture")
					main_material.albedo_texture = tex
					main_material.set("albedo_texture",tex)
					#mesh.set_texture(tex)
