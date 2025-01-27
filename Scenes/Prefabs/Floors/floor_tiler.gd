@tool 
extends Node3D
@export var active: bool = false
@export var tile_size: Vector2 = Vector2(1, 1)
var internal_tile_size: Vector2

func _ready():
	internal_tile_size = tile_size
	update_texture_scale()

func _process(delta):
	# Ensure the script works in the editor as well as runtime
	if active and Engine.is_editor_hint():
		update_texture_scale()

func update_texture_scale():
	var mesh_scale = transform.basis.get_scale()
	var uv_scale = Vector2(mesh_scale.x / internal_tile_size.x, mesh_scale.z / internal_tile_size.y)
	$Plane1.mesh.surface_get_material(0).uv1_scale.x = uv_scale.x
	$Plane1.mesh.surface_get_material(0).uv1_scale.y = uv_scale.y
