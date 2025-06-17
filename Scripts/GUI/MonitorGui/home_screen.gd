extends Panel

@onready var notepad = $"../NotePad"
@onready var mailPong = $"../MailPongBackground/MailPong"
@onready var paint = $"../Paint"
func _on_button_pressed():
	notepad.show()


func _notepad_close():
	notepad.hide()


func on_mail_pong_close():
	mailPong.hide_game()


func _on_mail_pong_pressed():
	mailPong.player_using_computer = true
	mailPong.start_game()


func _on_paint_pressed():
	paint.show()
