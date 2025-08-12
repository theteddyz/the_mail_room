extends MeshInstance3D

@export var speed: float = 0.5  # UV units per second

var mat: StandardMaterial3D

func _ready() -> void:
	# Use the per-surface override you showed in the screenshot
	mat = get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		mat = material_override as StandardMaterial3D

	if mat == null:
		push_error("No StandardMaterial3D found on surface 0 or material_override.")
		return

	# Duplicate so we don't mutate a shared resource, and mark as local to scene
	mat = mat.duplicate()
	mat.resource_local_to_scene = true

	# Re-apply the unique copy
	set_surface_override_material(0, mat)

func _process(delta: float) -> void:
	if mat == null:
		return
	var o := mat.uv1_offset
	o.x = wrapf(o.x + speed * delta, 0.0, 1.0)  # scroll & wrap 0..1
	mat.uv1_offset = o
