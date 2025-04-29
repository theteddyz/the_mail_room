@tool
extends DirectionalLight3D
@export var enable: bool = true
@export var update: bool = true
@export var light: PackedScene
@export var light_intensity: float = 1
@export var light_attenuation: float = 1
@export var light_distance: float = 1
#var directionalLight: DirectionalLight3D
const RAY_LENGTH: float = 1000
var lights: = []
var space_state
var previousRotation: Vector3
var current_light := 0
const LIGHTS_PER_FRAME := 20
@export var width = 10
@export var height = 10
var lastWidth = 0
var lastHeight = 0
@export var spacingWidth = 1.0
@export var spacingHeight = 1.0
var lastEnable = true

func _ready():
	create_lights()
	var root = get_tree().root
	
func create_lights():
	for n in range(-width, width):  # from -4 to 3 (8 steps)
		for s in range(-height, height):
			var light = light.instantiate() as Node3D
			add_child(light)
			var actualLight = light.get_child(0) as OmniLight3D
			lights.push_back(actualLight)

func _process(delta: float) -> void:
	if width != lastWidth or height != lastHeight or (lastEnable != enable):
		for light in lights:
			light.queue_free()
		lights.clear()
		if (!lastEnable and enable) or ((width != lastWidth or height != lastHeight) and enable):
			create_lights()
	
	if enable and update:#directionalLight.rotation != previousRotation:
		if space_state:
				
				
			# Use the directional basis (right, up, forward)
			var right = global_transform.basis.x
			var up = global_transform.basis.y
			var forward = -global_transform.basis.z  # Negative z is forward

			
			for i in LIGHTS_PER_FRAME:  # from -4 to 3 (8 steps)
				if current_light >= lights.size():
					current_light = 0  # Start over

				var light = lights[current_light]

				# Calculate grid position
				var row = current_light / (width+height)  # integer division
				var column = current_light % (width+height)

				var n = row - width
				var s = column - height
				
				
				
				
				var base_origin = global_position

				# Add offset sideways (right) and vertically (up)
				var offset = (right * n * spacingHeight) + (up * s * spacingWidth)  # *2.0 controls the spacing between rays
				var origin = base_origin + offset

				var end = origin + forward * RAY_LENGTH
				var query = PhysicsRayQueryParameters3D.create(origin, end)

				var result = space_state.intersect_ray(query)
				if result.has("collider"):
					var collider = result["collider"] as Node3D
					if collider != null:
						if (collider.collision_layer & (1 << 22)) == 0:
							# Only enter here if NOT on layer 2
							var direction = forward 
							var offset_position = result.position - direction.normalized() * light_distance 
							
							light.global_position = offset_position
							light.light_color = light_color
							light.omni_attenuation = light_attenuation
							light.light_energy = light_intensity
							light.visible = true
						else:
							light.visible = false
					else:
						light.visible = false
				else:
					light.visible = false
				current_light += 1

		else:
			print("SPACE STATE: ", space_state)
	previousRotation = rotation
	lastWidth = width
	lastHeight = height
	lastEnable = enable
func _physics_process(delta: float) -> void:
	space_state = get_world_3d().direct_space_state

	
#func find_directional_light(node: Node):
	#if node is DirectionalLight3D:
		#directionalLight = node
#
	#for child in node.get_children():
		#find_directional_light(child)
