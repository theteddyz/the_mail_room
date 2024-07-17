extends Control
@onready var text_object = $RichTextLabel
@onready var animation_player = $AnimationPlayer
@onready var timer = $Timer

func set_text(text:String):
	text_object.text = ("[center]" + text)
	show_text()
	start_fade_timer()


func show_text():
	animation_player.stop()
	text_object.modulate = Color(1, 1, 1, 1)
	visible = true

func hide_text():
	visible = false

func start_fade_timer():
	timer.start(2.0)

func _on_timer_timeout():
	animation_player.play("fade_out")
