extends Node
##Signals##
#Signals when an game object is held by player and feeds mass
signal object_held(mass: float, object: Node3D)
#Signals when we drop an object
signal dropped_object(mass:float,object:Node3D)
#Signal for telling the pause menu we are reading something
signal player_reading(is_reading:bool)
#Signal for trigger Scares for the ScareDirector to keep track of
signal scare_event(event_type:String,pos:Vector3)
#Signal for when we want to disable to player movement
signal disable_player_movement(l:bool,w:bool)
#Signal for giving the floor to the game manager when in the elevator
signal  moved_to_floor(path:String,floor:int)
#Signal for when game is paused
signal game_paused()
###############################################################################

#Connecting Functions
func emitCustomSignal(signal_name: String, args = []):
	if has_signal(signal_name):
		var method_name = "emit_signal"
		var full_args = [signal_name] + args
		callv(method_name, full_args)
	else:
		print("Signal not found: " + signal_name)


func connectCustomSignal(signal_name: String, target: Object, method: String, binds: Array = [], flags: int = 0):
	if has_signal(signal_name):
		var callable = Callable(target, method)
		return connect(signal_name, callable.bindv(binds), flags)
	else:
		print("Signal not found: " + signal_name)
		return ERR_INVALID_PARAMETER
