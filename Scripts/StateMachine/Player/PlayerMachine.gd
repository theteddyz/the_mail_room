extends CharacterBody3D
class_name PlayerMachine

var pause_menu

# Privates
var state: State
var state_factory: StateFactory
var standing_is_blocked = false

# Called when the node enters the scene tree for the first time.
func _ready():
	state_factory = StateFactory.new()
	GameManager.register_player(self)
	change_state("walking")

# Break this out to a pausemanager or similar
func _shortcut_input(event):
	if event.is_action_pressed("escape"):
		EventBus.emitCustomSignal("game_paused")
	
func change_state(new_state_name):
	if state != null:
		state.queue_free()
	state = state_factory.get_state(new_state_name).new()
	state.setup(Callable(self, "change_state"), self)
	state.name = "current_state"
	add_child(state)

func save():
	var save_dict = {
		"nodepath" : get_parent().name + "/" + name,
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rotation.y" : rotation.y,
	}
	return save_dict
