extends CharacterBody3D
class_name PlayerMachine

var pause_menu

# Privates
var state: State
var state_factory: StateFactory
var extra_life = 1
var hit_timer: SceneTreeTimer
const DAMAGE_GRADIENT_TEXTURE = preload("res://damage_gradient_texture.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	hit_timer = get_tree().create_timer(0)
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

# Move this to some hit-manager
func hit_by_entity():
	if extra_life == 1 and hit_timer.time_left <= 0:
		# Generate hit effect
		#TODO: Revisit this, kinda ugly
		var par = get_parent()
		if par.name == "Mailcart":
			par = par.get_parent()
		par.get_node("WorldEnvironment").set_adjustment_color_correction(DAMAGE_GRADIENT_TEXTURE)
		var timer = get_tree().create_timer(0.35)
		timer.timeout.connect(func(): par.get_node("WorldEnvironment").set_adjustment_color_correction(null))
		hit_timer.start(1.25)
	else:
		var par = get_parent()
		if par.name == "Mailcart":
			par = par.get_parent()
		par.get_node("WorldEnvironment").set_adjustment_color_correction(DAMAGE_GRADIENT_TEXTURE)
		var timer = get_tree().create_timer(0.08)
		timer.timeout.connect(func(): par.get_node("WorldEnvironment").set_adjustment_color_correction(null))
		
func save():
	var save_dict = {
		"nodepath" : get_parent().name + "/" + name,
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rotation.y" : rotation.y,
	}
	return save_dict
