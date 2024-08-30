extends Control
@onready var display_text:RichTextLabel = $Panel/RichTextLabel
@onready var panel:Panel = $Panel

func _ready():
	visible = false
func display_item(text):
	if visible == false:
		display_text.text = "[center]" + text + "[/center]"
		display_text.call_deferred("scroll_to_line", 0)
		display_text.call_deferred("_resize_panel")
		show()


func hide_item():
	display_text.text = ""
	hide()


func _resize_panel():
	var text_size = display_text.get_minimum_size()
	var padding = Vector2(20, 20)
	panel.rect_size = text_size + padding
