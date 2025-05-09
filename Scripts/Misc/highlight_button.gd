extends MeshInstance3D
@export var active: bool = false
func _ready():
	EventBus.connect("turn_off_elevator_buttons",turn_off_button)
	if active:
		update_glow()
	else:
		turn_off_button()


func turn_off_button():
	var layer_ = [2]
	for layer in layer_:
		var child:Area3D = get_child(0)
		child.set_collision_layer_value(layer, false)
	active = false
	update_glow()

func update_glow():
	var child: Area3D = get_child(0)
	child.set_collision_layer_value(2, active)

	var mat := mesh.surface_get_material(0)
	if mat == null:
		return

	if mat is StandardMaterial3D:
		mat = mat.duplicate()
		mesh.surface_set_material(0, mat)

		if active:
			mat.emission_enabled = true
			mat.emission = Color(1, 1, 1) # White glow
			mat.emission_energy = 2.0
		else:
			mat.emission_enabled = false
			mat.emission = Color(0, 0, 0)
			mat.emission_energy = 0.0


func _process(delta):
	pass
