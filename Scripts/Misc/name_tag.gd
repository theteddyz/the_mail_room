@tool
extends Node3D

@export_multiline var name_text:String
var mesh_set = false
func _process(delta):
	if Engine.is_editor_hint() and !mesh_set:
		update_text()

func _ready():
	var text_mesh = $Holder/Tag/MeshInstance3D
	if text_mesh and name_text != text_mesh.mesh.text:
		var unique_text_mesh = text_mesh.mesh.duplicate()
		unique_text_mesh.text = name_text
		text_mesh.mesh = unique_text_mesh
		mesh_set = true

func update_text():
	if Engine.is_editor_hint():
		var text_mesh = $Holder/Tag/MeshInstance3D
		if text_mesh and name_text != text_mesh.mesh.text:
			var unique_text_mesh = text_mesh.mesh.duplicate()
			unique_text_mesh.text = name_text
			text_mesh.mesh = unique_text_mesh
