extends Node3D

var time: float = 0.0

## The amount of sway the trees should do.
@export var amount: float = 1.0
## The speed of the swaying motion.
@export var speed: float = 1.0
## Position Influence affects how much rotational difference the trees should have depending on their position.
## 0 means that they all move at the same time.
@export var position_influence: float = 1.0
## Speed of the animation.
@export var animation_speed: float = 1.0
## Controls the exaggeration of the animation keyframes.
## 0 is no animation, 2 will exaggerate the animation movements by double.
@export var animation_strength: float = 1.0

var amount2: float = 1.0
var speed2: float = 1.0
var position_influence2: float = 1.0
var animation_speed2: float = 1.0
var animation_strength2: float = 1.0

var visibility_range_1: int = 100
var visibility_range_2: int = 200

var vegetationController: Node3D
var vegetationScript = "res://Scenes/Worlds/vegetation_controller.gd"

var animationPlayer: AnimationPlayer
var animationTree: AnimationTree

@export var trunk: MeshInstance3D
@export var leaves: MeshInstance3D
@export var low_quality_trunk: MeshInstance3D
@export var low_quality_leaves: MeshInstance3D
@export var super_low_quality: MeshInstance3D



func _ready():
	var root = get_tree().root
	var specific_script = load(vegetationScript)
	find_node_with_script(root, specific_script)
	
	amount2 = amount * vegetationController.amount
	speed2 = speed * vegetationController.speed
	position_influence2 = position_influence * vegetationController.position_influence
	animation_speed2 = animation_speed * vegetationController.animation_speed
	animation_strength2 = animation_strength * vegetationController.animation_strength
	
	
	if leaves:
		animationPlayer = leaves.find_child("AnimationPlayer")
		animationTree = leaves.find_child("AnimationTree")
	
	if animationPlayer:
		var animation: Animation = animationPlayer.get_animation(animationPlayer.current_animation)
		if animation:
			animation.loop_mode = (Animation.LOOP_LINEAR)

	if trunk:
		trunk.visibility_range_begin = 0
		trunk.visibility_range_end = visibility_range_1+5
	if leaves:
		leaves.visibility_range_begin = 0
		leaves.visibility_range_end = visibility_range_1+5
	if low_quality_trunk:
		low_quality_trunk.visibility_range_begin = visibility_range_1
		low_quality_trunk.visibility_range_end = visibility_range_2+5
	if low_quality_leaves:
		low_quality_leaves.visibility_range_begin = visibility_range_1
		low_quality_leaves.visibility_range_end = visibility_range_2+5
	if super_low_quality:
		super_low_quality.visibility_range_begin = visibility_range_2

	
	#low_quality_trunk.visibility_parent = super_low_quality.get_path()
	#trunk.visibility_parent = low_quality_trunk.get_path()
	
	#rotation.y = randf()*360


func _process(delta: float) -> void:
	
	
	
	#Remove when releasing the game
	amount2 = amount * vegetationController.amount
	speed2 = speed * vegetationController.speed
	position_influence2 = position_influence * vegetationController.position_influence
	animation_speed2 = animation_speed * vegetationController.animation_speed
	animation_strength2 = animation_strength * vegetationController.animation_strength
	
	if animationTree:
		animationTree["parameters/Blend/blend_amount"] = animation_strength2
		animationTree["parameters/TimeScale/scale"] = animation_speed2
		
	time += delta*speed2
	var amound = sin((global_position.x + global_position.z)*0.05*position_influence2 + time)*amount2
	
	
	
	var yaw = rotation.y
	var x_val = sin(yaw)
	var y_val = cos(yaw)  # or -cos(yaw), depending on handedness

	if trunk:
		trunk.set("blend_shapes/X", -x_val*amound)
		trunk.set("blend_shapes/Y", y_val*amound)
	if leaves: 
		leaves.set("blend_shapes/X", -x_val*amound)
		leaves.set("blend_shapes/Y", y_val*amound)
		
	#yaw = global_rotation.y
	#x_val = sin(yaw)
	#y_val = cos(yaw)
	#if low_quality_trunk:
		#low_quality_trunk.global_rotation.x = x_val*amound*0.2
		#low_quality_trunk.global_rotation.z =  -y_val*amound*0.2
	#if low_quality_leaves:
		#low_quality_leaves.global_rotation.x = x_val*amound*0.2
		#low_quality_leaves.global_rotation.z =  -y_val*amound*0.2

func find_node_with_script(node, script):
	# Check if the current node has the specific script
	if (node.get_script() == script):#!= package_script:#node.get_script() == script:
		vegetationController = node

	# Recurse into children
	for child in node.get_children():
		find_node_with_script(child, script)
