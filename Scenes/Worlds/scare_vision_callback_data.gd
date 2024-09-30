extends Node

@export var scare_vision_callback = _wait_for_seen
@export var scare_vision_callback_delay = 0
signal callback_done


func _ready():
	pass
	#ScareDirector.connect("monster_seen", _wait_for_seen)
	
func _wait_for_seen():
	pass

# External callback function that could have some delay or complex operations
func scare_vision_external_callback() -> void:
	print("External callback started...")
	# Simulate a delay or complex task (in a real case, this could be an async operation)
	await ScareDirector.monster_seen
	print("External callback completed!")
	emit_signal("callback_done")
