extends Node

# Enum-like dictionary to map effect names to numbers
enum Effect { NONE, MONSTER_SEEN, DELAY }

# Export this variable so you can select from the editor
@export var effect_type: Effect = Effect.NONE
@export var delay_length: float = 0
signal callback_done

func _ready():
	pass
	#ScareDirector.connect("monster_seen", _seen_check_for)
	
# External callback function that could have some delay or complex operations
func scare_vision_external_callback() -> void:
	match effect_type:
		Effect.MONSTER_SEEN:
			await _seen_check_for(false)
		Effect.DELAY:
			await delay_length
	print("Scarevision effect: DONE!")
	emit_signal("callback_done")
	
func _seen_check_for(seen: bool):
	var flag = !seen 
	while flag != seen:
		flag = await ScareDirector.monster_seen
