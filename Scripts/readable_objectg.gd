extends Interactable

@onready var item_reader
@export var image_path:Texture2D 
@export var object_text:String

var startPosition = Vector3.ZERO

func _ready():
	startPosition = position
	item_reader = Gui.get_item_reader()



func interact():
	item_reader.display_item(object_text,image_path)
