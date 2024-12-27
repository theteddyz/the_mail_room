extends Node3D

#@export var drawerOpenedSound: AudioStreamPlayer3D
#@export var drawerClosedSound: AudioStreamPlayer3D
#@export var drawerLoopSound: AudioStreamPlayer3D
#@export var drawerSliderJoint: SliderJoint3D
#var drawerMinDistance: float
#var drawerMaxDistance: float
#var tolerance: float = 0.01  # Small tolerance to account for precision issues
#
#var body_a_path # The first body
#var body_b_path  # The second body
#
#var body_a: RigidBody3D
#var body_b: RigidBody3D
#var initial_offset: float
#
#@export var volume: float
#@export var joint_axis_local: Vector3 = Vector3(0, 0, 1)
#
## Called when the node enters the scene tree for the first time.
#
#
#var grabbable_script
#
#var isEnabled = false
#
#var coyoteTime = 0
#
#func _ready() -> void:
	#
	#if drawerSliderJoint == null:
		#for child in get_parent().get_children():
			#if child is SliderJoint3D:
				#drawerSliderJoint = child
	#grabbable_script = get_parent()
	#body_a_path = drawerSliderJoint.node_a 
	#body_b_path = drawerSliderJoint.node_b
	#EventBus.connect("object_held",held_object)
	#EventBus.connect("dropped_object",dropped_object)
	#if body_a_path and body_b_path:
		#body_a = get_node(body_a_path) as RigidBody3D
		#body_b = get_node(body_b_path) as RigidBody3D
	#if drawerSliderJoint:
		#drawerMinDistance = drawerSliderJoint.PARAM_LINEAR_LIMIT_LOWER
		#drawerMaxDistance = drawerSliderJoint.PARAM_LINEAR_LIMIT_UPPER
	## Calculate the initial offset when the scene starts
	#initial_offset = get_relative_position_along_joint_axis()
#
#func held_object(t, j):
	#if j == grabbable_script:
		#set_physics_process(true)
		#isEnabled = true
#
#func dropped_object(t, j):
	#if isEnabled:
		#isEnabled = false
#
#func _physics_process(delta: float) -> void:
	#if !body_b.freeze:
		#if isEnabled:
			#coyoteTime = 2
		#else:
			#coyoteTime -= delta
		#if coyoteTime > 0:
			#if body_b.sleeping:
				#return
			#var velocityMagnitude = abs((body_b.linear_velocity - body_a.linear_velocity).length())#abs(get_velocity_along_axis())
			#var relative_position = get_relative_position_along_joint_axis() - initial_offset
#
			## Normalize the relative position based on the min and max distances
			#relative_position = clamp(relative_position, drawerMinDistance, drawerMaxDistance)
			#
			#if relative_position >= (drawerMaxDistance - tolerance) and velocityMagnitude > 0.5:
				#if !drawerOpenedSound.playing:
					#drawerOpenedSound.volume_db = min(-30 + velocityMagnitude * 2 + volume, volume)
					#drawerOpenedSound.play()
#
			#if relative_position <= (drawerMinDistance + tolerance) and velocityMagnitude > 0.5:
				#if !drawerClosedSound.playing:
					#drawerClosedSound.volume_db = min(-30 + velocityMagnitude * 2 + volume, volume)
					#drawerClosedSound.play()
#
			#if velocityMagnitude > 0.2 and drawerLoopSound:
				#drawerLoopSound.volume_db = min(-20 + velocityMagnitude * 2 + volume, volume)
				#if !drawerLoopSound.playing:
					#drawerLoopSound.play()
			#else:
				#if drawerLoopSound:
					#drawerLoopSound.stop()
	#else:
		#set_physics_process(false)
#
#func get_relative_position_along_joint_axis() -> float:
	## Get the transform of body_a (the reference body)
	#var body_a_transform = body_a.global_transform
#
	## Get the transform of body_b (the moving body)
	#var body_b_transform = body_b.global_transform
#
	## Calculate the vector from body_a to body_b
	#var relative_position_vector = body_b_transform.origin - body_a_transform.origin
#
	## Get the joint axis in the local space of body_a (assuming the joint's local Z-axis)
	##var joint_axis_local = Vector3(0, 0, 1)  # This is usually the local Z-axis of the joint
#
	## Transform the local joint axis to the global space using body_a's basis
	#var joint_axis_global = body_a_transform.basis * joint_axis_local
#
	## Project the relative position vector onto the joint axis to get the scalar position
	#var relative_position = relative_position_vector.dot(joint_axis_global.normalized())
#
	#return relative_position
#
## Function to get the linear velocity along a specific axis
#func get_velocity_along_axis():
	## Normalize the axis to ensure it's a unit vector
	#var joint_axis_global_a = body_a.global_transform.basis * joint_axis_local
	#var normalized_axis_a = joint_axis_global_a
	#var velocity_along_axis_a = body_a.linear_velocity.dot(normalized_axis_a)
	#
	#var joint_axis_global_b = body_b.global_transform.basis * joint_axis_local
	#var normalized_axis_b = joint_axis_global_b
	#var velocity_along_axis_b = body_b.linear_velocity.dot(normalized_axis_b)
	#
	## Project the linear velocity onto the axis
	#return velocity_along_axis_a - velocity_along_axis_b
