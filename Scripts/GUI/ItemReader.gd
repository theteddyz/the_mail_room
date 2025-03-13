extends Control
@onready var display_text:RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/RichTextLabel
@onready var panel_container:PanelContainer = $PanelContainer
var tween: Tween
var is_fading: bool = false
func _ready():
	visible = false
	panel_container.modulate.a = 0
func display_item(text):
	if is_fading:
		tween.stop() 
		is_fading = false
	display_text.text = "[center]" + text + "[/center]"
	if not visible:
		show()
	_fade_in()


func hide_item():
	if is_fading:
		tween.stop()
		is_fading = false
	_fade_out()

func _fade_in():
	is_fading = true
	tween = create_tween()
	tween.tween_property(panel_container, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	is_fading = false


func _fade_out():
	is_fading = true
	tween = create_tween()
	tween.tween_property(panel_container, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	is_fading = false
	hide()
