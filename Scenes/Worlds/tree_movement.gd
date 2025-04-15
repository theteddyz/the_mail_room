extends MeshInstance3D

var time: float = 0.0

## The amount of sway the trees should do.
@export_range(0, 2, 0.01) var amount: float = 1.0
## The speed of the swaying motion.
@export_range(0, 2, 0.01) var speed: float = 1.0
## Position Influence affects how much rotational difference the trees should have depending on their position.
## 0 means that they all move at the same time.
@export_range(0, 2, 0.01) var position_influence: float = 1.0
## Speed of the animation.
@export_range(0, 2, 0.01) var animation_speed: float = 1.0
## Controls the exaggeration of the animation keyframes.
## 0 is no animation, 2 will exaggerate the animation movements by double.
@export_range(0, 2, 0.01) var animation_strength: float = 1.0

var animationPlayer: AnimationPlayer

func _ready():
	var animationPlayer:AnimationPlayer = find_child("AnimationPlayer")
	if animationPlayer:
		animationPlayer.speed_scale = animation_speed
		#animationPlayer.set("/X", -x_val*amound)
		var animation: Animation = animationPlayer.get_animation(animationPlayer.current_animation)
		if animation:
			animation.loop_mode = (Animation.LOOP_LINEAR)

	pass
	
	#rotation.y = randf()*360


func _process(delta: float) -> void:
	if animationPlayer:
		animationPlayer.speed_scale = animation_speed
	
	time += delta*speed
	var amound = sin((position.x + position.z)*0.05*position_influence + time)*amount
	
	#rotation.y += 0.2*delta
	
	var yaw = rotation.y
	var x_val = sin(yaw)
	var y_val = cos(yaw)  # or -cos(yaw), depending on handedness

	self.set("blend_shapes/X", -x_val*amound)
	self.set("blend_shapes/Y", y_val*amound)
