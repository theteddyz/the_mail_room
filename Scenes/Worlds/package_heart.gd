extends Node3D

@export var package1: MeshInstance3D
@export var animationPlayer1: AnimationPlayer
@export var package2: MeshInstance3D
@export var animationPlayer2: AnimationPlayer
@export var string1: MeshInstance3D
@export var animationPlayer3: AnimationPlayer
@export var string2: MeshInstance3D
@export var animationPlayer4: AnimationPlayer
@export var heart1: MeshInstance3D
@export var animationPlayer5: AnimationPlayer
@export var heart2: MeshInstance3D
@export var animationPlayer6: AnimationPlayer

@export var package: Node3D
var package_script_path = "res://Scripts/MailCart/Package.gd"
var package_script: Script = load(package_script_path)

var blood: float = 0
var initial_blood: float = 0.3
var hasTransitioned = false

func _ready():
	if (package != null): 
		if (package.get_script() == package_script):
			print("it works")
	if animationPlayer1:
		animationPlayer1.stop()
	if animationPlayer2:
		animationPlayer2.stop()
	if animationPlayer3:
		animationPlayer3.stop()
	if animationPlayer4:
		animationPlayer4.stop()
	#if animationPlayer5:
		#animationPlayer5.stop()
	#if animationPlayer6:
		#animationPlayer6.stop()
	if animationPlayer5:
		var animation: Animation = animationPlayer5.get_animation(animationPlayer5.current_animation)
		if animation:
			animation.loop_mode = (Animation.LOOP_LINEAR)
	if animationPlayer6:
		var animation: Animation = animationPlayer6.get_animation(animationPlayer6.current_animation)
		if animation:
			animation.loop_mode = (Animation.LOOP_LINEAR)
	package1.get_surface_override_material(0).set_shader_parameter("blood",initial_blood);
	
func _process(delta: float) -> void:
	if package != null:
		if package.is_picked_up and !hasTransitioned:
			hasTransitioned = true
			if animationPlayer1:
				animationPlayer1.play()
			if animationPlayer2:
				animationPlayer2.play()
			if animationPlayer3:
				animationPlayer3.play()
			if animationPlayer4:
				animationPlayer4.play()
			if animationPlayer5:
				animationPlayer5.play()
			if animationPlayer6:
				animationPlayer6.play()
			
	if hasTransitioned == true:
		blood += delta
		if package1:
			package1.get_surface_override_material(0).set_shader_parameter("blood",initial_blood + blood*0.13);
		if blood > 3.5:
			package1.visible = false
			package2.visible = false
			string1.visible = false
			string2.visible = false

#func find_node_with_script(node, script):
	## Check if the current node has the specific script
	#if (node.get_script() == script):#!= package_script:#node.get_script() == script:
		#vegetationController = node
#
	## Recurse into children
	#for child in node.get_children():
		#find_node_with_script(child, script)
