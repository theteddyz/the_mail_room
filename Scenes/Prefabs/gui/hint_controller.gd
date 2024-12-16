extends Control

@export var typing_presentation_variation: bool = false
var hint_dict = {
	"intro" : {
		"text":"This is a hint, they will pop up in relevant contexts and provide you with useful information, such as controls.",
		"one_shot":true,
		"fired":false
	},
	"darkness" :{
		"text": "Your eyes will slowly adapt to dark areas. Look for shapes and corners to find your way.",
		"one_shot":true,
		"fired":false
	},
	"keys" : {
		"text":"Some doors may require keys.",
		"one_shot": true,
		"fired":false
	},
	"journal" : {
		"text":"Useful documents are added to your journal. [J]",
		"one_shot":true,
		"fired":false
	},
	"inspect": {
		"text":"To inspect packages, hold right click.",
		"one_shot":true,
		"fired":false
	}
	
}
@onready var hint_title: Label = $MarginContainer/HintTitle
@onready var breadtext: Label = $MarginContainer/Breadtext
@onready var margin_container: MarginContainer = $MarginContainer
@onready var typewrite_sfx: AudioStreamPlayer = $TypewriteSFX
var intensity_flag = false
var previously_displayed_hint
var local_tween: Tween
var coroutine_passer

func _ready():
	margin_container.set_modulate(Color(1, 1, 1, 0))
	ScareDirector.disable_intensity_flag.connect(disable_intensity_flag)
	ScareDirector.enable_intensity_flag.connect(enable_intensity_flag)
	
func enable_intensity_flag():
	intensity_flag = true
	if local_tween != null:
		local_tween.kill()
		previously_displayed_hint["fired"] = false
		coroutine_passer = Time.get_unix_time_from_system()

func disable_intensity_flag():
	intensity_flag = false
	assert(local_tween != null, "A hint coroutine has started even though our intensity flag is true, this should never happen")
	

# Display a hint from the dictionary
func display_hint(key: String, duration: float):
	assert(hint_dict.has(key), "The hint for key " + key + " does not exist. Create one or delete the calling reference.")
	if !(hint_dict[key]["fired"] and hint_dict[key]["one_shot"] and !intensity_flag):
		coroutine_passer = Time.get_unix_time_from_system()
		var start_pass = coroutine_passer
		previously_displayed_hint = hint_dict[key]
		hint_dict[key]["fired"] = true
		
		if !(hint_dict[key]["text"].length() > 50):
			breadtext.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else: 
			breadtext.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			
		if !typing_presentation_variation:
			breadtext.text = hint_dict[key]

			local_tween = create_tween()
			local_tween.tween_property(margin_container, "modulate", Color(1, 1, 1, 1), 0.66);
			await local_tween.finished
			if start_pass == coroutine_passer:
				await get_tree().create_timer(duration).timeout
			if start_pass == coroutine_passer:
				local_tween = create_tween()
				local_tween.tween_property(margin_container, "modulate", Color(1, 1, 1, 0), 0.66);
				await local_tween.finished
		else:
			if start_pass == coroutine_passer:
				hint_title.modulate = Color(1, 1, 1, 0)
				breadtext.modulate = Color(1, 1, 1, 0)
				margin_container.modulate = Color(1, 1, 1, 1)
				local_tween = create_tween()
				local_tween.tween_property(hint_title, "modulate", Color(1, 1, 1, 1), 0.66);
				await local_tween.finished
			if start_pass == coroutine_passer:
				await type_breadtext(hint_dict[key]["text"], duration, start_pass)

func type_breadtext(text: String, wait_time: float, start_pass):
	breadtext.text = ""
	breadtext.modulate = Color(1, 1, 1, 1)
	if start_pass == coroutine_passer:
		for symbol in text:
			await get_tree().create_timer(randf_range(0.0075, 0.038)).timeout
			breadtext.text += symbol
			typewrite_sfx.playing = true
	if start_pass == coroutine_passer:
		await get_tree().create_timer(wait_time).timeout
	if start_pass == coroutine_passer:
		var tween = create_tween()
		tween.tween_property(margin_container, "modulate", Color(1, 1, 1, 0), 0.66);
		await tween.finished
