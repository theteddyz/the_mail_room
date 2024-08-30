extends Control
@onready var display_text:RichTextLabel = $RichTextLabel



func display_item(text):
	if visible == false:
		display_text.text = "[center]" + text + "[/center]"
		show()
		print("displaying", display_text.visible)
		


func hide_item():
	display_text.text = ""
	hide()
