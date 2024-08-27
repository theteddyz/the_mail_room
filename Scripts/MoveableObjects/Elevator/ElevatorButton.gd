extends Interactable
@export var target_scene_path := ""
@export var floor_num:int
var text_displayer
func _ready():
	EventBus.connect("object_looked_at",on_seen)
	EventBus.connect("no_object_found",on_unseen)
	text_displayer = Gui.get_address_displayer()
func interact():
	print("GOING TO NEW SCENE ",target_scene_path)
	EventBus.emitCustomSignal("moved_to_floor", [target_scene_path,floor_num])



func on_seen(node):
	if node == self:
		text_displayer.show_text()
		text_displayer.set_text(get_parent().name)

func on_unseen(node):
	if node == self:
		text_displayer.hide_text()
