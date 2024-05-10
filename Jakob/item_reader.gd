extends Control

@onready var object_text:RichTextLabel = $VBoxContainer/RichTextLabel
func _ready():
	set_text("this is a typewritter effect and i am working. This is really cool actually and not stupid at all. I AM SCARED AHHHHHHHHHHHHHHHHHHHHH SCARY MONSTER.")




func set_text(text):
	object_text.modulate = Color(1, 1, 1, 1)
	object_text.text = ""  # Start with empty text
	await display_text_with_typewriter_effect(text, 0.03)  # Adjust the speed as necessary


func display_text_with_typewriter_effect(text: String, delay: float):
	for i in range(len(text)):
		object_text.text = "[center]" + text.substr(0, i + 1) + "[/center]"
		await get_tree().create_timer(delay).timeout
