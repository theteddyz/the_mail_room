extends Node3D
@export var light: PackedScene
var directionalLight: DirectionalLight3D
const RAY_LENGTH: float = 100
var boolean: bool = true
var lights = []
func _ready():

	var root = get_tree().root
	find_directional_light(root)

func _physics_process(delta: float) -> void:
	for light in lights:
		light.queue_free()
		
	lights.clear()
	if true:#boolean == true:
		boolean = false
		var space_state = get_world_3d().direct_space_state
		if directionalLight == null:
			push_error("No DirectionalLight3D found in the scene!")
			return
		if space_state == null:
			push_error("No space_state!")
			return
			
			
		# Use the directional basis (right, up, forward)
		var right = directionalLight.global_transform.basis.x
		var up = directionalLight.global_transform.basis.y
		var forward = -directionalLight.global_transform.basis.z  # Negative z is forward
		
		for n in range(-3, 3):  # from -4 to 3 (8 steps)
			for s in range(-3, 3):
				var base_origin = directionalLight.global_position

				# Add offset sideways (right) and vertically (up)
				var offset = (right * n * 2.0) + (up * s * 2.0)  # *2.0 controls the spacing between rays
				var origin = base_origin + offset

				var end = origin + forward * RAY_LENGTH
				var query = PhysicsRayQueryParameters3D.create(origin, end)

				var result = space_state.intersect_ray(query)
				if(result.has("collider")):
					var light = light.instantiate() as Node3D
					add_child(light)
					light.global_position = result.position
					lights.push_back(light)
	
func find_directional_light(node: Node):
	if node is DirectionalLight3D:
		directionalLight = node

	for child in node.get_children():
		find_directional_light(child)
