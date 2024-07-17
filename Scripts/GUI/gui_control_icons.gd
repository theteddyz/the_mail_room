extends Control
@onready var anim:AnimationPlayer = $AnimationPlayer

func _ready():
	#hide()
	pass

func show_icon(b:bool):
	if b:
		show()
	else:
		hide()

func scroll_up():
	if !anim.is_playing():
		anim.play("scroll_up")


func scroll_down():
	if !anim.is_playing():
		anim.play("scroll_down")
