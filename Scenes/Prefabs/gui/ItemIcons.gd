extends Control
@onready var key_icon = $KeyIcon

func _ready():
	key_icon.visible = false
func show_icon():
	key_icon.visible = true

func hide_icon():
	key_icon.visible = false
