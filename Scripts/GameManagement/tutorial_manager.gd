extends Node3D

var tutorial_started = false
var step_1_played = false
var step_2_played = false
var step_3_played = false
var player_radio 
var mail_cart
var package_in_mailcart
var player
var start_sound = preload("res://Assets/Audio/SoundFX/VoiceLines/IntroMailRoom2.ogg")
var tutorial_step_1 = preload("res://Assets/Audio/SoundFX/VoiceLines/TutorialStep1.ogg")
var tutorial_step_2 = preload("res://Assets/Audio/SoundFX/VoiceLines/TutorialStep2.ogg")
var tutorial_step_3 = preload("res://Assets/Audio/SoundFX/VoiceLines/TutorialStep3.ogg")
var tutorial_end = preload("res://Assets/Audio/SoundFX/VoiceLines/TutorialEnd.ogg")
var that_just_happened = preload("res://Assets/Audio/SoundFX/VoiceLines/ThatJustHappened.ogg")
var mailroom_discovery_audio = preload("res://Assets/Audio/SoundFX/AmbientNeutral/MailRoomTransitionalAmbience1.ogg")
@onready var finance_floor_chute = $"../mailroom_prefab/Objects/StaticBody3D6"
func _ready():
	player_radio = GameManager.get_player_radio()
	mail_cart = GameManager.get_mail_cart()
	player = GameManager.get_player()
	ScareDirector.connect("package_delivered", start_tutorial_end)
	EventBus.connect("object_held",start_tutorial_part_3)
func _on_area_3d_body_entered(body):
	if (body.name == "Player" or body.name == "Mailcart") and !tutorial_started:
		tutorial_started = true
		var timer = Timer.new()
		add_child(timer)
		timer.one_shot = false
		timer.start(8.9)
		AudioController.play_resource(mailroom_discovery_audio, 0, func():, 18)
		#timer.timeout.connect(func(): player_radio.play_narrator_sound(start_sound))
		#timer.timeout.connect(func(): timer.queue_free())

func _on_tutorial_start_body_entered(body):
	if tutorial_started and !step_1_played:
		step_1_played = true
		#player_radio.play_narrator_sound(tutorial_step_1)

func start_tutorial_end(num):
	var player_audio_player = player_radio.get_stream_player()
	await player_audio_player.finished
	#player_radio.play_narrator_sound(that_just_happened)
	await get_tree().create_timer(3.0).timeout
	#player_radio.play_narrator_sound(tutorial_end)
	await get_tree().create_timer(2.0).timeout
	finance_floor_chute.activate_chute()
	
func start_tutorial_part_3(var1,var2):
	if var2 is Package and step_2_played == true and !step_3_played:
		await get_tree().create_timer(3.0).timeout
		#player_radio.play_narrator_sound(tutorial_step_3)
		step_3_played = true
func start_tutorial_part_2():
	await get_tree().create_timer(2.0).timeout
	#player_radio.play_narrator_sound(tutorial_step_2)
	step_2_played = true

func _process(delta):
	if step_1_played and !package_in_mailcart:
		if mail_cart.game_objects.size() > 0:
			package_in_mailcart = true
			start_tutorial_part_2()
