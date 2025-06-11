class_name ShadowStateFactory

var states

func _init():
	states = {
		"aggro": ShadowChasingState,
		"respawning": ShadowRespawningState,
		"teleporting": ShadowTeleportingState
	}

func get_state(state_name):
	if states.has(state_name):
		return states.get(state_name)
	else:
		printerr("No state ", state_name, " in state factory!")
