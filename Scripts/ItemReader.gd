extends Control

@onready var object_text:RichTextLabel = $VBoxContainer/ScrollContainer/RichTextLabel
@onready var background_image:TextureRect = $TextureRect
var skip_typewriter_effect: bool = false
var player 
func _ready():
	#hide()
	pass

func display_item(text:String,img_path:Texture2D):
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	player = $"../../Player"
	player.state.is_reading = true
	set_text(text,img_path)
	EventBus.emitCustomSignal("player_reading",[is_reading(0)])
	

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		skip_typewriter_effect = true

func set_text(text:String,img_path:Texture2D):
	var delay = 0.03
	background_image.texture = img_path
	skip_typewriter_effect = false
	object_text.modulate = Color(1, 1, 1, 1)
	object_text.text = ""  # Start with empty text
	self.show()
	await display_text_with_typewriter_effect(text, delay)  # Adjust the speed as necessary

func display_text_with_typewriter_effect(text: String, delay: float):
	for i in range(len(text)):
		if skip_typewriter_effect:
			object_text.text = "[center]" + text + "[/center]"
			return
		object_text.text = "[center]" + text.substr(0, i + 1) + "[/center]"
		await get_tree().create_timer(delay).timeout

func is_reading(caller:int)->bool:
	if caller == 0:
		return true
	else:
		return false
func _on_button_pressed():
	hide()
	EventBus.emitCustomSignal("player_reading",[is_reading(1)])
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.state.is_reading = false
