extends Control
@onready var text_object = $RichTextLabel


func set_text(text:String):
	text_object.text = ("[center]" + text)


func show_text():
	visible = true

func hide_text():
	visible = false
