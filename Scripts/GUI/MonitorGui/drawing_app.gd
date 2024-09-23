extends Node2D
@onready var _lines:Node2D = $Line2D
var _pressed:bool = false
var _current_line:Line2D = null
@onready var _panel:Panel = $".."
var current_color = Color.BLACK
##Colors##
@onready var red_button:Button = $"../Red"
@onready var light_blue_button:Button = $"../Light_Blue"
@onready var yellow_button:Button = $"../Yellow"
@onready var blue_button:Button = $"../Blue"
@onready var eraser_button:Button = $"../Eraser"
@onready var reset_button:Button = $"../Reset"
var background_color = Color.GRAY
var selected_color_object
var is_eraser = false  # New eraser flag

func _ready():
	var style:StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color =  Color.GRAY
	_panel.add_theme_stylebox_override("panel", style)
	red_button.connect("pressed", Callable(self, "on_color_pressed").bind(red_button))
	light_blue_button.connect("pressed", Callable(self, "on_color_pressed").bind(light_blue_button))
	blue_button.connect("pressed", Callable(self, "on_color_pressed").bind(blue_button))
	yellow_button.connect("pressed", Callable(self, "on_color_pressed").bind(yellow_button))
	eraser_button.connect("pressed", Callable(self, "_on_eraser_pressed"))
	reset_button.connect("pressed", Callable(self, "_on_reset_press"))

func _input(event:InputEvent) -> void:
	if _panel.visible:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_pressed = event.pressed
				if _pressed and is_inside_panel(event.position):
						_current_line = Line2D.new()
						_current_line.default_color = current_color
						_current_line.width = 4
						_lines.add_child(_current_line)
						_current_line.add_point(to_local_panel_position(event.position))
		elif event is InputEventMouseMotion and _pressed:
				_current_line.add_point(to_local_panel_position(event.position))

func is_inside_panel(position:Vector2) -> bool:
	var panel_rect = Rect2(_panel.global_position, _panel.size)
	return panel_rect.has_point(position)

func to_local_panel_position(global_position:Vector2) -> Vector2:
	return global_position - _panel.global_position

func on_color_pressed(object):
	var color:ColorRect = object.get_child(0)
	var select_color:ColorRect = object.get_child(1)
	if current_color != color.color:
		if selected_color_object:
			selected_color_object.hide()
		current_color = color.color
		selected_color_object = select_color
		select_color.show()

#Erase
func _on_eraser_pressed():
	is_eraser = true 
	current_color = background_color  
	if selected_color_object:
		selected_color_object.hide()

func _on_reset_press():
	for line in _lines.get_children():
		line.queue_free() 


func _on_hide_pressed():
	get_parent().hide()
