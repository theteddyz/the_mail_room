extends Node

signal object_held(mass: float)


func emitCustomSignal(signal_name: String, args):
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
