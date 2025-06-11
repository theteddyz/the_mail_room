extends Node3D
class_name ShadowMachine

var state: State
var previous_state: String
var state_factory: ShadowStateFactory
var player_errors := 0

# Debug export
@export var enabled: bool = true
@export var scare_manager: Node
@onready var startposition = position.y
@onready var collision_shape_3d: CollisionShape3D = $Collider/CollisionShape3D

func _ready() -> void:
	assert(scare_manager != null, "A reference to the scare_manager is required for the shadowspecter to function. Please assign one now, or remove the shadow if none exists.")
	state_factory = ShadowStateFactory.new()
	scare_manager.package_order_disrupted.connect(_initialize)
	visible = false
	collision_shape_3d.disabled = true

func _initialize():
	player_errors += 1
	scare_manager.package_order_disrupted.disconnect(_initialize)
	change_state("teleporting")

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
