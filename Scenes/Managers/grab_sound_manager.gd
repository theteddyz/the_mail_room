extends Node
@export var open_sound: AudioStreamPlayer3D
@export var close_sound: AudioStreamPlayer3D
@export var loop_sound: AudioStreamPlayer3D
var min_distance: float
var max_distance: float
var tolerance: float = 0.01  # Small tolerance to account for precision issues

#var body_a_path # The first body
#var body_b_path  # The second body

var body_a: RigidBody3D
var body_b
var initial_offset: float

@export var volume: float
@export var joint_axis_local: Vector3 = Vector3(0, 0, 1)

# Called when the node enters the scene tree for the first time.


var grabbable_script
var joint: SliderJoint3D
var hingeJoint: HingeJoint3D
var isEnabled = false

var coyoteTime = 0
func _ready() -> void:
	pass

func enable_sound(main_body:RigidBody3D):
	body_a = main_body
	body_b = body_a.get_parent()
	open_sound = main_body.open_sound
	close_sound = main_body.close_sound
	loop_sound = main_body.loop_sound
	if body_a.grab_type == 2:
		for child in body_a.get_children():
			if child is SliderJoint3D:
				joint = child
				min_distance = joint.PARAM_LINEAR_LIMIT_UPPER
				max_distance = joint.PARAM_LINEAR_LIMIT_LOWER*0.5
	elif body_a.grab_type == 1:
		for child in body_a.get_children():
			if child is HingeJoint3D:
				hingeJoint = child
				min_distance = hingeJoint.PARAM_LIMIT_UPPER
				max_distance = hingeJoint.PARAM_LIMIT_LOWER
	if joint == null:
		push_warning("JOINT DOES NOT EXIST. SETTING TO 0.")
		initial_offset = 0
	elif joint.get_script() == null:
		push_warning("JOINT DOES NOT HAVE A SCRIPT. SETTING TO 0.")
		initial_offset = 0
	elif "initial_offset" in joint:
		initial_offset = joint.initial_offset
	else:
		push_warning("JOINT'S SCRIPT DOES NOT DEFINE 'initial_offset'. SETTING TO 0.")
		initial_offset = 0
	isEnabled = true


func _physics_process(delta: float) -> void:
	if body_a:
		if body_a.grab_type == 2:
			_drawer_sound(delta)
		else:
			_door_sound(delta)

func _drawer_sound(delta):
	if isEnabled:
		coyoteTime = 2
	else:
		coyoteTime -= delta
	if coyoteTime > 0:
		#if body_b.sleeping:
		#	return
		var body_a_velocity = Vector3.ZERO
		if body_a is RigidBody3D:
			body_a_velocity = body_a.linear_velocity
		var body_b_velocity = Vector3.ZERO
		if body_b is RigidBody3D:
			body_b_velocity = body_b.linear_velocity
		var velocityMagnitude = abs((body_b_velocity- body_a_velocity).length())#abs(get_velocity_along_axis())
		var relative_position = get_relative_position_along_joint_axis() - initial_offset

		relative_position = -relative_position
		# Normalize the relative position based on the min and max distances
		#relative_position = clamp(relative_position, min_distance, max_distance)
		
		if open_sound == null or close_sound == null or loop_sound == null:
			return
		
		if relative_position >= (max_distance - tolerance) and velocityMagnitude > 0.5:
			if !open_sound.playing:
				open_sound.volume_db = min(-30 + velocityMagnitude * 2 + volume, volume)
				open_sound.play()

		if relative_position <= (min_distance + tolerance) and velocityMagnitude > 0.5:
			if !close_sound.playing:
				close_sound.volume_db = min(-30 + velocityMagnitude * 2 + volume, volume)
				close_sound.play()

		if velocityMagnitude > 0.2 and loop_sound:
			loop_sound.volume_db = min(-20 + velocityMagnitude * 2 + volume, volume)
			if !loop_sound.playing:
				loop_sound.play()
		else:
			if loop_sound:
				loop_sound.stop()

func _door_sound(delta):
	return
	if isEnabled:
		coyoteTime = 2
	else:
		coyoteTime -= delta
	if coyoteTime > 0:
		var velocityMagnitude = abs((body_a.angular_velocity).length())#abs(get_velocity_along_axis())
		var relative_position = get_relative_position_along_joint_axis() - initial_offset

		# Normalize the relative position based on the min and max distances
		relative_position = clamp(relative_position, min_distance, max_distance)
		if relative_position >= (max_distance - tolerance) and velocityMagnitude > 0.5:
			if !open_sound.playing:
				open_sound.volume_db = min(-30 + velocityMagnitude * 2 + volume, volume)
				open_sound.play()

		if relative_position <= (min_distance + tolerance) and velocityMagnitude > 0.5:
			if !close_sound.playing:
				close_sound.volume_db = min(-30 + velocityMagnitude * 2 + volume, volume)
				close_sound.play()

		if velocityMagnitude > 0.2 and loop_sound:
			loop_sound.volume_db = min(-20 + velocityMagnitude * 2 + volume, volume)
			if !loop_sound.playing:
				loop_sound.play()
		else:
			if loop_sound:
				loop_sound.stop()

func get_relative_position_along_joint_axis() -> float:
	# Get the transform of body_a (the reference body)
	var body_a_transform = body_a.global_transform

	# Get the transform of body_b (the moving body)
	var body_b_transform = body_b.global_transform

	# Calculate the vector from body_a to body_b
	var relative_position_vector = body_b_transform.origin - body_a_transform.origin

	# Get the joint axis in the local space of body_a (assuming the joint's local Z-axis)
	#var joint_axis_local = Vector3(0, 0, 1)  # This is usually the local Z-axis of the joint

	# Transform the local joint axis to the global space using body_a's basis
	var joint_axis_global = body_a_transform.basis * joint_axis_local

	# Project the relative position vector onto the joint axis to get the scalar position
	var relative_position = relative_position_vector.dot(joint_axis_global.normalized())

	return relative_position
