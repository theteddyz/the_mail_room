extends Control


var icons = {}


func _ready():
	EventBus.connect("show_icon",show_icon)
	EventBus.connect("hide_icon",hide_all_icons)
	for child in get_children():
		if child is TextureRect:
			icons[child.name] = child
			child.hide()


func show_icon(object_name):
	if object_name in icons:
		icons[object_name].show()
	else:
		icons["grab"].show


func hide_icon(object_name):
	if object_name in icons:
		icons[object_name].hide()


func hide_all_icons():
	for icon in icons.values():
		icon.hide()
