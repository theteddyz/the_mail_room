extends Node3D

var tutorial_started = false
var step_1_played = false
var player_radio 
var mail_cart
var package_in_mailcart
var start_sound = preload("res://Assets/Audio/SoundFX/VoiceLines/IntroMailRoom2.ogg")
var tutorial_step_1 = preload("res://Assets/Audio/SoundFX/VoiceLines/TutorialStep1.ogg")
var tutorial_step_2 = preload("res://Assets/Audio/SoundFX/VoiceLines/TutorialStep2.ogg")
var tutorial_step_3 = preload("res://Assets/Audio/SoundFX/VoiceLines/TutorialStep3.ogg")
var tutorial_end = preload("res://Assets/Audio/SoundFX/VoiceLines/TutorialEnd.ogg")
var that_just_happened = preload("res://Assets/Audio/SoundFX/VoiceLines/ThatJustHappened.ogg")
@onready var finance_floor_chute = $"../stage/Objects/StaticBody3D6"
func _ready():
	player_radio = GameManager.get_player_radio()
	mail_cart = GameManager.get_mail_cart()
	ScareDirector.connect("package_delivered", start_tutorial_end)
func _on_area_3d_body_entered(body):
	if body.name == "Player" and !tutorial_started:
		tutorial_started = true
		player_radio.play_narrator_sound(start_sound)


func _on_tutorial_start_body_entered(body):
	if tutorial_started and !step_1_played:
		step_1_played = true
		player_radio.play_narrator_sound(tutorial_step_1)

func start_tutorial_end(num):
	var player_audio_player = player_radio.get_stream_player()
	await player_audio_player.finished
	player_radio.play_narrator_sound(that_just_happened)
	player_radio.play_narrator_sound(tutorial_end)
	finance_floor_chute.activate_chute()
	

func start_tutorial_part_2():
	player_radio.play_narrator_sound(tutorial_step_2)
	player_radio.play_narrator_sound(tutorial_step_3)

func _process(delta):
	if step_1_played and !package_in_mailcart:
		if mail_cart.game_objects.size() > 0:
			package_in_mailcart = true
			start_tutorial_part_2()
