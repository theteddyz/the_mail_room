extends MeshInstance3D

@onready var anim = $AnimationPlayer
@onready var audio_player = $AudioStreamPlayer3D
# Called when the node enters the scene tree for the first time.
func _ready():
	anim.play("blinking")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func stop_blinking():
	print("STOPPING")
	await get_tree().create_timer(4).timeout
	audio_player.play()
	anim.stop()


func _on_audio_stream_player_3d_finished():
	EventBus.emitCustomSignal("disable_player_movement",[false,false])
