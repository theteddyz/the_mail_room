extends Area3D
@onready var item_reader
@export_multiline var object_text:String
@onready var highlight_mesh:MeshInstance3D = $MeshInstance3D
var showing:bool = false
func _ready():
	item_reader = Gui.get_item_reader()
	EventBus.connect("object_looked_at",display_text)
	EventBus.connect("no_object_found",hide_text)

func display_text(node):
	if node == self:
		highlight_mesh.show()
		item_reader.display_item(object_text)
		showing = true
	else:
		if showing:
			highlight_mesh.hide()
			item_reader.hide_item()
			showing = false
	

func hide_text(node):
	if node == self:
		showing = false
		highlight_mesh.hide()
		item_reader.hide_item()
