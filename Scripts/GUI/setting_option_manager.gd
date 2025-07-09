extends Panel
@onready var parent = $"../../../.."

@export var setting_title:String
@export var setting_description:String
var stylebox: StyleBoxFlat
func _ready():
	#hover_area.connect("mouse_entered", Callable(self,"on_mouse_entered"))
	#hover_area.connect("mouse_exited",Callable(self,"on_mouse_exited"))
	stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0, 0, 0,0)
	stylebox.border_color = Color(1, 1, 1)
	stylebox.set_border_width_all(0)
	self.add_theme_stylebox_override("panel", stylebox)


func on_mouse_exited():
	stylebox.set_border_width_all(0)

func on_mouse_entered():
	stylebox.set_border_width_all(2)
	#parent.set_setting_description(setting_title,setting_description)
