extends Control

@onready var pause_menu = $"../pauseMenu"
@onready var controls_menu = $Controls
@onready var display_menu = $Display
@onready var graphics_menu = $graphics
@onready var audio_menu = $audio
@onready var system_menu = $system
@onready var selected_option:RichTextLabel = $OptionsSelectedLabel
@onready var options_holder = $OptionsButtons
var current_submenu:Array
func _ready():
	hide()






func _on_controls_pressed():
	options_holder.hide()
	controls_menu.show()
	current_submenu.append(controls_menu)
	set_options_label("CONTROLS")
func _on_display_pressed():
	options_holder.hide()
	display_menu.show()
	current_submenu.append(display_menu)
	set_options_label("DISPLAY")

func _on_graphics_pressed():
	pass # Replace with function body.


func _on_audio_pressed():
	pass # Replace with function body.


func _on_system_pressed():
	pass # Replace with function body.




func set_options_label(text):
	if selected_option.text == "":
		selected_option.text = text
		selected_option.show()
	else:
		selected_option.text = ""
		selected_option.hide()


func _on_back_button_pressed():
	if current_submenu.size() > 0:
		current_submenu[0].hide()
		set_options_label("")
		options_holder.show()
		current_submenu.clear()
	else:
		hide()
		pause_menu._reset_button_alpha()
