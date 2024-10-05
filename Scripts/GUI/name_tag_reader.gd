extends Area3D
var showing:bool = false
var item_reader
var name_text
func _ready():
	name_text = get_parent().name_text
	if name_text == "":
		monitoring = false
		monitorable = false
	else:
		item_reader = Gui.get_item_reader()
		EventBus.connect("object_looked_at",display_text)
		EventBus.connect("no_object_found",hide_text)

func display_text(node):
	if node == self:
		item_reader.display_item(name_text)
		showing = true
	else:
		if showing:
			item_reader.hide_item()
			showing = false
	

func hide_text(node):
	if node == self:
		showing = false
		item_reader.hide_item()
