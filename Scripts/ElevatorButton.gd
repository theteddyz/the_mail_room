extends Interactable
@export var target_scene_path := ""
@export var floor_num:int
@onready var anim:AnimationPlayer = $"../../../../AnimationPlayer"

func interact():
	anim.play("door_close_inside")
	await anim.animation_finished
	print("GOING TO NEW SCENE ",target_scene_path)
	EventBus.emitCustomSignal("moved_to_floor", [target_scene_path,floor_num])
