extends Node

# Dictionary with path, category and stack-flags. Allow stacking disables the ability to play same-category-sounds. Category is only used to determine when we are allowed to play
# that specific sound

var sound_dict = {
	"vent1" : {"path" : "res://Assets/Audio/SoundFX/AmbientNeutral/VentilationRumble4.ogg", "category" : 0, "allow_stacking" : false},
	"vent2" : {"path" : "res://Assets/Audio/SoundFX/AmbientNeutral/VentilationRumble5.ogg", "category" : 0, "allow_stacking" : false},
	"vent3" : {"path" : "res://Assets/Audio/SoundFX/AmbientNeutral/VentilationRumble6.ogg", "category" : 1, "allow_stacking" : false},
}

@onready var timer: Timer = $Timer
@onready var active_categories: Array[int] = [
	0, 1
]
@onready var awaited_sound_key: String = ""
@onready var previously_awaited_sound_key: String = ""

@export var maximum_ambiance_restart_time: int = 60
@export var minimum_ambiance_restart_time: int = 12

func _ready() -> void:
	timer.start(2)
	awaited_sound_key = "vent1"
	timer.timeout.connect(_timerdown_play_awaited_sound)
	#var timer = Timer.new()
	#add_child(timer)
	#timer.one_shot = false
	#timer.start(10)
	#timer.timeout.connect(func(): AudioController.play_spatial_resource(load("res://Assets/Audio/SoundFX/AmbientNeutral/VentilationRumble4.ogg")))
	
func _timerdown_play_awaited_sound():
	play_specific_sound(awaited_sound_key)
	previously_awaited_sound_key = String(awaited_sound_key)
	var new_sound_key = ""
	var count = 0
	while(new_sound_key.is_empty()):
		count += 1
		assert(count < 100, "We have played this loop for too long! Possible that all sounds are locked up? Check!")
		var picked_key = sound_dict.keys().pick_random()
		# If the category is allowed
		if active_categories.has(sound_dict[picked_key]["category"]):
			# If the previous sound allows stacking OR the sounds dont share category
			#if sound_dict[previously_awaited_sound_key]["allow_stacking"] == true or (sound_dict[picked_key]["category"] != sound_dict[previously_awaited_sound_key]["category"]):
				#new_sound_key = picked_key
			if sound_dict.has(previously_awaited_sound_key):
				var sounds_share_category = sound_dict[picked_key]["category"] == sound_dict[previously_awaited_sound_key]["category"] 
				var previous_sound_no_stacking = sound_dict[previously_awaited_sound_key]["allow_stacking"] == false
				if !sounds_share_category or !previous_sound_no_stacking:
					new_sound_key = picked_key
			else:
				new_sound_key = picked_key
	awaited_sound_key = new_sound_key

func play_specific_sound(sound_dict_key: String):
	var sound_object = sound_dict[sound_dict_key]
	AudioController.play_spatial_resource(load(sound_object["path"]), Vector3.ZERO, 0, restart_ambiance_timer)
	
func restart_ambiance_timer():
	timer.start(randi_range(minimum_ambiance_restart_time, maximum_ambiance_restart_time))

# TODO CHECK IF THIS WORKS PROPERLY ALONG WITH THE BELOW
func _adjust_active_categories(arr: Dictionary):
	for key in arr:
		if active_categories.has(key) != null and arr[key] == false:
			active_categories.erase(key)
		elif active_categories.has(key) == null and arr[key] == true:
			active_categories.append(key)

# TODO CALL THIS WHEN JOHN 
func john_is_out_change():
	_adjust_active_categories({
		1 : true
	})
