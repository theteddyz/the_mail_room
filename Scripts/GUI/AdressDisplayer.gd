extends Control
@onready var text_object:RichTextLabel = $RichTextLabel
@onready var animation_player:AnimationPlayer = $AnimationPlayer
@onready var timer:Timer = $Timer

func _ready():
	hide_text()
func set_text(text:String):
	text_object.text = ("[center]" + text)
	show_text()


func show_text():
	animation_player.stop()
	text_object.modulate = Color(1, 1, 1, 1)
	show()

func hide_text():
	hide()



func _on_timer_timeout():
	animation_player.play("fade_out")
