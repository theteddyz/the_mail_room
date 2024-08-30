extends Area3D

@onready var item_reader
@export_multiline var object_text:String
@onready var highlight_mesh:MeshInstance3D = $MeshInstance3D
var package_material:MeshInstance3D
var shader_material
func _ready():
	package_material = get_child(0)
	item_reader = Gui.get_item_reader()
	EventBus.connect("object_looked_at",display_text)
	EventBus.connect("no_object_found",hide_text)

func display_text(node):
	if node == self:
		highlight_mesh.show()
		item_reader.display_item(object_text)

func hide_text(node):
	if node == self:
		highlight_mesh.hide()
		item_reader.hide_item()
