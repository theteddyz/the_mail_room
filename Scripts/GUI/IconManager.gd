extends Control


var icons:Dictionary = {}
var object_held

func _ready():
	EventBus.connect("show_icon",show_icon)
	EventBus.connect("hide_icon",hide_all_icons)
	EventBus.connect("object_looked_at",show_icon)
	EventBus.connect("no_object_found",hide_all_icons)
	EventBus.connect("object_held",held_object)
	EventBus.connect("dropped_object",dropped_object)
	for child in get_children():
		if child is TextureRect:
			icons[child.name] = child
			child.hide()


func show_icon(object):
	hide_all_icons(self)
	var object_name
	if !object_held:
		if "icon_type" in object:
			object_name = object.icon_type
		elif object.name == "Handlebar":
			object_name = "Drive"
		else:
			pass
	elif object_held is Package:
		match object.name:
			"Mailcart":
				object_name = "deliverable"
			"MailboxStand":
				object_name = "deliverable"
			_:
				if "icon_type" in object:
					object_name = object.icon_type
				else:
					pass
	if object_name != null:
		if object_name in icons:
			icons[object_name].show()
		else:
			pass
			#icons["grab"].show


func hide_icon(object):
	var object_name
	if object.has_meta("icon_type"):
		object_name = object.icon_type
	elif object.name == "Handlebar":
		object_name = "Drive"
	if object_name != null:
		if object_name in icons:
			icons[object_name].hide()


func hide_all_icons(_object):
	for icon in icons.values():
		icon.hide()


func held_object(_var1,var2):
	object_held = var2

func dropped_object(_var1,_var2):
	hide_all_icons(_var1)
	object_held = null
