extends CharacterBody3D
class_name PlayerMachine

var pause_menu

# Privates
var state: State
var state_factory: StateFactory
var extra_life = 1
@onready var hit_timer: Timer = $hit_timer
const DAMAGE_GRADIENT_TEXTURE = preload("res://Scenes/Worlds/FinanceDamaged.tres")
const REGULAR_WE = preload("res://Scenes/Worlds/Finance.tres")
@onready var scare_vision_controller = $ScareVisionController

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

# Move this to some hit-manager
func hit_by_entity():
	if extra_life == 1 and hit_timer.time_left <= 0:
		# Generate hit effect
		#TODO: Revisit this, kinda ugly
		var par = get_parent()
		if par.name == "Mailcart":
			par = par.get_parent()
		par.get_node("WorldEnvironment").set_environment(DAMAGE_GRADIENT_TEXTURE)
		var timer = get_tree().create_timer(0.35)
		timer.timeout.connect(func(): par.get_node("WorldEnvironment").set_environment(REGULAR_WE))
		timer.timeout.connect(_reset_we_visual)
		hit_timer.start(1.25)
		extra_life = 0
	elif hit_timer.time_left <= 0:
		var par = get_parent()
		if par.name == "Mailcart":
			par = par.get_parent()
		scare_vision_controller.tween.kill() if scare_vision_controller.tween != null else null
		scare_vision_controller.reset_world_environment_visual()
		par.get_node("WorldEnvironment").set_environment(DAMAGE_GRADIENT_TEXTURE)
		var timer = get_tree().create_timer(0.08)
		timer.timeout.connect(game_over)
		
func game_over():
	_reset_we_visual()
	var par = get_parent()
	par.get_node("WorldEnvironment").set_environment(REGULAR_WE)
	get_tree().change_scene_to_file("res://Scenes/Prefabs/gui/MainMenu.tscn")
	
func _reset_we_visual():
	scare_vision_controller.tween.kill() if scare_vision_controller.tween != null else null
	scare_vision_controller.reset_world_environment_visual()
	
func save():
	var save_dict = {
		"nodepath" : get_parent().name + "/" + name,
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rotation.y" : rotation.y,
	}
	return save_dict
