extends Node3D

var tutorial_started = false
var step_1_not_ran = true
var step_2_not_ran = true
var step_3_not_ran = true
var start_sound = preload("res://Assets/Audio/SoundFX/VoiceLines/IntroMailRoom2.ogg")
var tutorial_step_1 = preload("res://Assets/Audio/SoundFX/VoiceLines/TutorialStep1.ogg")
var tutorial_step_2 = preload("res://Assets/Audio/SoundFX/VoiceLines/TutorialStep2.ogg")
var tutorial_step_3 = preload("res://Assets/Audio/SoundFX/VoiceLines/TutorialStep3.ogg")
var tutorial_end = preload("res://Assets/Audio/SoundFX/VoiceLines/TutorialEnd.ogg")
var that_just_happened = preload("res://Assets/Audio/SoundFX/VoiceLines/ThatJustHappened.ogg")
var mailroom_discovery_audio = preload("res://Assets/Audio/SoundFX/AmbientNeutral/MailRoomTransitionalAmbience1.ogg")
var tutorial_queue: Array = []
var is_busy: bool = false
@onready var tv_screen: Area3D = $"../Crttv/Area3D"
@onready var finance_floor_chute = $"../mailroom_prefab/Objects/StaticBody3D6"

func _ready():
	EventBus.connect("object_held", start_tutorial_step_3)
	ScareDirector.connect("package_delivered", start_tutorial_end)

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



func _on_start_area_body_entered(body: Node3D) -> void:
	if (body.name == "Player") and !tutorial_started:
		trigger_tutorial_step(_tutorial_1)

func _tutorial_1():
	tutorial_started = true	
	AudioController.play_resource(mailroom_discovery_audio, 0, func():, 18)
	await get_tree().create_timer(8.9).timeout
	GameManager.get_player_radio().play_narrator_sound(start_sound)
	GameManager.get_player_radio().radio_sound_player.finished.connect(on_step_complete)


func _on_tutorial_step_one_body_entered(body: Node3D) -> void:
	if (body.name == "Player") and step_1_not_ran and tutorial_started:
		step_1_not_ran = false
		trigger_tutorial_step(_tutorial_2)

func _tutorial_2():
	tv_screen.interact()
	tv_screen.video_player.finished.connect(_tutorial_3)

func _tutorial_3():
	GameManager.get_player_radio().play_narrator_sound(tutorial_step_1)
	GameManager.get_player_radio().radio_sound_player.finished.connect(on_step_complete)



func _process(delta):
	if !step_1_not_ran and step_2_not_ran:
		if GameManager.get_mail_cart().game_objects.size() > 0 or GameManager.get_player().state.is_holding_package:
			step_2_not_ran = false
			trigger_tutorial_step(_tutorial_4)

func _tutorial_4():
	GameManager.get_player_radio().play_narrator_sound(tutorial_step_2)
	GameManager.get_player_radio().radio_sound_player.finished.connect(on_step_complete)



func start_tutorial_step_3(var1,var2): 
	if var2 is Package and !step_1_not_ran and !step_2_not_ran:
		trigger_tutorial_step(_tutorial_5)

func _tutorial_5():
	step_3_not_ran = false
	await get_tree().create_timer(3.0).timeout
	GameManager.get_player_radio().play_narrator_sound(tutorial_step_3)
	GameManager.get_player_radio().radio_sound_player.finished.connect(on_step_complete)



func start_tutorial_end(package_num: int):
	#player_radio.play_narrator_sound(that_just_happened)
	var elevator = GameManager.get_elevator()
	elevator.light_active_button()
	finance_floor_chute.activate_chute()
	tutorial_queue.clear()
	tv_screen.stop_video()
	await GameManager.get_player_radio().radio_sound_player.finished
	GameManager.get_player_radio().play_narrator_sound(tutorial_end)
