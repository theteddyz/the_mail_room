extends Interactable
var parent
var original_energy
@export var on:bool = false
@export var light_mesh:MeshInstance3D
func _ready():
	parent = get_parent()
	original_energy = parent.light_energy
	if !on:
		parent.light_energy = 0
		light_mesh.transparency = 1
func interact():
	toggle_light()

func toggle_light():
	if on:
		on = false
		parent.light_energy = 0
		light_mesh.transparency = 1
	else:
		on = true
		parent.light_energy = original_energy
		light_mesh.transparency = 0
