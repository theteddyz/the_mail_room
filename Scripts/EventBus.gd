extends Node
#Signals 
#Signals when an game object is held by player and feeds mass
signal object_held(mass: float, object: Node3D)
#Signals when we drop an object and feeds mass. Mass is not needed but need an arg 
#Should be fixed later bother Jakob is not
signal dropped_object(mass:float)
#Signal for telling the pause menu we are reading something
signal player_reading(is_reading:bool)




#Connecting Functions
func emitCustomSignal(signal_name: String, args = []):
	if has_signal(signal_name):
		if args.size() == 1:
			emit_signal(signal_name, args[0])
		if args.size() == 2:
			print(args)
			emit_signal(signal_name, args[0], args[1])
			
		if args.size() == 3:
			emit_signal(signal_name, args[0], args[1], args[2])
				
	else:
		print("Signal not found: " + signal_name)


func connectCustomSignal(signal_name: String, target: Object, method: String, binds: Array = [], flags: int = 0):
	if has_signal(signal_name):
		var callable = Callable(target, method)
		return connect(signal_name, callable.bindv(binds), flags)
	else:
		print("Signal not found: " + signal_name)
		return ERR_INVALID_PARAMETER
