extends Node
#Signals 
#Signals when an game object is held by player and feeds mass
signal object_held(mass: float)
#Signals when we drop an object and feeds mass. Mass is not needed but need an arg 
#Should be fixed later bother Jakob is not
signal dropped_object(mass:float)









#Connecting Functions
func emitCustomSignal(signal_name: String, args = []):
	if has_signal(signal_name):
		emit_signal(signal_name, args)
	else:
		print("Signal not found: " + signal_name)


func connectCustomSignal(signal_name: String, target: Object, method: String, binds: Array = [], flags: int = 0):
	if has_signal(signal_name):
		var callable = Callable(target, method)
		return connect(signal_name, callable.bindv(binds), flags)
	else:
		print("Signal not found: " + signal_name)
		return ERR_INVALID_PARAMETER
