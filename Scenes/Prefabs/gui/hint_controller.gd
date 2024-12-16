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

var cancellation_breadtext_suffixes = [
	"€AxAe@!eO5% gw6Aki ¤j0Vb9k$xA e@!e5Fer%()xj0Vb9k$ xAe@!ej0Vb9k35Fer%()x5-,! eO5%gw66Aki;",
	"o1!35Fer%()x5-,!eO5%gw66Aki¤j-,!eO6r%()x5-,9k$t1kL $163G3G @c[]1()x5;",
	"xJ%t1 kL$163G@c[ ]1()x5-,!eO6Aki¤j0Vb 9k$t1kL$163G@c[ 0Vb9k$xAe@ !e5Fer%()x;",
]
@onready var hint_title: Label = $MarginContainer/HintTitle
@onready var breadtext: Label = $MarginContainer/Breadtext
@onready var margin_container: MarginContainer = $MarginContainer
@onready var typewrite_sfx: AudioStreamPlayer = $TypewriteSFX
var intensity_flag = false
var previously_displayed_hint
var local_tween: Tween
var coroutine_passer

var label_settings_hint_title_resource
var label_settings_hint_title_cancelled_resource

func _ready():
	margin_container.set_modulate(Color(1, 1, 1, 0))
	ScareDirector.disable_intensity_flag.connect(disable_intensity_flag)
	ScareDirector.enable_intensity_flag.connect(enable_intensity_flag)
	label_settings_hint_title_resource = preload("res://label_settings_hint_title.tres")
	label_settings_hint_title_cancelled_resource = preload("res://label_settings_hint_title_cancelled.tres")

func enable_intensity_flag():
	intensity_flag = true
	if local_tween != null:
		local_tween.kill()
		previously_displayed_hint["fired"] = false
		coroutine_passer = Time.get_unix_time_from_system()
		hint_title.label_settings = label_settings_hint_title_cancelled_resource
		
		local_tween = create_tween().set_parallel(true)
		local_tween.tween_property(hint_title, "position", Vector2(-10, hint_title.position.y), 0.08);
		local_tween.chain().tween_property(hint_title, "position", Vector2(10, hint_title.position.y), 0.13);
		local_tween.chain().tween_property(hint_title, "position", Vector2(-6, hint_title.position.y), 0.16);
		local_tween.chain().tween_property(hint_title, "position", Vector2(6, hint_title.position.y), 0.215);
		local_tween.chain().tween_property(hint_title, "position", Vector2(0, hint_title.position.y), 0.25);
		local_tween.chain().tween_property(margin_container, "modulate", Color(1, 1, 1, 0), 1.98);
		for symbol in cancellation_breadtext_suffixes.pick_random():
			await get_tree().create_timer(randf_range(0.009, 0.022)).timeout
			breadtext.text += symbol

func disable_intensity_flag():
	intensity_flag = false

# Display a hint from the dictionary
func display_hint(key: String, duration: float):
	assert(hint_dict.has(key), "The hint for key " + key + " does not exist. Create one or delete the calling reference.")
	if !(hint_dict[key]["fired"] and hint_dict[key]["one_shot"] and !intensity_flag):
		hint_title.label_settings = label_settings_hint_title_resource
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
	for symbol in text:
		if start_pass == coroutine_passer:
			await get_tree().create_timer(randf_range(0.0075, 0.038)).timeout
			breadtext.text += symbol
			typewrite_sfx.playing = true
	if start_pass == coroutine_passer:
		await get_tree().create_timer(wait_time).timeout
	if start_pass == coroutine_passer:
		var tween = create_tween()
		tween.tween_property(margin_container, "modulate", Color(1, 1, 1, 0), 0.66);
		await tween.finished
