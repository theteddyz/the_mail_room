extends Node3D

# Used for checking if the mouse is inside the Area3D.
var is_mouse_inside = false
# The last processed input touch/mouse event. To calculate relative movement.
var last_event_pos2D = null
# The time of the last event in seconds since engine start.
var last_event_time: float = -1.0
var scale_factor = 0.5
@onready var node_viewport =$SubViewport
@onready var node_quad = $"../Screen"
@onready var node_area = $"../Screen/Area3D"
@onready var mouse_cursor = $SubViewport/GUI/MouseCursor
var space_state = null
func _ready():
	pass
	#node_area.mouse_entered.connect(_mouse_entered_area)
	#node_area.mouse_exited.connect(_mouse_exited_area)
	#node_area.input_event.connect(_mouse_input_event)

func _physics_process(delta: float):
	space_state = get_world_3d().direct_space_state

func _input(event):
	# Only care about mouse input


	if is_mouse_inside:
		if not is_inside_tree():
			return  # Avoid querying world before node is in the scene
		if event is InputEventKey:
			node_viewport.push_input(event)
		elif event is InputEventMouseMotion or event is InputEventMouseButton: 
			var camera := get_viewport().get_camera_3d()
			if camera == null:
				return
			# Raycast from camera into the scene
			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * 1000
			var query = PhysicsRayQueryParameters3D.create(from, to)
			query.collision_mask = 1 << 24
			query.exclude = []
			query.hit_from_inside = true
			query.collide_with_bodies = false
			query.collide_with_areas = true
			var result = space_state.intersect_ray(query)
			if result and result.collider == node_area:
				#is_mouse_inside = true
				_mouse_input_event(camera, event, result.position, result.normal, result.shape)
			else:
				pass
				#is_mouse_inside = false



func _mouse_input_event(_camera: Camera3D, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int):
	# Get mesh size to detect edges and make conversions. This code only support PlaneMesh and QuadMesh.
	var quad_mesh_size = node_quad.mesh.size
	# Event position in Area3D in world coordinate space.
	var event_pos3D = event_position
	# Current time in seconds since engine start.
	var now: float = Time.get_ticks_msec() / 1000.0
	# Convert position to a coordinate space relative to the Area3D node.
	# NOTE: affine_inverse accounts for the Area3D node's scale, rotation, and position in the scene!
	event_pos3D = node_quad.global_transform.affine_inverse() * event_pos3D

	# TODO: Adapt to bilboard mode or avoid completely.

	var event_pos2D: Vector2 = Vector2()

	if is_mouse_inside:
		# Convert the relative event position from 3D to 2D.
		event_pos2D = Vector2(event_pos3D.x, -event_pos3D.y)
		mouse_cursor.position = event_pos2D
		# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
		# We need to convert it into the following range: -0.5 -> 0.5
		event_pos2D.x = event_pos2D.x / quad_mesh_size.x
		event_pos2D.y = (event_pos2D.y / quad_mesh_size.y)
		# Then we need to convert it into the following range: 0 -> 1
		event_pos2D.x += 0.5
		event_pos2D.y += 0.5
		
		# Finally, we convert the position to the following range: 0 -> viewport.size
		event_pos2D.x *= node_viewport.size.x
		event_pos2D.y *= node_viewport.size.y
		mouse_cursor.set_position(event_pos2D)
		# We need to do these conversions so the event's position is in the viewport's coordinate system.

	elif last_event_pos2D != null:
		# Fall back to the last known event position.
		event_pos2D = last_event_pos2D

	# Set the event's position and global position.
	event.position = event_pos2D
	if event is InputEventMouse:
		event.global_position = event_pos2D

	# Calculate the relative event distance.
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		# If there is not a stored previous position, then we'll assume there is no relative motion.
		if last_event_pos2D == null:
			event.relative = Vector2(0, 0)
		# If there is a stored previous position, then we'll calculate the relative position by subtracting
		# the previous position from the new position. This will give us the distance the event traveled from prev_pos.
		else:
			event.relative = event_pos2D - last_event_pos2D
			event.velocity = event.relative / (now - last_event_time)

	# Update last_event_pos2D with the position we just calculated.
	last_event_pos2D = event_pos2D

	# Update last_event_time to current time.
	last_event_time = now

	# Finally, send the processed input event to the viewport.
	node_viewport.push_input(event)


func _on_button_pressed():
	print("Pressed")


func _on_button_mouse_entered():
	print("BUTTON Entered")
