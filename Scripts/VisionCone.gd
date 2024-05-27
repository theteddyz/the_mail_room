extends MeshInstance3D
var vision_range: float = 10.0
var vision_angle: float = 45.0 # Angle in degrees
# Called when the node enters the scene tree for the first time.
var patrol_material: StandardMaterial3D
var chase_material: StandardMaterial3D
func _ready():
	patrol_material = load("res://Scenes/Monsters/patrol_material.tres")
	chase_material = load("res://Scenes/Monsters/chase_materiel.tres")
	update_cone(patrol_material)


func update_cone(material: StandardMaterial3D):
	var cone_mesh = generate_cone_mesh(vision_range, deg_to_rad(vision_angle), 32)
	mesh = cone_mesh
	mesh.surface_set_material(0, material)


func generate_cone_mesh(radius: float, angle: float, segments: int) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = []
	var indices = []
	vertices.append(Vector3.ZERO)
	for i in range(segments + 1):
		var theta = angle * i / segments - angle / 2
		var x = radius * cos(theta)
		var z = radius * sin(theta)
		vertices.append(Vector3(x, 0, -z))
	for i in range(1, segments):
		indices.append(0)
		indices.append(i)
		indices.append(i + 1)
	indices.append(0)
	indices.append(segments)
	indices.append(1)
	var array = []
	array.resize(Mesh.ARRAY_MAX)
	array[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	array[Mesh.ARRAY_INDEX] = PackedInt32Array(indices)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
	return mesh
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
