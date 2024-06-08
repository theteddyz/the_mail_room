extends RigidBody3D

var sound 

func _ready():
	sound = load("res://Jakob/738864__looplicator__157-bpm-industrial-asmr-loop-677-wav.mp3")


func _on_area_3d_body_entered(body):
	if body.name == "Radio":
		EventBus.emitCustomSignal("dropped_object",[mass,self])
		body.playTape(self)
		hide()


