extends Control
@export_enum("text file", "image") var file_type: int
@export var application_text:String
var text_icon = preload("res://Assets/TemporaryAssets/Folder Friends icOnS/Sprites/Files/Files2_2.png")
var image_icon = preload("res://Assets/TemporaryAssets/Folder Friends icOnS/Sprites/Files/Files1_5.png")
@onready var button:Button = $file_button
@onready var application_text_ = $file_button/Label

# Called when the node enters the scene tree for the first time.
func _ready():
	if file_type == 0:
		button.icon = text_icon
	else:
		button.icon = image_icon
	application_text_.text = application_text
