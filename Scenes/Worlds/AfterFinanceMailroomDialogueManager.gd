extends Node3D

const DISCLAIMER = preload("res://Assets/Audio/SoundFX/VoiceLines/Disclaimer.ogg")
const BACK_FROM_FINANCE = preload("res://Assets/Audio/SoundFX/VoiceLines/BackFromFinance.ogg")
const APOLOGETIC = preload("res://Assets/Audio/SoundFX/VoiceLines/Apologetic.ogg")
var dialogue_started := false
var apologetic_not_played := true
var tutorial_queue: Array = []
var is_busy: bool = false


# Called when a tutorial trigger is activated
func trigger_tutorial_step(callback: Callable) -> void:
	if is_busy:
		tutorial_queue.append(callback)
	else:
		is_busy = true
		callback.call()

# Call this when the current tutorial step is done (e.g. audio finishes)
func on_step_complete() -> void:
	if tutorial_queue.size() > 0:
		var next_step: Callable = tutorial_queue.pop_front()
		is_busy = true
		next_step.call()
	else:
		is_busy = false

func _on_starting_trigger_body_entered(body: Node3D) -> void:
	if !dialogue_started:
		dialogue_started = true
		trigger_tutorial_step(_initial_dialogue)

func _initial_dialogue():
	GameManager.get_player_radio().play_narrator_sound(BACK_FROM_FINANCE)
	await GameManager.get_player_radio().radio_sound_player.finished
	GameManager.get_player_radio().play_narrator_sound(DISCLAIMER)
	GameManager.get_player_radio().radio_sound_player.finished.connect(on_step_complete)

func _process(delta):
	if dialogue_started and apologetic_not_played:
		if GameManager.get_mail_cart().game_objects.size() > 0 or GameManager.get_player().state.is_holding_package:
			apologetic_not_played = false
			trigger_tutorial_step(_second_dialogue)

func _second_dialogue():
	GameManager.get_player_radio().play_narrator_sound(APOLOGETIC)
	GameManager.get_player_radio().radio_sound_player.finished.connect(on_step_complete)
