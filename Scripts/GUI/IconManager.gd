extends Control

var icons: Dictionary = {}
var object_held

# Mapping from enum integer values to icon names
const ICON_TYPE_NAMES = {
	0: "grab",
	1: "light",
	2: "package",
	3:"deliverable",
	4:"key",
	5:"tape"
}

func _ready():
	EventBus.connect("show_icon", show_icon)
	EventBus.connect("hide_icon", hide_all_icons)
	EventBus.connect("object_looked_at", show_icon)
	EventBus.connect("no_object_found", hide_all_icons)
	EventBus.connect("object_held", held_object)
	EventBus.connect("dropped_object", dropped_object)

	for child in get_children():
		if child is TextureRect:
			icons[child.name] = child
			child.hide()

func show_icon(object):
	hide_all_icons(object)

	var object_name = null

	if GrabbingManager.current_grabbed_object == object:
		object_name = "grabClosed"
	else:
		# If there was anything scary and horrific about our game, it is this here code. Truly eldritch. Truly frightening.
		if not object_held:
			if "icon_type" in object:
				var type_id = object.icon_type
				if type_id in ICON_TYPE_NAMES:
					object_name = ICON_TYPE_NAMES[type_id]
				else:
					object_name = "grab"
				if object is Package:
					object.show_label(object.package_partial_address)
			elif object.name == "Handlebar":
				object_name = "Drive"
		elif object_held is Package and object is not Package:
			match object.name:
				"Basket", "MailboxStand":
					object_name = "deliverable"
				_:
					object_name = "grab"

	if object_name != null and object_name in icons:
		icons[object_name].show()

func hide_icon(object):
	var object_name = null
	if object.has_meta("icon_type"):
		var type_id = object.icon_type
		if type_id in ICON_TYPE_NAMES:
			object_name = ICON_TYPE_NAMES[type_id]
	elif object.name == "Handlebar":
		object_name = "Drive"

	if object_name != null and object_name in icons:
		icons[object_name].hide()

func hide_all_icons(_object):
	if _object is RigidBody3D and _object.has_method("hide_label"):
		_object.hide_label()

	if not object_held:
		for icon in icons.values():
			icon.hide()
	else:
		for icon in icons.values():
			if icon.name != "grabClosed":
				icon.hide()

func held_object(_var1, var2):
	object_held = var2

func dropped_object(_var1, _var2):
	hide_all_icons(_var1)
	object_held = null
