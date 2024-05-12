extends Control

@onready var object_text:RichTextLabel = $VBoxContainer/ScrollContainer/RichTextLabel
@onready var background_image:TextureRect = $TextureRect
var skip_typewriter_effect: bool = false


func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		skip_typewriter_effect = true

func set_text(text:String,img_path:String):
	var img = load(img_path)
	background_image.texture = img
	skip_typewriter_effect = false
	object_text.modulate = Color(1, 1, 1, 1)
	object_text.text = ""  # Start with empty text
	self.show()
	await display_text_with_typewriter_effect(text, 0.03)  # Adjust the speed as necessary

func display_text_with_typewriter_effect(text: String, delay: float):
	for i in range(len(text)):
		if skip_typewriter_effect:
			object_text.text = "[center]" + text + "[/center]"
			return
		object_text.text = "[center]" + text.substr(0, i + 1) + "[/center]"
		await get_tree().create_timer(delay).timeout
