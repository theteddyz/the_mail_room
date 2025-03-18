extends SliderJoint3D
var initial_offset: float
@export var joint_axis_local: Vector3 = Vector3(0, 0, 1)

func _ready() -> void:
	initial_offset = get_relative_position_along_joint_axis();

func get_relative_position_along_joint_axis() -> float:
	# Get the transform of body_a (the reference body)
	
	var body_a_transform = get_node(node_b).global_transform

	# Get the transform of body_b (the moving body)
	var body_b_transform = get_node(node_a).global_transform

	# Calculate the vector from body_a to body_b
	var relative_position_vector = body_b_transform.origin - body_a_transform.origin

	# Get the joint axis in the local space of body_a (assuming the joint's local Z-axis)
	#var joint_axis_local = Vector3(0, 0, 1)  # This is usually the local Z-axis of the joint

	# Transform the local joint axis to the global space using body_a's basis
	var joint_axis_global = body_a_transform.basis * joint_axis_local

	# Project the relative position vector onto the joint axis to get the scalar position
	var relative_position = relative_position_vector.dot(joint_axis_global.normalized())

	return relative_position
