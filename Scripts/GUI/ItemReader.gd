extends Control
@onready var display_text:RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/RichTextLabel
@onready var panel_container:PanelContainer = $PanelContainer
var fade_in_tween:Tween
var fade_out_tween:Tween
func _ready():
	visible = false
func display_item(text):
	if visible == false:
		display_text.text = "[center]" + text + "[/center]"
		show()
		_fade_in()


func hide_item():
	_fade_out()

func _fade_in():
	if fade_out_tween != null:
		if fade_out_tween.is_running():
			fade_out_tween.stop()
	fade_in_tween = create_tween()
	fade_in_tween.tween_property(panel_container, "modulate:a", 1, 1).set_ease(Tween.EASE_IN_OUT)

func _fade_out():
	if fade_in_tween != null:
		if fade_in_tween.is_running():
			fade_in_tween.stop()
	fade_out_tween = create_tween()
	fade_out_tween.tween_property(panel_container, "modulate:a", 0, 1).set_ease(Tween.EASE_IN_OUT)
	await fade_out_tween.finished
	hide()
