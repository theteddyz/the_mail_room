class_name CutterStateFactory

var states

func _init():
	states = {
		"roaming": CutterRoamingState,
		"aggro": CutterAggroState,
		"respawning": CutterRespawningState,
		"carcass": CutterCarcassState,
		#"aggroState: AggroState
	}

func get_state(state_name):
	if states.has(state_name):
		return states.get(state_name)
	else:
		printerr("No state ", state_name, " in state factory!")
