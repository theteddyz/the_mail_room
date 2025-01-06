@tool 
extends Node3D
@export var active: bool = false
@export var tile_size: Vector2 = Vector2(1, 1):
	set(new_size):
		tile_size = new_size
@onready var mesh: MeshInstance3D = $Plane1

func _process(delta):
	# Ensure the script works in the editor as well as runtime
	if active:
		update_texture_scale()

func update_texture_scale():
	var mesh_scale = transform.basis.get_scale()
	var uv_scale = Vector2(mesh_scale.x / tile_size.x, mesh_scale.z / tile_size.y)
	mesh.mesh.surface_get_material(0).uv1_scale.x = uv_scale.x
	mesh.mesh.surface_get_material(0).uv1_scale.y = uv_scale.y
