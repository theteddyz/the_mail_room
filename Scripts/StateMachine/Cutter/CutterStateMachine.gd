extends CharacterBody3D
class_name CutterMachine

var state: State
var previous_state: String
var state_factory: CutterStateFactory

# Debug export
@export var enabled: bool = true
@export var can_see_player: bool = true
@onready var startposition = position.y


func _ready() -> void:
	state_factory = CutterStateFactory.new()
	change_state("roaming")

func change_state(new_state_name):
	if state != null:
		previous_state = state.get_class_custom()
		state.queue_free()
	state = state_factory.get_state(new_state_name).new()
	state.setup(Callable(self, "change_state"), self)
	state.name = "current_state"
	add_child(state)

# Enum-like dictionary to map effect names to numbers
enum Effect { NONE, MONSTER_SEEN, DELAY }

# Export this variable so you can select from the editor
@export var effect_type: Effect = Effect.NONE
@export var delay_length: float = 0
var keep_scare_vision: bool = true
signal external_callback
var _running_callback = false
#signal callback_done

# External callback function that could have some delay or complex operations
func scare_vision_external_callback() -> void:
	_running_callback = true
	match effect_type:
		Effect.MONSTER_SEEN:
			await _seen_check_for(false)
		Effect.DELAY:
			await delay_length
	emit_signal("external_callback")
	_running_callback = false

func _exit_tree() -> void:
	if _running_callback:
		emit_signal("external_callback")
		_running_callback = false
	
func _seen_check_for(seen: bool):
	var flag = !seen 
	while flag != seen:
		flag = await ScareDirector.monster_seen
